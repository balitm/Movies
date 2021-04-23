//
//  MovieCollectionViewCell.swift
//  Movies
//
//  Created by Balázs Kilvády on 04/14/21.
//

import UIKit

class MovieCollectionViewCell: UICollectionViewCell {
    private let _imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        _setupViews()
        _setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func config(with movieItem: MovieItem) {
        _imageView.image = movieItem.image
    }
}

private extension MovieCollectionViewCell {
    func _setupViews() {
        _imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(_imageView)
    }

    func _setupConstraints() {
        NSLayoutConstraint.activate([
            _imageView.widthAnchor.constraint(equalTo: contentView.widthAnchor),
            _imageView.heightAnchor.constraint(equalTo: contentView.heightAnchor),
            _imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            _imageView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
        ])
    }
}
