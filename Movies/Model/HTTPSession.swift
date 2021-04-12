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
        let posterPath: String
    }
}

typealias DS = DataSource
