//
//  API.swift
//  Movies
//
//  Created by Balázs Kilvády on 04/12/21.
//

import Foundation
import Combine
import class UIKit.UIImage

private let _kTokenKey = "01c2282c845056a58215f4bd57f65352"
private let _kBaseUrl = URL(string: "https://api.themoviedb.org/3/")!

enum API {
    static let _decoder = _createDecoder()

    static func nowPlaying(page: Int) -> AnyPublisher<DS.NowPlaying, HTTPError> {
        let url = Self._createURL("movie/now_playing", ["language": "en-US", "page": String(page)])
        return _fetch(url)
    }

    static func configuration() -> AnyPublisher<DS.Configuration, HTTPError> {
        let url = Self._createURL("configuration")
        return _fetch(url)
    }

    static func downloadImage(url: URL?) -> AnyPublisher<UIImage?, HTTPError> {
        guard let url = url else {
            return Just(UIImage?(nil))
                .mapError { _ in HTTPError.invalidResponse }
                .eraseToAnyPublisher()
        }
        return URLSession.shared.dataTaskPublisher(for: url)
            .map { UIImage(data: $0.data) }
            .mapError { _ in HTTPError.invalidResponse }
            .eraseToAnyPublisher()
    }
}

private extension API {
    static func _fetch<D: Decodable>(_ urlRequest: URLRequest) -> AnyPublisher<D, HTTPError> {
        DLog("url: ", urlRequest.url?.absoluteString ?? "nil")

        return URLSession.shared.dataTaskPublisher(for: urlRequest)
            .tryMap { output in
                guard let response = output.response as? HTTPURLResponse else { fatalError() }
                guard response.statusCode == 200 else {
                    throw HTTPError.status(code: response.statusCode)
                }
                return output.data
            }
            .decode(type: D.self, decoder: _decoder)
            .mapError { error -> HTTPError in
                DLog("fetch error: ", error)
                if let httpError = error as? HTTPError {
                    return httpError
                }
                return HTTPError.invalidResponse
            }
            .eraseToAnyPublisher()
    }

    static func _createURL(_ function: String, _ parameters: [String: String] = [:]) -> URLRequest {
        // Assembling the url.
        guard let url = URL(string: function, relativeTo: _kBaseUrl) else { fatalError() }
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        components.queryItems = [URLQueryItem(name: "api_key", value: _kTokenKey)]
            + parameters.map { URLQueryItem(name: $0, value: $1) }

        // Set up the reqest.
        var request = URLRequest(url: components.url!, timeoutInterval: 30)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        return request
    }

    static func _createDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}
