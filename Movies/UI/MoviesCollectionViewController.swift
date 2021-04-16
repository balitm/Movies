//
//  MoviesCollectionViewController.swift
//  Movies
//
//  Created by Balázs Kilvády on 04/12/21.
//

import UIKit
import Combine

private let _reuseId = "Cell"

enum Section {
    case main
}

private var _movieList = [MovieItem]()

final class MoviesCollectionViewController: UICollectionViewController {
    private typealias _DataSource = UICollectionViewDiffableDataSource<Section, MovieItem>
    private typealias _Snapshot = NSDiffableDataSourceSnapshot<Section, MovieItem>

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
        _setupLayout(collectionViewLayout as! UICollectionViewFlowLayout)

        // Register cell classes.
        collectionView.register(MovieCollectionViewCell.self, forCellWithReuseIdentifier: _reuseId)

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
        _viewModel.dataSource()
            .map(\.results)
            .assign(to: \._dataSourceProperty, on: self)
            .store(in: &_bag)
    }

    // MARK: UICollectionViewDiffableDataSource

    private func _makeDataSource() -> _DataSource {
        let dataSource = _DataSource(
            collectionView: collectionView,
            cellProvider: { [weak self] collectionView, indexPath, item in
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: _reuseId,
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
}

private func _setupLayout(_ layout: UICollectionViewFlowLayout) {
    layout.itemSize = CGSize(width: 171, height: 256)
    layout.minimumInteritemSpacing = 0
    layout.minimumLineSpacing = 0
    layout.scrollDirection = .vertical
}
