//
//  MenuTableViewController.swift
//  NewOrderOoO
//

import UIKit
import FirebaseFirestore

class MenuTableViewCell: UITableViewCell {
    @IBOutlet weak var pdImgView: UIImageView!
    @IBOutlet weak var pdNameLabel: UILabel!
    @IBOutlet weak var pdPriceLabel: UILabel!
    @IBOutlet weak var pdContentLabel: UILabel!
    @IBOutlet weak var pdDescriptionLabel: UILabel!

    private let card = UIView()
    private let thumb = UIImageView()
    private let nameLabel = UILabel()
    private let priceLabel = PaddedLabel()
    private let contentLabel = UILabel()
    private let descriptionLabel = UILabel()

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.subviews.forEach { $0.removeFromSuperview() }
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.clipsToBounds = false
        clipsToBounds = false

        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = AppTheme.cardBackground
        card.layer.cornerRadius = AppTheme.Radius.card
        card.layer.cornerCurve = .continuous
        AppTheme.Shadow.card(on: card.layer)
        contentView.addSubview(card)

        thumb.translatesAutoresizingMaskIntoConstraints = false
        thumb.contentMode = .scaleAspectFill
        thumb.layer.cornerRadius = AppTheme.Radius.thumb
        thumb.layer.cornerCurve = .continuous
        thumb.layer.masksToBounds = true
        thumb.backgroundColor = AppTheme.imagePlaceholder
        card.addSubview(thumb)

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = AppTheme.Font.cardTitle
        nameLabel.textColor = AppTheme.primaryText
        nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        card.addSubview(nameLabel)

        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        priceLabel.font = AppTheme.Font.priceMedium
        priceLabel.textColor = AppTheme.accent
        priceLabel.textAlignment = .center
        priceLabel.backgroundColor = AppTheme.accent.withAlphaComponent(0.15)
        priceLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        priceLabel.setContentHuggingPriority(.required, for: .horizontal)
        card.addSubview(priceLabel)

        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        contentLabel.font = AppTheme.Font.secondary
        contentLabel.textColor = AppTheme.secondaryText
        card.addSubview(contentLabel)

        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.font = AppTheme.Font.caption
        descriptionLabel.textColor = AppTheme.tertiaryText
        descriptionLabel.numberOfLines = 2
        card.addSubview(descriptionLabel)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            thumb.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 10),
            thumb.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
            thumb.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -10),
            thumb.widthAnchor.constraint(equalTo: thumb.heightAnchor),

            nameLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            nameLabel.leadingAnchor.constraint(equalTo: thumb.trailingAnchor, constant: 14),

            priceLabel.firstBaselineAnchor.constraint(equalTo: nameLabel.firstBaselineAnchor),
            priceLabel.leadingAnchor.constraint(greaterThanOrEqualTo: nameLabel.trailingAnchor, constant: 8),
            priceLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),

            contentLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            contentLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            contentLabel.trailingAnchor.constraint(lessThanOrEqualTo: card.trailingAnchor, constant: -14),

            descriptionLabel.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 6),
            descriptionLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
        ])

        let highlight = UIView()
        highlight.backgroundColor = .clear
        selectedBackgroundView = highlight
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        let scale: CGFloat = highlighted ? 0.97 : 1.0
        UIView.animate(withDuration: 0.18, delay: 0, options: [.allowUserInteraction, .curveEaseOut]) {
            self.card.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
    }

    func configure(with data: ProductData) {
        thumb.image = UIImage(named: data.imgName)
        nameLabel.text = data.name
        priceLabel.text = data.price
        contentLabel.text = data.content
        descriptionLabel.text = data.description
    }
}

class MenuTableViewController: UITableViewController {
    private let viewModel = MenuListViewModel()

    struct cellKey {
        static let MenuTableViewCell = "MenuTableViewCell"
    }

//    var bd: Firestore!

    override func viewDidLoad() {
        super.viewDidLoad()
//        bd = Firestore.firestore()

        tableView.separatorStyle = .none
        tableView.backgroundColor = AppTheme.pageBackground
        tableView.rowHeight = 116
        tableView.contentInset = UIEdgeInsets(top: 4, left: 0, bottom: 16, right: 0)

        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always

        let refresh = UIRefreshControl()
        refresh.tintColor = AppTheme.accent
        refresh.addTarget(self, action: #selector(refreshPulled), for: .valueChanged)
        tableView.refreshControl = refresh
    }

    @objc private func refreshPulled() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.tableView.refreshControl?.endRefreshing()
        }
    }

    @IBSegueAction func dataPassed(_ coder: NSCoder) -> MenuDetailTableViewController? {
        guard let row = tableView.indexPathForSelectedRow?.row else { return nil }
        let controller = MenuDetailTableViewController(coder: coder)
        controller?.viewModel = MenuDetailViewModel(product: viewModel.product(at: row))
        return controller
    }

    //以下設定tableviewcell
    override func numberOfSections(in tableView: UITableView) -> Int { 1 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { viewModel.numberOfProducts }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellKey.MenuTableViewCell, for: indexPath) as? MenuTableViewCell else { return UITableViewCell() }
        cell.configure(with: viewModel.product(at: indexPath.row))
        return cell
    }
}
