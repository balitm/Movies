//
//  MovieCollectionViewCell.swift
//  Movies
//
//  Created by Balázs Kilvády on 04/14/21.
//

import UIKit

class MovieCollectionViewCell: UICollectionViewCell {
    private let _label = UILabel()
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
        _label.text = String(movieItem.index)
        _imageView.image = movieItem.image
    }
}

private extension MovieCollectionViewCell {
    func _setupViews() {
        _imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(_imageView)

        _label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(_label)
    }

    func _setupConstraints() {
        NSLayoutConstraint.activate([
            _label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            _label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            _imageView.widthAnchor.constraint(equalTo: contentView.widthAnchor),
            _imageView.heightAnchor.constraint(equalTo: contentView.heightAnchor),
            _imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            _imageView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
        ])
    }
}
