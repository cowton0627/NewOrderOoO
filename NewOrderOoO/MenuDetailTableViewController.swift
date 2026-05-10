//
//  MenuDetailTableViewController.swift
//  NewOrderOoO
//
//  Created by 鄭淳澧 on 2021/8/15.
//

import UIKit
import Foundation
import FirebaseFirestore

class MenuDetailTableViewController: UITableViewController {
    // storyboard 上原本第 1 個 cell 的 outlet 仍保留（cell 高度設 0 隱藏），但實際 UI 改用下方 hero card。
    @IBOutlet weak var dtImgView: UIImageView!
    @IBOutlet weak var dtNameLabel: UILabel!
    @IBOutlet weak var dtPriceLabel: UILabel!
    @IBOutlet weak var productCountLabel: UILabel!
    @IBOutlet weak var dtStepper: UIStepper!

    @IBOutlet weak var orderNameTextField: UITextField!
    @IBOutlet weak var orderSizeSegCon: UISegmentedControl!
    @IBOutlet weak var orderSugarSegCon: UISegmentedControl!
    @IBOutlet weak var orderIceSegCon: UISegmentedControl!
    @IBOutlet weak var orderAddSegCon: UISegmentedControl!

    var db: Firestore!
    var productData: ProductData!

    // MARK: - Hero card (取代 storyboard row 0)
    private let heroCard = UIView()
    private let heroThumb = UIImageView()
    private let heroName = UILabel()
    private let heroPrice = PaddedLabel()
    private let heroContent = UILabel()
    private let heroDescription = UILabel()
    private let heroSeparator = UIView()
    private let heroCountTitle = UILabel()
    private let heroCountValue = UILabel()
    private let heroCountUnit = UILabel()
    private let heroStepper = UIStepper()

    // 對應 storyboard 上 7 個 static cells 的高度（row 0 用 hero card 取代,row 6 是 storyboard 預留的空白 cell,都設 0 隱藏）
    private let staticHeights: [CGFloat] = [0, 77, 77, 66, 77, 77, 0]

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.isScrollEnabled = true
        tableView.separatorStyle = .none
        tableView.backgroundColor = AppTheme.pageBackground
        tableView.alwaysBounceVertical = true

        applyStyle()
        buildHeroHeader()
        refreshHero(stepperValue: 0)

