//
//  MovieCollectionViewCell.swift
//  Movies
//
//  Created by Balázs Kilvády on 04/14/21.
//

import UIKit

class MovieCollectionViewCell: UICollectionViewCell {
    private let _label = UILabel()
    var label: UILabel {
        get { _label }
        set { fatalError() }
    }

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
    }
}

private extension MovieCollectionViewCell {
    func _setupViews() {
        _label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(_label)
    }

    func _setupConstraints() {
        NSLayoutConstraint.activate([
            _label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            _label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }
}
