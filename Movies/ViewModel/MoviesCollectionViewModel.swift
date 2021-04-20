//
//  MoviesCollectionViewModel.swift
//  Movies
//
//  Created by Balázs Kilvády on 04/12/21.
//

import Foundation
import Combine
import class UIKit.UIImage

final class MoviesCollectionViewModel: ViewModelType {
    struct Input {
        let page: AnyPublisher<Int, Never>
        let width: Int
    }

    typealias Output = AnyPublisher<NowPlaying, Never>

    private typealias _IndexedImage = (index: Int, image: UIImage?)
    private typealias _ConfigTuple = (page: Int, width: Float, config: Configuration)

    private enum _Event {
        case start(nowPlaying: NowPlaying)
        case fetched(tuple: _IndexedImage)
    }

    private let _configuration = PassthroughSubject<Configuration, Never>()
    private let queue = DispatchQueue(label: "fetch", qos: .background, target: DispatchQueue.global(qos: .background))
    private let _item = PassthroughSubject<MovieItem, Never>()
    private var _bag = Set<AnyCancellable>()

    init() {
        _getConfiguration()
    }

    func transform(_ input: Input) -> Output {
        let data = PassthroughSubject<NowPlaying, Never>()
        let event = PassthroughSubject<_Event, Never>()

        input.page
            .combineLatest(_configuration) { (page: $0, width: input.width, config: $1) }
            .subscribe(on: queue)
            .debug()
            .flatMap {
                Self._fetchPlayingPosters($0.page, $0.width, $0.config)
                    .map { _Event.start(nowPlaying: $0) }
                    .catch { _ in Empty<_Event, Never>() }
                    .debug()
            }
            .debug()
            .subscribe(event)
            // .sink { event.send($0) }
            .store(in: &_bag)

        _item
            .subscribe(on: queue)
            .flatMap { item in
                API.downloadImage(url: item.url)
                    .map { _Event.fetched(tuple: _IndexedImage(item.index, $0)) }
                    .catch { _ in Empty<_Event, Never>() }
                    .debug()
            }
            .debug()
            .subscribe(event)
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
    func _getConfiguration() {
        API.configuration()
            .replaceError(with: Configuration.empty)
            .subscribe(_configuration)
            .store(in: &_bag)
    }

    static func _fetchPlayingPosters(_ page: Int, _ width: Int, _ config: Configuration) -> AnyPublisher<NowPlaying, HTTPError> {
        API.nowPlaying(page: page)
            .filter { !$0.results.isEmpty }
            .debug()
            .map {
                let urls = Self._convertToURLs(config, width, $0)
                return NowPlaying(page: $0.page,
                                  results: urls.enumerated().map { MovieItem(index: $0.offset, url: $0.element, image: nil) })
            }
            .debug()
            .eraseToAnyPublisher()
    }

    static func _convertToURLs(_ config: Configuration, _ width: Int, _ nowPlaying: DS.NowPlaying) -> [URL?] {
        guard !config.baseUrl.isEmpty else {
            return [URL?].init(repeating: nil, count: 1)
        }
        let baseUrl = config.baseUrl
        let index = _indef(of: width, in: config)
        let size = config.posterSizes[index]
        let urls = nowPlaying.results.map { np -> URL? in
            guard let path = np.posterPath else { return nil }
            let url = URL(string: baseUrl + size + path)
            // DLog(url?.absoluteString ?? "nil")
            return url
        }
        return urls
    }

    static func _indef(of width: Int, in cofig: Configuration) -> Int {
        let widhts = cofig.posterSizes.compactMap {
            Int($0.dropFirst())
        }
        return widhts.firstIndex { $0 >= width } ?? cofig.posterSizes.count - 2
    }
}
