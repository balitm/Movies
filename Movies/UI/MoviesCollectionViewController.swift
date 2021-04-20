//
//  MoviesCollectionViewController.swift
//  Movies
//
//  Created by Balázs Kilvády on 04/12/21.
//

import UIKit
import Combine

private let _kReuseId = "Cell"
private let _kRatio: CGFloat = 1.5

enum Section {
    case main
}

final class MoviesCollectionViewController: UICollectionViewController {
    private typealias _DataSource = UICollectionViewDiffableDataSource<Section, MovieItem>
    private typealias _Snapshot = NSDiffableDataSourceSnapshot<Section, MovieItem>
    private typealias _ViewModel = MoviesCollectionViewModel

    private var _width: CGFloat!
    @Published private var _page = 1
    private var _viewModel: MoviesCollectionViewModel!
    private lazy var _dataSource = _makeDataSource()
    private var _bag = Set<AnyCancellable>()

    class func create(with viewModel: MoviesCollectionViewModel) -> MoviesCollectionViewController {
        let layout = UICollectionViewFlowLayout()
        let vc = Self(collectionViewLayout: layout)
        vc._viewModel = viewModel
        return vc
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.backgroundColor = .systemBackground
        title = "The Movies"

        // Register cell classes.
        collectionView.register(MovieCollectionViewCell.self, forCellWithReuseIdentifier: _kReuseId)

        // Compute width.
        let bounds = UIScreen.main.bounds
        _width = min(bounds.width, bounds.height) / 2

        _setupLayout(collectionViewLayout as! UICollectionViewFlowLayout)

        // Bind the data source.
        _bind()
    }
}

private extension MoviesCollectionViewController {
    var _dataSourceProperty: [MovieItem] {
        get { [] }
        set {
            _applySnapshot(items: newValue)
        }
    }

    func _bind() {
        let scale = UIScreen.main.scale
        let width = Int(_width * scale)
        let input = _ViewModel.Input(page: $_page.eraseToAnyPublisher(),
                                     width: width)
        _viewModel.transform(input)
            .map(\.results)
            .assign(to: \._dataSourceProperty, on: self)
            .store(in: &_bag)
    }

    // MARK: UICollectionViewDiffableDataSource

    private func _makeDataSource() -> _DataSource {
        let dataSource = _DataSource(
            collectionView: collectionView,
            cellProvider: { [weak self] collectionView, indexPath, item in
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: _kReuseId,
                                                              for: indexPath) as! MovieCollectionViewCell
                cell.config(with: item)
                if item.canFetchImage {
                    self?._viewModel.downloadImage(for: item)
                }
                return cell
            })
        return dataSource
    }

    func _applySnapshot(items: [MovieItem], animatingDifferences: Bool = true) {
        var snapshot = _Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(items)
        _dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }

    func _setupLayout(_ layout: UICollectionViewFlowLayout) {
        layout.itemSize = CGSize(width: _width, height: _width * _kRatio)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .vertical
    }
}
