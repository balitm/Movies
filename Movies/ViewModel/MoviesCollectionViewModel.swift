//
//  MoviesCollectionViewModel.swift
//  Movies
//
//  Created by Balázs Kilvády on 04/12/21.
//

import Foundation
import Combine
import class UIKit.UIImage

final class MoviesCollectionViewModel {
    // @Published private var _nowPlaying = DS.NowPlaying(page: 0, results: [])
    @Published private var _configuration = DS.Configuration.empty
    private var _bag = Set<AnyCancellable>()

    init() {
        _getConfiguration()
    }

    func fetchPlayingPosters() -> AnyPublisher<NowPlaying, HTTPError> {
        let nowPlaying = PassthroughSubject<DS.NowPlaying, HTTPError>()
        let result = PassthroughSubject<NowPlaying, HTTPError>()

        let confWithError = $_configuration
            .catch { _ in Empty<Configuration, HTTPError>() }
            .debug()

        API.nowPlaying()
            .subscribe(nowPlaying)
            .store(in: &_bag)

        nowPlaying
            .debug()
            .prefix(1)
            .map {
                NowPlaying(page: $0.page, results: $0.results.map { _ in MovieListResult(poster: nil) })
            }
            .subscribe(result)
            .store(in: &_bag)

        nowPlaying
            .debug()
            .filter { !$0.results.isEmpty }
            .flatMap { nowPlaying in
                confWithError
                    .debug()
                    .map { _ConfPlaying(config: $0, nowPlaying: nowPlaying) }
            }
            .flatMap {
                self._convertToURLs($0)
                    .catch { _ in Empty<_IndexedURL, HTTPError>() }
            }
            .flatMap { indexedURL in
                API.downloadImage(url: indexedURL.url)
                    .map { (image: $0, index: indexedURL.index) }
            }
            .zip(result) { (nowPlaying: $1, image: $0.image, index: $0.index) }
            .map { tuple -> NowPlaying in
                var results = tuple.nowPlaying.results
                results[tuple.index] = MovieListResult(poster: tuple.image)
                let new = NowPlaying(page: tuple.nowPlaying.page, results: results)
                return new
            }
            .subscribe(result)
            .store(in: &_bag)

        return result.eraseToAnyPublisher()
    }

    private func _getConfiguration() {
        API.configuration()
            .catch { _ in
                Empty<Configuration, Never>()
            }
            .debug()
            .assign(to: \._configuration, on: self)
            .store(in: &_bag)
    }
    
    // func _fetchPlayingPosters() {
    //     API.nowPlaying()
    //         .catch { _ in
    //             Empty<DS.NowPlaying, Never>()
    //         }
    //         .assign(to: \._nowPlaying, on: self)
    //         .store(in: &_bag)
    // }
}

private extension MoviesCollectionViewModel {
    typealias _ConfPlaying = (config: DS.Configuration, nowPlaying: DS.NowPlaying)
    typealias _IndexedURL = (url: URL, index: Int)

    // func _convertToURLs(_ confPlaying: _ConfPlaying) -> [URL] {
    func _convertToURLs(_ confPlaying: _ConfPlaying) -> Publishers.Sequence<[_IndexedURL], Never> {
        let baseUrl = confPlaying.config.baseUrl
        let index = min(2, confPlaying.config.posterSizes.count - 1)
        let size = confPlaying.config.posterSizes[index]
        let urls = confPlaying.nowPlaying.results.enumerated().compactMap { np -> _IndexedURL? in
            guard let path = np.element.posterPath else { return nil }
            guard let url = URL(string: baseUrl + size + "/" + path) else { return nil }
            return (url: url, index: np.offset)
        }
        return urls.publisher
    }
}
