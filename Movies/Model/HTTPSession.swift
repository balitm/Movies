//
//  HTTPSession.swift
//  Movies
//
//  Created by Balázs Kilvády on 04/12/21.
//

import Foundation
import class UIKit.UIImage

enum HTTPError: Error {
    case status(code: Int)
    case invalidResponse
}

struct NowPlaying {
    let results: [MovieListResult]
}

struct MovieListResult {
    let poster: UIImage
}

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

        let baseUrl: String
        let posterSizes: [String]

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: Self.CodingKeys)
            let images = try container.decode(Images.self, forKey: .images)
            baseUrl = images.baseUrl
            posterSizes = images.posterSizes
        }
    }
}

typealias DS = DataSource
