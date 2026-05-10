//
//  StatusOverlayView.swift
//  NewOrderOoO
//
//  載入 / 空 / 錯誤的全頁覆蓋。
//  用法:overlay.show(.loading) / .show(.empty(...)) / .show(.error(...)) / .hide()
//

import UIKit

final class StatusOverlayView: UIView {

    enum State {
        case loading
        case empty(title: String, message: String?)
        case error(message: String, retry: () -> Void)
    }

    private let stack = UIStackView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let actionButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private var actionHandler: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = AppTheme.pageBackground

        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = AppTheme.primaryText
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        messageLabel.font = AppTheme.Font.secondary
        messageLabel.textColor = AppTheme.secondaryText
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center

        activityIndicator.color = AppTheme.accent
        activityIndicator.hidesWhenStopped = true

        actionButton.setTitleColor(AppTheme.accent, for: .normal)
        actionButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)

        stack.addArrangedSubview(activityIndicator)
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(messageLabel)
        stack.addArrangedSubview(actionButton)
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -32),
        ])
    }

    @objc private func actionTapped() { actionHandler?() }

    func show(_ state: State) {
        isHidden = false
        switch state {
        case .loading:
            titleLabel.isHidden = true
            messageLabel.isHidden = true
            actionButton.isHidden = true
            activityIndicator.startAnimating()
            actionHandler = nil

        case .empty(let title, let msg):
            activityIndicator.stopAnimating()
            titleLabel.text = title
            titleLabel.isHidden = false
            messageLabel.text = msg
            messageLabel.isHidden = (msg == nil)
            actionButton.isHidden = true
            actionHandler = nil

        case .error(let msg, let retry):
            activityIndicator.stopAnimating()
            titleLabel.text = "載入失敗"
            titleLabel.isHidden = false
            messageLabel.text = msg
            messageLabel.isHidden = false
            actionButton.setTitle("重試", for: .normal)
            actionButton.isHidden = false
            actionHandler = retry
        }
    }

    func hide() {
        isHidden = true
        activityIndicator.stopAnimating()
        actionHandler = nil
    }
}
