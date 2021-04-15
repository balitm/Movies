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
            vm._fetchPlayingPosters()
                .sink {
                    DLog("completion: ", $0)
                    expectation.fulfill()
                } receiveValue: {
                    DLog("recved: ", $0.results.compactMap { $0.posterURL }.count)
                }
                .store(in: &bag)
        }

        expectation { expectation in
            vm._fetchPlayingPosters()
                .flatMap {
                    vm.downloadImage(from: $0.results[0].posterURL!)
                }
                .sink {
                    DLog("completion: ", $0)
                    expectation.fulfill()
                } receiveValue: {
                    DLog("recved: ", $0?.description ?? "nil")
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
