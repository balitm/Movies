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
    @Published var page = 1
    override func setUpWithError() throws {}

    func testViewModel() {
        let vm = MoviesCollectionViewModel()
        var bag = Set<AnyCancellable>()
        var movieItem: MovieItem?
        let input = MoviesCollectionViewModel.Input(page: $page.eraseToAnyPublisher(), width: 375)
        let source = vm.transform(input).share()
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
                .catch { _ in Empty<NowPlaying, Error>() }
                .tryMap { np -> UIImage in
                    guard let image = np.results.first?.image else {
                        throw HTTPError.invalidResponse
                    }
                    return image
                }
                .sink {
                    switch $0 {
                    case .finished:
                        break
                    case let .failure(error):
                        XCTAssert(false, "No first image \(error).")
                    }
                } receiveValue: {
                    XCTAssertLessThanOrEqual(375, $0.size.width)
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
