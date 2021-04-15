//
//  MovieItem.swift
//  Movies
//
//  Created by Balázs Kilvády on 04/14/21.
//

import Foundation
import class UIKit.UIImage

struct MovieItem: Hashable {
    let index: Int
    let url: URL?
    let image: UIImage?
}
