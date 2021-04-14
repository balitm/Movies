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
    @Published private var _configuration = DS.Configuration.empty
    private var _bag = Set<AnyCancellable>()

    init() {
        _getConfiguration()
    }

    func fetchPlayingPosters() -> AnyPublisher<NowPlaying, HTTPError> {
        let queue = DispatchQueue(label: "fetch", qos: .background, target: DispatchQueue.global(qos: .background))

        let confWithError = $_configuration
            .catch { _ in Empty<Configuration, HTTPError>() }

        return API.nowPlaying()
            .receive(on: queue)
            .filter { !$0.results.isEmpty }
            .flatMap { nowPlaying in
                confWithError
                    .prefix(1)
                    .map { _ConfPlaying(config: $0, nowPlaying: nowPlaying) }
            }
            .map { [unowned self] cp -> NowPlaying in
                let urls = self._convertToURLs(cp)
                return NowPlaying(page: cp.nowPlaying.page, results: urls.map { MovieListResult(posterURL: $0) })
            }
            .eraseToAnyPublisher()
    }

    func downloadImage(from url: URL) -> AnyPublisher<UIImage?, HTTPError> {
        API.downloadImage(url: url)
    }
}

private extension MoviesCollectionViewModel {
    typealias _ConfPlaying = (config: DS.Configuration, nowPlaying: DS.NowPlaying)

    func _getConfiguration() {
        API.configuration()
            .catch { _ in
                Empty<Configuration, Never>()
            }
            .assign(to: \._configuration, on: self)
            .store(in: &_bag)
    }

    func _convertToURLs(_ confPlaying: _ConfPlaying) -> [URL?] {
        let baseUrl = confPlaying.config.baseUrl
        let index = min(3, confPlaying.config.posterSizes.count - 1)
        let size = confPlaying.config.posterSizes[index]
        let urls = confPlaying.nowPlaying.results.map { np -> URL? in
            guard let path = np.posterPath else { return nil }
            let url = URL(string: baseUrl + size + path)
            // DLog(url?.absoluteString ?? "nil")
            return url
        }
        return urls
    }
}