        db = Firestore.firestore()
    }

    // MARK: - Hero card

    private func buildHeroHeader() {
        heroCard.translatesAutoresizingMaskIntoConstraints = false
        heroCard.backgroundColor = AppTheme.cardBackground
        heroCard.layer.cornerRadius = AppTheme.Radius.card
        heroCard.layer.cornerCurve = .continuous

        heroThumb.translatesAutoresizingMaskIntoConstraints = false
        heroThumb.contentMode = .scaleAspectFit
        heroThumb.backgroundColor = AppTheme.imagePlaceholder
        heroThumb.clipsToBounds = true
        heroCard.addSubview(heroThumb)

        heroName.font = AppTheme.Font.detailTitle
        heroName.textColor = AppTheme.primaryText
        heroName.numberOfLines = 1
        heroName.setContentHuggingPriority(.defaultLow, for: .horizontal)
        heroName.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        heroPrice.font = .monospacedDigitSystemFont(ofSize: 17, weight: .bold)
        heroPrice.textColor = AppTheme.accent
        heroPrice.backgroundColor = AppTheme.accent.withAlphaComponent(0.15)
        heroPrice.textAlignment = .center
        heroPrice.contentInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
        heroPrice.setContentCompressionResistancePriority(.required, for: .horizontal)
        heroPrice.setContentHuggingPriority(.required, for: .horizontal)

        heroContent.font = .systemFont(ofSize: 14, weight: .medium)
        heroContent.textColor = AppTheme.secondaryText
        heroContent.numberOfLines = 1

        heroDescription.font = AppTheme.Font.caption
        heroDescription.textColor = AppTheme.tertiaryText
        heroDescription.numberOfLines = 3

        heroSeparator.translatesAutoresizingMaskIntoConstraints = false
        heroSeparator.backgroundColor = UIColor.separator.withAlphaComponent(0.5)

        heroCountTitle.font = AppTheme.Font.formLabel
        heroCountTitle.textColor = AppTheme.primaryText
        heroCountTitle.text = "數量"

        heroCountValue.font = .monospacedDigitSystemFont(ofSize: 19, weight: .semibold)
        heroCountValue.textColor = AppTheme.primaryText
        heroCountValue.textAlignment = .right

        heroCountUnit.font = AppTheme.Font.secondary
        heroCountUnit.textColor = AppTheme.secondaryText
        heroCountUnit.text = "杯"

        heroStepper.tintColor = AppTheme.accent
        heroStepper.maximumValue = 99
        heroStepper.minimumValue = 0
        heroStepper.value = 0
        heroStepper.addTarget(self, action: #selector(heroStepperChanged(_:)), for: .valueChanged)

        // 標題列：品名 + 價格膠囊
        let titleRow = UIStackView(arrangedSubviews: [heroName, heroPrice])
        titleRow.axis = .horizontal
        titleRow.alignment = .firstBaseline
        titleRow.spacing = 8

        // 數量列：標題 + 杯數 + 杯 + Stepper
        let countSpacer = UIView()
        countSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let countRow = UIStackView(arrangedSubviews: [heroCountTitle, countSpacer, heroCountValue, heroCountUnit, heroStepper])
        countRow.axis = .horizontal
        countRow.alignment = .center
        countRow.spacing = 6

        // 整體垂直 stack
        let infoStack = UIStackView(arrangedSubviews: [titleRow, heroContent, heroDescription, heroSeparator, countRow])
        infoStack.axis = .vertical
        infoStack.spacing = 8
        infoStack.setCustomSpacing(14, after: heroDescription)
        infoStack.setCustomSpacing(14, after: heroSeparator)
        infoStack.translatesAutoresizingMaskIntoConstraints = false
        heroCard.addSubview(infoStack)

        NSLayoutConstraint.activate([
            heroThumb.topAnchor.constraint(equalTo: heroCard.topAnchor),
            heroThumb.leadingAnchor.constraint(equalTo: heroCard.leadingAnchor),
            heroThumb.trailingAnchor.constraint(equalTo: heroCard.trailingAnchor),
            heroThumb.heightAnchor.constraint(equalToConstant: 300),

            infoStack.topAnchor.constraint(equalTo: heroThumb.bottomAnchor, constant: 16),
            infoStack.leadingAnchor.constraint(equalTo: heroCard.leadingAnchor, constant: 16),
            infoStack.trailingAnchor.constraint(equalTo: heroCard.trailingAnchor, constant: -16),
            infoStack.bottomAnchor.constraint(equalTo: heroCard.bottomAnchor, constant: -16),

            heroSeparator.heightAnchor.constraint(equalToConstant: 1),
        ])

        // 包進帶左右 padding 的 container 後設成 tableHeaderView
        let container = UIView()
        container.backgroundColor = .clear
        container.addSubview(heroCard)

        NSLayoutConstraint.activate([
            heroCard.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            heroCard.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            heroCard.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            heroCard.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
        ])

        // 圖片自己圓角（只圓上半），heroCard masksToBounds = false 才能露出陰影
        AppTheme.Shadow.card(on: heroCard.layer)
        heroCard.layer.masksToBounds = false
        heroThumb.layer.cornerRadius = AppTheme.Radius.card
        heroThumb.layer.cornerCurve = .continuous
        heroThumb.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        heroThumb.layer.masksToBounds = true

        tableView.tableHeaderView = container
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard let header = tableView.tableHeaderView else { return }
        let targetWidth = tableView.bounds.width
        guard targetWidth > 0 else { return }

        let fitted = header.systemLayoutSizeFitting(
            CGSize(width: targetWidth, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )

        if abs(header.frame.height - fitted.height) > 0.5 || header.frame.width != targetWidth {
            header.frame = CGRect(x: 0, y: 0, width: targetWidth, height: fitted.height)
            tableView.tableHeaderView = header
        }
    }

    @objc private func heroStepperChanged(_ sender: UIStepper) {
        refreshHero(stepperValue: sender.value)
    }

    private func refreshHero(stepperValue: Double) {
        heroThumb.image = UIImage(named: productData.imgName)
        heroName.text = productData.name
        heroContent.text = productData.content
        heroDescription.text = productData.description

        let moneySub = productData.price.dropFirst()
        let moneyDouble = Double(String(moneySub)) ?? 0

        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "zh_tw")
        formatter.numberStyle = .currencyISOCode
        formatter.maximumFractionDigits = 0

        let total = stepperValue == 0 ? moneyDouble : moneyDouble * (stepperValue + 1)
        heroPrice.text = formatter.string(from: NSNumber(value: total))
        heroCountValue.text = "\(Int(stepperValue + 1))"
    }

    // MARK: - 表單樣式（姓名、大小、糖、冰、加料）

    private func applyStyle() {
        orderNameTextField.borderStyle = .none
        orderNameTextField.backgroundColor = AppTheme.inputBackground
        orderNameTextField.layer.cornerRadius = AppTheme.Radius.input
        orderNameTextField.layer.cornerCurve = .continuous
        orderNameTextField.layer.masksToBounds = true
        orderNameTextField.font = AppTheme.Font.body
        let leftPad = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        orderNameTextField.leftView = leftPad
        orderNameTextField.leftViewMode = .always
        orderNameTextField.attributedPlaceholder = NSAttributedString(
            string: "請輸入姓名",
            attributes: [.foregroundColor: AppTheme.tertiaryText]
        )

        let segments: [UISegmentedControl?] = [orderSizeSegCon, orderSugarSegCon, orderIceSegCon, orderAddSegCon]
        for seg in segments {
            seg?.selectedSegmentTintColor = AppTheme.accent
            seg?.setTitleTextAttributes([
                .foregroundColor: AppTheme.primaryText,
                .font: AppTheme.Font.segmentNormal
            ], for: .normal)
            seg?.setTitleTextAttributes([
                .foregroundColor: AppTheme.onAccentText,
                .font: AppTheme.Font.segmentSelected
            ], for: .selected)
        }

        styleSendButton()
    }

    private func styleSendButton() {
        guard let button = tableView.tableFooterView as? UIButton else { return }

        button.removeFromSuperview()
        tableView.tableFooterView = nil

        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = AppTheme.Radius.button
        button.layer.cornerCurve = .continuous
        button.layer.masksToBounds = false
        AppTheme.Shadow.button(on: button.layer)
        button.titleLabel?.font = AppTheme.Font.buttonLabel

        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            button.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            button.heightAnchor.constraint(equalToConstant: 56),
        ])

        tableView.contentInset.bottom = 84
    }

    // MARK: - Static cells 高度（row 0 隱藏）

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.row < staticHeights.count else { return 0 }
        return staticHeights[indexPath.row]
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == 0 { return } // hero card 取代

        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear

        let cardTag = 0xC0DE
        if cell.viewWithTag(cardTag) == nil {
            let card = UIView()
            card.tag = cardTag
            card.backgroundColor = AppTheme.cardBackground
            card.layer.cornerRadius = AppTheme.Radius.cardInner
            card.layer.cornerCurve = .continuous
            card.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.insertSubview(card, at: 0)
            NSLayoutConstraint.activate([
                card.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                card.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                card.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 4),
                card.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -4),
            ])

            // storyboard 元件用 contentView 16pt margin,加進 card 後會貼齊 card 邊。
            // 動態把 leading 16 → 32、trailingMargin 8 → 16,讓元件相對 card 內縮 16pt。
            for c in cell.contentView.constraints {
                if (c.firstItem as? UIView)?.tag == cardTag { continue }
                if (c.secondItem as? UIView)?.tag == cardTag { continue }

                if c.firstAttribute == .leading, c.secondAttribute == .leading, c.constant == 16 {
                    c.constant = 32
                }
                if c.firstAttribute == .trailingMargin, c.secondAttribute == .trailing, c.constant == 8 {
                    c.constant = 16
                }
            }
        }
    }

    // MARK: - Storyboard IBAction（保留以避免 storyboard 連結失效，實際 stepper 改用 hero）

    @IBAction func stepperTapped(_ sender: UIStepper) {
        refreshHero(stepperValue: sender.value)
    }

    @IBAction func orderSended(_ sender: UIButton) {
        if orderNameTextField.text?.trimmingCharacters(in: .whitespaces).isEmpty == false {

            db?.collection("orderList").addDocument(data: [
                "orderName": orderNameTextField.text ?? "",
                "drinkName": productData.name,
                "drinkSize": orderSizeSegCon.titleForSegment(at: orderSizeSegCon.selectedSegmentIndex) ?? "",
                "sugar": orderSugarSegCon.titleForSegment(at: orderSugarSegCon.selectedSegmentIndex) ?? "",
                "cold": orderIceSegCon.titleForSegment(at: orderIceSegCon.selectedSegmentIndex) ?? "",
                "add": orderAddSegCon.titleForSegment(at: orderAddSegCon.selectedSegmentIndex) ?? "",
                "price": heroPrice.text ?? "",
            ]) { error in
                if let error = error { print(error) }
            }

            let content = UNMutableNotificationContent()
            content.title = "wow！恭喜您～"
            content.subtitle = "訂購成功"

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
            let request = UNNotificationRequest(identifier: "noti", content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request) { _ in
                print("成功建立前景通知")
            }

            self.performSegue(withIdentifier: "orderSendedDB", sender: nil)

        } else {
            let alert = UIAlertController(title: "注意", message: "姓名欄不得為空", preferredStyle: .alert)
            let alertAction = UIAlertAction(title: "上一步", style: .cancel, handler: nil)
            alert.addAction(alertAction)
            present(alert, animated: true, completion: nil)
            print("購買人欄位為空")
        }
    }
}
