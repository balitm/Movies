//
//  MoviesCollectionViewModel.swift
//  Movies
//
//  Created by Balázs Kilvády on 04/12/21.
//

import Foundation
import Combine

private let _kTokenKey = "01c2282c845056a58215f4bd57f65352"
private let _kBaseUrl = "https://api.themoviedb.org/3/movie/"

struct MoviesCollectionViewModel {
    func nowPlaying() -> AnyPublisher<DS.NowPlaying, HTTPError> {
        let url = Self._createURL("now_playing", ["language": "en-US"])
        let decoder = Self._createDecoder()

        return URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { output in
                guard let response = output.response as? HTTPURLResponse else { fatalError() }
                guard response.statusCode == 200 else {
                    throw HTTPError.status(code: response.statusCode)
                }
                return output.data
            }
            .decode(type: DS.NowPlaying.self, decoder: decoder)
            .mapError { error -> HTTPError in
                print("nowPlaying error:", error)
                return HTTPError.invalidResponse
            }
            .eraseToAnyPublisher()
    }
}

private extension MoviesCollectionViewModel {
    static func _createURL(_ function: String, _ parameters: [String: String] = [:]) -> URL {
        let base = _kBaseUrl +
        function + "?" + "api_key=" + _kTokenKey
        var str = parameters.reduce(base) {
            $0 + $1.key + "=" + $1.value + "&"
        }
        if parameters.count > 0 {
            assert(str.last == "&")
            str.removeLast()
        }
        guard let url = URL(string: str) else { fatalError() }
        return url
    }

    static func _createDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}
