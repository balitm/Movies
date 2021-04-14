//
//  MoviesCollectionViewController.swift
//  Movies
//
//  Created by Balázs Kilvády on 04/12/21.
//

import UIKit

private let _reuseId = "Cell"

final class MoviesCollectionViewController: UICollectionViewController {
    private var _viewModel: MoviesCollectionViewModel!

    class func create(with viewModel: MoviesCollectionViewModel) -> MoviesCollectionViewController {
        let layout = UICollectionViewFlowLayout()
        let vc = Self(collectionViewLayout: layout)
        return vc
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.backgroundColor = .yellow
        title = "The Movies"
        _setupLayout(collectionViewLayout as! UICollectionViewFlowLayout)

        // Register cell classes
        collectionView.register(MovieCollectionViewCell.self, forCellWithReuseIdentifier: _reuseId)

        // Do any additional setup after loading the view.
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        1
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: _reuseId, for: indexPath) as? MovieCollectionViewCell else {
            return UICollectionViewCell()
        }

        // Configure the cell

        return cell
    }
}

private func _setupLayout(_ layout: UICollectionViewFlowLayout) {
    layout.itemSize = CGSize(width: 171, height: 256)
    layout.minimumInteritemSpacing = 0
    layout.minimumLineSpacing = 0
    layout.scrollDirection = .vertical
}
