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
        var movieItem: MovieItem?
        let source = vm.dataSource().share()
        var first: AnyCancellable?

        expectation { expectation in
            first = source
                .sink {
                    XCTAssertEqual($0.page, 1)
                    XCTAssertEqual($0.results.compactMap { $0.url }.count, 20)
                    XCTAssertEqual($0.results.compactMap { $0.image }.count, 0)
                    movieItem = $0.results.first
                    expectation.fulfill()
                }
        }
        first?.cancel()
        first = nil

        expectation { expectation in
            guard let movieItem = movieItem else {
                XCTAssert(false)
                return
            }

            vm.downloadImage(for: movieItem)

            source
                .filter { $0.results.first?.image != nil }
                .sink { _ in
                    expectation.fulfill()
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
