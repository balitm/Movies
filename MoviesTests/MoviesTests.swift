//
//  MoviesTests.swift
//  MoviesTests
//
//  Created by Balázs Kilvády on 04/12/21.
//

import XCTest
import Combine
import class UIKit.UIImage
@testable import Movies

class MoviesTests: XCTestCase {
    override func setUpWithError() throws {}

    func testViewModel() {
        let vm = MoviesCollectionViewModel()
        var bag = Set<AnyCancellable>()

        expectation { expectation in
            vm.fetchPlayingPosters()
                .sink {
                    DLog("completion: ", $0)
                    expectation.fulfill()
                } receiveValue: {
                    // let size = $0.size
                    DLog("recved: ", $0.results.compactMap { $0.poster }.count)
                }
                .store(in: &bag)
        }
        DLog("cancellables: ", bag.count)
    }
}

extension MoviesTests {
    func expectation(timeout: Double = 30.0, test: (XCTestExpectation) -> Void) {
        let expectation = XCTestExpectation(description: "combine")
        test(expectation)
        wait(for: [expectation], timeout: timeout)
    }
}
