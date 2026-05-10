//
//  ReceiptViewController.swift
//  NewOrderOoO
//
//  下單成功後的確認頁。Programmatic UI,不用 storyboard。
//

import UIKit

struct ReceiptSummary {
    let orderName: String
    let drinkName: String
    let size: DrinkSize
    let sugar: SugarLevel
    let ice: IceLevel
    let add: AddOn
    let quantity: Int
    let totalPrice: Money
    let orderID: String
}

final class ReceiptViewController: UIViewController {

    var summary: ReceiptSummary!

    private let card = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "訂單確認"
        view.backgroundColor = AppTheme.pageBackground
        navigationItem.hidesBackButton = true

        setupUI()
    }

    private func setupUI() {
        // 大綠勾勾
        let checkImageView = UIImageView()
        checkImageView.translatesAutoresizingMaskIntoConstraints = false
        checkImageView.contentMode = .scaleAspectFit
        checkImageView.tintColor = AppTheme.success
        checkImageView.image = UIImage(systemName: "checkmark.circle.fill",
                                       withConfiguration: UIImage.SymbolConfiguration(pointSize: 80, weight: .regular))

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "訂單已送出"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = AppTheme.primaryText
        titleLabel.textAlignment = .center

        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "感謝訂購,我們很快就會準備好"
        subtitleLabel.font = AppTheme.Font.secondary
        subtitleLabel.textColor = AppTheme.secondaryText
        subtitleLabel.textAlignment = .center

        // 摘要卡
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = AppTheme.cardBackground
        card.layer.cornerRadius = AppTheme.Radius.card
        card.layer.cornerCurve = .continuous
        AppTheme.Shadow.card(on: card.layer)

        let summaryStack = makeSummaryStack()
        summaryStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(summaryStack)

        // 按鈕
        let viewOrdersButton = UIButton(type: .system)
        viewOrdersButton.translatesAutoresizingMaskIntoConstraints = false
        viewOrdersButton.setTitle("查看所有訂單", for: .normal)
        viewOrdersButton.titleLabel?.font = AppTheme.Font.buttonLabel
        viewOrdersButton.setTitleColor(AppTheme.onAccentText, for: .normal)
        viewOrdersButton.backgroundColor = AppTheme.accent
        viewOrdersButton.layer.cornerRadius = AppTheme.Radius.button
        viewOrdersButton.layer.cornerCurve = .continuous
        AppTheme.Shadow.button(on: viewOrdersButton.layer)
        viewOrdersButton.addTarget(self, action: #selector(viewOrdersTapped), for: .touchUpInside)

        let backButton = UIButton(type: .system)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.setTitle("再點一杯", for: .normal)
        backButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        backButton.setTitleColor(AppTheme.accent, for: .normal)
        backButton.addTarget(self, action: #selector(backToMenuTapped), for: .touchUpInside)

        view.addSubview(checkImageView)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(card)
        view.addSubview(viewOrdersButton)
        view.addSubview(backButton)

        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            checkImageView.topAnchor.constraint(equalTo: safe.topAnchor, constant: 24),
            checkImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            titleLabel.topAnchor.constraint(equalTo: checkImageView.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            card.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            summaryStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            summaryStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            summaryStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            summaryStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),

            viewOrdersButton.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 16),
            viewOrdersButton.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -16),
            viewOrdersButton.heightAnchor.constraint(equalToConstant: 56),
            viewOrdersButton.bottomAnchor.constraint(equalTo: backButton.topAnchor, constant: -8),

            backButton.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 16),
            backButton.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -16),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            backButton.bottomAnchor.constraint(equalTo: safe.bottomAnchor, constant: -12),
        ])
    }

    private func makeSummaryStack() -> UIStackView {
        func row(_ title: String, _ value: String) -> UIView {
            let titleL = UILabel()
            titleL.text = title
            titleL.font = AppTheme.Font.secondary
            titleL.textColor = AppTheme.secondaryText
            titleL.setContentHuggingPriority(.defaultHigh, for: .horizontal)

            let valueL = UILabel()
            valueL.text = value
            valueL.font = .systemFont(ofSize: 15, weight: .medium)
            valueL.textColor = AppTheme.primaryText
            valueL.textAlignment = .right
            valueL.numberOfLines = 0

            let h = UIStackView(arrangedSubviews: [titleL, valueL])
            h.axis = .horizontal
            h.spacing = 8
            h.alignment = .firstBaseline
            return h
        }

        let totalTitleL = UILabel()
        totalTitleL.text = "總額"
        totalTitleL.font = AppTheme.Font.formLabel
        totalTitleL.textColor = AppTheme.primaryText

        let totalValueL = PaddedLabel()
        totalValueL.text = summary.totalPrice.formattedISO()
        totalValueL.font = .monospacedDigitSystemFont(ofSize: 17, weight: .bold)
        totalValueL.textColor = AppTheme.accent
        totalValueL.backgroundColor = AppTheme.accent.withAlphaComponent(0.15)
        totalValueL.contentInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
        totalValueL.setContentHuggingPriority(.required, for: .horizontal)
        totalValueL.setContentCompressionResistancePriority(.required, for: .horizontal)

        let totalRow = UIStackView(arrangedSubviews: [totalTitleL, totalValueL])
        totalRow.axis = .horizontal
        totalRow.alignment = .center

        let separator = UIView()
        separator.backgroundColor = UIColor.separator.withAlphaComponent(0.5)
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true

        let spec = "\(summary.size.displayName) · \(summary.sugar.displayName) · \(summary.ice.displayName) · \(summary.add.displayName)"

        let stack = UIStackView(arrangedSubviews: [
            row("訂購人", summary.orderName),
            row("飲料", summary.drinkName),
            row("規格", spec),
            row("數量", "\(summary.quantity) 杯"),
            separator,
            totalRow,
        ])
        stack.axis = .vertical
        stack.spacing = 10
        stack.setCustomSpacing(14, after: separator)
        return stack
    }

    @objc private func viewOrdersTapped() {
        guard let nav = navigationController else { return }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let orders = storyboard.instantiateViewController(withIdentifier: "OrderDetail") as? OrderDetailTableViewController else {
            return
        }
        // 把整條堆疊重設成:root → orders,把 menu detail 跟 receipt 同時清掉
        var stack = nav.viewControllers
        if let rootIndex = stack.firstIndex(where: { $0 is MenuTableViewController }) {
            stack = Array(stack.prefix(rootIndex + 1))
        }
        stack.append(orders)
        nav.setViewControllers(stack, animated: true)
    }

    @objc private func backToMenuTapped() {
        navigationController?.popToRootViewController(animated: true)
    }
}
