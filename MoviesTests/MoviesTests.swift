//
//  MoviesTests.swift
//  MoviesTests
//
//  Created by Balázs Kilvády on 04/12/21.
//

import XCTest
import Combine
@testable import Movies

class MoviesTests: XCTestCase {
    override func setUpWithError() throws {
    }

    func testViewModel() {
        let vm = MoviesCollectionViewModel()

        expectation { expectation in
            _ = vm.nowPlaying()
                .sink {
                    print("completion:", $0)
                    expectation.fulfill()
                } receiveValue: {
                    print("recved #", $0.page, "results:", $0.results.count)
                }
        }
    }
}

extension MoviesTests {
    func expectation(timeout: Double = 30.0, test: (XCTestExpectation) -> Void) {
        let expectation = XCTestExpectation(description: "combine")
        test(expectation)
        wait(for: [expectation], timeout: timeout)
    }
}
