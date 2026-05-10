//
//  AppTheme.swift
//  NewOrderOoO
//
//  集中色彩、字型，避免散落於各 view controller。
//

import UIKit

enum AppTheme {

    // MARK: - 主色
    static let accent: UIColor = UIColor(named: "AccentColor") ?? .systemOrange
    static let danger: UIColor = .systemRed
    static let success: UIColor = .systemGreen

    // MARK: - 文字
    static let primaryText: UIColor = .label
    static let secondaryText: UIColor = .secondaryLabel
    static let tertiaryText: UIColor = .tertiaryLabel
    static let onAccentText: UIColor = .white

    // MARK: - 背景
    static let pageBackground: UIColor = .systemGroupedBackground
    static let cardBackground: UIColor = .secondarySystemGroupedBackground
    static let inputBackground: UIColor = .tertiarySystemFill
    static let imagePlaceholder: UIColor = .tertiarySystemFill
    static let selectionHighlight: UIColor = .systemGray6

    // MARK: - 圓角
    enum Radius {
        static let card: CGFloat = 18
        static let cardInner: CGFloat = 14
        static let thumb: CGFloat = 12
        static let input: CGFloat = 10
        static let button: CGFloat = 14
    }

    // MARK: - 字型
    enum Font {
        static let cardTitle = UIFont.systemFont(ofSize: 17, weight: .semibold)
        static let detailTitle = UIFont.systemFont(ofSize: 24, weight: .bold)
        static let body = UIFont.systemFont(ofSize: 16, weight: .regular)
        static let secondary = UIFont.systemFont(ofSize: 13, weight: .regular)
        static let caption = UIFont.systemFont(ofSize: 12, weight: .regular)

        static let priceMedium = UIFont.monospacedDigitSystemFont(ofSize: 15, weight: .bold)
        static let priceLarge = UIFont.monospacedDigitSystemFont(ofSize: 22, weight: .bold)

        static let segmentNormal = UIFont.systemFont(ofSize: 14, weight: .medium)
        static let segmentSelected = UIFont.systemFont(ofSize: 14, weight: .semibold)
        static let buttonLabel = UIFont.systemFont(ofSize: 18, weight: .semibold)
        static let formLabel = UIFont.systemFont(ofSize: 17, weight: .medium)
    }

    // MARK: - 陰影
    enum Shadow {
        static func card(on layer: CALayer) {
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOpacity = 0.06
            layer.shadowRadius = 10
            layer.shadowOffset = CGSize(width: 0, height: 4)
        }
        static func button(on layer: CALayer) {
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOpacity = 0.18
            layer.shadowRadius = 14
            layer.shadowOffset = CGSize(width: 0, height: 6)
        }
    }
}
