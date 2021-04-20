//
//  ViewModelType.swift
//  Movies
//
//  Created by Balázs Kilvády on 04/19/21.
//

import Foundation

protocol ViewModelType {
    associatedtype Input
    associatedtype Output

    func transform(_ input: Input) -> Output
}
