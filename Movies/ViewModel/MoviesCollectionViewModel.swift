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
    @Published private var _nowPlaying = DS.NowPlaying(page: 0, results: [])

    func fetchPlayingPosters() -> AnyPublisher<UIImage, HTTPError> {
        API.configuration()
            .flatMap { config in
                API.nowPlaying()
                    .map { _ConfPlaying(config: config, nowPlaying: $0) }
            }
            .flatMap { [unowned self] in
                self._convertToURLs($0)
                    .catch { _ in Empty<URL, HTTPError>() }
            }
            .flatMap {
                API.downloadImage(url: $0)
            }
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
}

private extension MoviesCollectionViewModel {
    typealias _ConfPlaying = (config: DS.Configuration, nowPlaying: DS.NowPlaying)

    // func _convertToURLs(_ confPlaying: _ConfPlaying) -> [URL] {
    func _convertToURLs(_ confPlaying: _ConfPlaying) -> Publishers.Sequence<[URL], Never> {
        let baseUrl = confPlaying.config.baseUrl
        let index = min(2, confPlaying.config.posterSizes.count - 1)
        let size = confPlaying.config.posterSizes[index]
        let urls = confPlaying.nowPlaying.results.compactMap { np -> URL? in
            guard let path = np.posterPath else { return nil }
            return URL(string: baseUrl + size + "/" + path)
        }
    return urls.publisher
    }
}
