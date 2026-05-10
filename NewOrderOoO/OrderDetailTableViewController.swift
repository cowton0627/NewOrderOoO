//
//  OrderDetailTableViewController.swift
//  NewOrderOoO
//
//  Created by 鄭淳澧 on 2021/8/15.
//

import UIKit

class OrderDetailTableViewCell: UITableViewCell {
    // 保留 storyboard outlet 防失連，實際 UI 由 awakeFromNib 重畫。
    @IBOutlet weak var portraitImgView: UIImageView!
    @IBOutlet weak var orderNameLabel: UILabel!
    @IBOutlet weak var drinkNameLabel: UILabel!
    @IBOutlet weak var drinkSizeLabel: UILabel!
    @IBOutlet weak var sugarLabel: UILabel!
    @IBOutlet weak var coldLabel: UILabel!
    @IBOutlet weak var addLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!

    private let card = UIView()
    private let avatar = UIImageView()
    private let nameLabel = UILabel()
    private let drinkLabel = UILabel()
    private let optionsLabel = UILabel()
    private let priceCapsule = PaddedLabel()

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

        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.contentMode = .scaleAspectFill
        avatar.clipsToBounds = true
        avatar.layer.cornerRadius = 28
        avatar.backgroundColor = AppTheme.imagePlaceholder
        card.addSubview(avatar)

        nameLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        nameLabel.textColor = AppTheme.accent
        nameLabel.numberOfLines = 1
        nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        drinkLabel.font = AppTheme.Font.cardTitle
        drinkLabel.textColor = AppTheme.primaryText
        drinkLabel.numberOfLines = 1

        optionsLabel.font = AppTheme.Font.secondary
        optionsLabel.textColor = AppTheme.secondaryText
        optionsLabel.numberOfLines = 1

        priceCapsule.font = .monospacedDigitSystemFont(ofSize: 14, weight: .bold)
        priceCapsule.textColor = AppTheme.accent
        priceCapsule.backgroundColor = AppTheme.accent.withAlphaComponent(0.15)
        priceCapsule.textAlignment = .center
        priceCapsule.contentInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
        priceCapsule.setContentCompressionResistancePriority(.required, for: .horizontal)
        priceCapsule.setContentHuggingPriority(.required, for: .horizontal)

        let topRow = UIStackView(arrangedSubviews: [nameLabel, priceCapsule])
        topRow.axis = .horizontal
        topRow.alignment = .firstBaseline
        topRow.spacing = 8

        let textStack = UIStackView(arrangedSubviews: [topRow, drinkLabel, optionsLabel])
        textStack.axis = .vertical
        textStack.alignment = .fill
        textStack.spacing = 3
        textStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(textStack)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            avatar.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            avatar.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            avatar.widthAnchor.constraint(equalToConstant: 56),
            avatar.heightAnchor.constraint(equalToConstant: 56),

            textStack.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            textStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            textStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
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

    func configure(with order: OrderData, avatarImage: UIImage?) {
        avatar.image = avatarImage
        nameLabel.text = order.orderName
        drinkLabel.text = order.drinkName
        let opts = [order.drinkSize, order.sugar, order.cold, order.add]
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
        optionsLabel.text = opts
        priceCapsule.text = order.price
    }
}


class OrderDetailTableViewController: UITableViewController {
    @IBOutlet weak var animeImgView: UIImageView!  // storyboard 仍會 instantiate 此 view,但實際 banner 用 bannerImageView 取代

    private let bannerImageView = UIImageView()

    var orderRepository: OrderRepository = FirestoreOrderRepository()

    struct cellKey {
        static let OrderDetailTableViewCell = "OrderDetailTableViewCell"
    }

    var orderDatas = [OrderData]()

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.separatorStyle = .none
        tableView.backgroundColor = AppTheme.pageBackground
        tableView.rowHeight = 96
        tableView.contentInset = UIEdgeInsets(top: 4, left: 0, bottom: 16, right: 0)

        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always

        setupBannerHeader()
        startBannerAnimation()

        fetchData()
    }

    private func setupBannerHeader() {
        // 把 storyboard 帶來的 imageView 拆掉,避免重複出現在 view hierarchy
        animeImgView?.removeFromSuperview()

        let container = UIView()
        container.backgroundColor = .clear

        bannerImageView.translatesAutoresizingMaskIntoConstraints = false
        bannerImageView.contentMode = .scaleAspectFill
        bannerImageView.clipsToBounds = true
        bannerImageView.layer.cornerRadius = AppTheme.Radius.card
        bannerImageView.layer.cornerCurve = .continuous
        bannerImageView.backgroundColor = AppTheme.imagePlaceholder
        container.addSubview(bannerImageView)

        NSLayoutConstraint.activate([
            bannerImageView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            bannerImageView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            bannerImageView.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            bannerImageView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
            bannerImageView.heightAnchor.constraint(equalToConstant: 140),
        ])

        let width = tableView.bounds.width > 0 ? tableView.bounds.width : UIScreen.main.bounds.width
        container.frame = CGRect(x: 0, y: 0, width: width, height: 156)
        tableView.tableHeaderView = container
    }

    private func startBannerAnimation() {
        guard let data = NSDataAsset(name: "anime")?.data else { return }
        let cfData = data as CFData
        CGAnimateImageDataWithBlock(cfData, nil) { [weak self] (_, cgImage, stop) in
            guard let self = self else {
                stop.pointee = true
                return
            }
            self.bannerImageView.image = UIImage(cgImage: cgImage)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let header = tableView.tableHeaderView, header.frame.width != tableView.bounds.width, tableView.bounds.width > 0 {
            header.frame.size.width = tableView.bounds.width
            tableView.tableHeaderView = header
        }
    }

    func fetchData() {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let orders = try await self.orderRepository.fetchOrders()
                await MainActor.run {
                    self.orderDatas = orders
                    self.tableView.reloadData()
                }
            } catch {
                print("fetchOrders failed: \(error)")
            }
        }
    }

    private func avatarImage(for indexPath: IndexPath) -> UIImage? {
        // 用 row 取得穩定 avatar，避免滾動時頭像變來變去
        let id = (indexPath.row % 8) + 1
        return UIImage(named: String(format: "00%d", id))
    }

    //以下設定tableviewcell
    override func numberOfSections(in tableView: UITableView) -> Int { 1 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { orderDatas.count }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellKey.OrderDetailTableViewCell, for: indexPath) as? OrderDetailTableViewCell else { return UITableViewCell() }
        cell.configure(with: orderDatas[indexPath.row], avatarImage: avatarImage(for: indexPath))
        return cell
    }

    //設定cell可swipe
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

        let deleteAction = UIContextualAction(style: .destructive, title: "刪除") { [weak self] (_, _, completionHandler) in
            guard let self = self,
                  let id = self.orderDatas[indexPath.row].id else {
                completionHandler(false)
                return
            }
            self.orderDatas.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            completionHandler(true)

            Task {
                do {
                    try await self.orderRepository.deleteOrder(id: id)
                } catch {
                    print("deleteOrder failed: \(error)")
                }
            }
        }

        let doNothingAction = UIContextualAction(style: .normal, title: "考慮") { (action, view, completionHandler) in
            completionHandler(true)
        }

        doNothingAction.backgroundColor = AppTheme.success

        let config = UISwipeActionsConfiguration(actions: [deleteAction, doNothingAction])
        config.performsFirstActionWithFullSwipe = true
        return config
    }

}
