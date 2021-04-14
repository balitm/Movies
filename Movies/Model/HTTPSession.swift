//
//  HTTPSession.swift
//  Movies
//
//  Created by Balázs Kilvády on 04/12/21.
//

import Foundation

enum HTTPError: Error {
    case status(code: Int)
    case invalidResponse
}

struct NowPlaying {
    let page: Int
    let results: [MovieListResult]
}

struct MovieListResult {
    let posterURL: URL?
}

typealias Configuration = DS.Configuration

enum DataSource {
    struct NowPlaying: Decodable {
        let page: Int
        let results: [MovieListResult]
    }

    struct MovieListResult: Decodable {
        let posterPath: String?
    }

    struct Configuration: Decodable {
        struct Images: Decodable {
            private enum CodingKeys: String, CodingKey {
                case baseUrl
                case posterSizes
            }

            let baseUrl: String
            let posterSizes: [String]
        }

        private enum CodingKeys: String, CodingKey {
            case images
        }

        static var empty: Configuration { Configuration() }
        let baseUrl: String
        let posterSizes: [String]

        init() {
            baseUrl = ""
            posterSizes = []
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: Self.CodingKeys)
            let images = try container.decode(Images.self, forKey: .images)
            baseUrl = images.baseUrl
            posterSizes = images.posterSizes
        }
    }
}

typealias DS = DataSource
