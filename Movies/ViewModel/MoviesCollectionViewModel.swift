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
    private typealias _IndexedImage = (index: Int, image: UIImage?)

    private enum _Event {
        case start(nowPlaying: NowPlaying)
        case fetched(tuple: _IndexedImage)
    }

    @Published private var _configuration = DS.Configuration.empty
    private let queue = DispatchQueue(label: "fetch", qos: .background, target: DispatchQueue.global(qos: .background))
    private let _item = PassthroughSubject<MovieItem, Never>()
    private var _bag = Set<AnyCancellable>()

    init() {
        _getConfiguration()
    }

    func dataSource() -> AnyPublisher<NowPlaying, Never> {
        let data = PassthroughSubject<NowPlaying, Never>()
        let event = PassthroughSubject<_Event, Never>()

        _fetchPlayingPosters()
            .catch { _ in
                Just(NowPlaying(page: 0, results: []))
            }
            .map { _Event.start(nowPlaying: $0) }
            .sink {
                event.send($0)
            }
            .store(in: &_bag)

        _item
            .subscribe(on: queue)
            .flatMap { item in
                API.downloadImage(url: item.url)
                    .debug()
                    .map { _Event.fetched(tuple: _IndexedImage(item.index, $0)) }
                    .catch { _ in Empty<_Event, Never>() }
            }
            .sink {
                event.send($0)
            }
            .store(in: &_bag)

        event
            .subscribe(on: queue)
            .scan(NowPlaying.empty) { (np: NowPlaying, event: _Event) -> NowPlaying in
                switch event {
                case let .start(nowPlaying):
                    return nowPlaying
                case let .fetched(tuple):
                    var results = np.results
                    let oi = results[tuple.index]
                    assert(tuple.index == oi.index)
                    results[tuple.index] = MovieItem(index: oi.index, url: oi.url, image: tuple.image)
                    return NowPlaying(page: np.page, results: results)
                }
            }
            .receive(on: DispatchQueue.main)
            .subscribe(data)
            .store(in: &_bag)

        return data.eraseToAnyPublisher()
    }

    func downloadImage(for item: MovieItem) {
        _item.send(item)
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

    func _fetchPlayingPosters() -> AnyPublisher<NowPlaying, HTTPError> {
        let confWithError = $_configuration
            .catch { _ in Empty<Configuration, HTTPError>() }

        return API.nowPlaying()
            .subscribe(on: queue)
            .filter { !$0.results.isEmpty }
            .flatMap { nowPlaying in
                confWithError
                    .prefix(1)
                    .map { _ConfPlaying(config: $0, nowPlaying: nowPlaying) }
            }
            .map { [unowned self] cp -> NowPlaying in
                let urls = self._convertToURLs(cp)
                return NowPlaying(page: cp.nowPlaying.page,
                                  results: urls.enumerated().map { MovieItem(index: $0.offset, url: $0.element, image: nil) })
            }
            .eraseToAnyPublisher()
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
