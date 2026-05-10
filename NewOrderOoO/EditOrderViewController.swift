//
//  EditOrderViewController.swift
//  NewOrderOoO
//
//  編輯既有訂單(改規格 / 訂購人姓名),不改數量(quantity 並未存於 Firestore)。
//

import UIKit

final class EditOrderViewController: UIViewController {

    var orderID: String!
    var initialOrder: OrderData!
    var repository: OrderRepository = FirestoreOrderRepository()
    var onSaved: (() -> Void)?

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let drinkLabel = UILabel()
    private let nameField = UITextField()
    private let sizeSegment = UISegmentedControl(items: DrinkSize.allCases.map { $0.displayName })
    private let sugarSegment = UISegmentedControl(items: SugarLevel.allCases.map { $0.displayName })
    private let iceSegment = UISegmentedControl(items: IceLevel.allCases.map { $0.displayName })
    private let addSegment = UISegmentedControl(items: AddOn.allCases.map { $0.displayName })
    private let saveButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "編輯訂單"
        view.backgroundColor = AppTheme.pageBackground

        setupUI()
        prefill()
    }

    private func prefill() {
        drinkLabel.text = initialOrder.drinkName
        nameField.text = initialOrder.orderName
        sizeSegment.selectedSegmentIndex = DrinkSize.allCases.firstIndex { $0.rawValue == initialOrder.drinkSize } ?? 0
        sugarSegment.selectedSegmentIndex = SugarLevel.allCases.firstIndex { $0.rawValue == initialOrder.sugar } ?? 0
        iceSegment.selectedSegmentIndex = IceLevel.allCases.firstIndex { $0.rawValue == initialOrder.cold } ?? 0
        addSegment.selectedSegmentIndex = AddOn.allCases.firstIndex { $0.rawValue == initialOrder.add } ?? 0
    }

    private func setupUI() {
        for seg in [sizeSegment, sugarSegment, iceSegment, addSegment] {
            seg.selectedSegmentTintColor = AppTheme.accent
            seg.setTitleTextAttributes([.foregroundColor: AppTheme.primaryText, .font: AppTheme.Font.segmentNormal], for: .normal)
            seg.setTitleTextAttributes([.foregroundColor: AppTheme.onAccentText, .font: AppTheme.Font.segmentSelected], for: .selected)
        }

        nameField.borderStyle = .none
        nameField.backgroundColor = AppTheme.inputBackground
        nameField.layer.cornerRadius = AppTheme.Radius.input
        nameField.layer.cornerCurve = .continuous
        nameField.layer.masksToBounds = true
        nameField.font = AppTheme.Font.body
        let leftPad = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        nameField.leftView = leftPad
        nameField.leftViewMode = .always

        drinkLabel.font = AppTheme.Font.detailTitle
        drinkLabel.textColor = AppTheme.primaryText
        drinkLabel.textAlignment = .center

        saveButton.setTitle("儲存變更", for: .normal)
        saveButton.titleLabel?.font = AppTheme.Font.buttonLabel
        saveButton.setTitleColor(AppTheme.onAccentText, for: .normal)
        saveButton.backgroundColor = AppTheme.accent
        saveButton.layer.cornerRadius = AppTheme.Radius.button
        saveButton.layer.cornerCurve = .continuous
        AppTheme.Shadow.button(on: saveButton.layer)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        let formStack = makeFormStack()

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        contentView.addSubview(formStack)
        formStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(saveButton)
        saveButton.translatesAutoresizingMaskIntoConstraints = false

        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safe.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: saveButton.topAnchor, constant: -12),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            formStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            formStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            formStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            formStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),

            saveButton.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 16),
            saveButton.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -16),
            saveButton.heightAnchor.constraint(equalToConstant: 56),
            saveButton.bottomAnchor.constraint(equalTo: safe.bottomAnchor, constant: -16),
        ])

        nameField.heightAnchor.constraint(equalToConstant: 40).isActive = true
    }

    private func makeFormStack() -> UIStackView {
        func formCard(_ subviews: [UIView]) -> UIView {
            let card = UIView()
            card.backgroundColor = AppTheme.cardBackground
            card.layer.cornerRadius = AppTheme.Radius.cardInner
            card.layer.cornerCurve = .continuous

            let s = UIStackView(arrangedSubviews: subviews)
            s.axis = .vertical
            s.spacing = 10
            s.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(s)
            NSLayoutConstraint.activate([
                s.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
                s.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
                s.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
                s.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
            ])
            return card
        }

        func sectionTitle(_ text: String) -> UILabel {
            let l = UILabel()
            l.text = text
            l.font = AppTheme.Font.formLabel
            l.textColor = AppTheme.primaryText
            return l
        }

        let drinkCard = formCard([drinkLabel])
        let nameCard = formCard([sectionTitle("訂購人"), nameField])
        let sizeCard = formCard([sectionTitle("大小"), sizeSegment])
        let sugarCard = formCard([sectionTitle("糖量"), sugarSegment])
        let iceCard = formCard([sectionTitle("冰塊"), iceSegment])
        let addCard = formCard([sectionTitle("加料"), addSegment])

        let stack = UIStackView(arrangedSubviews: [drinkCard, nameCard, sizeCard, sugarCard, iceCard, addCard])
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }

    @objc private func saveTapped() {
        let name = (nameField.text ?? "").trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else {
            presentInfoAlert(title: "注意", message: "訂購人不得為空")
            return
        }

        let size = DrinkSize.allCases[sizeSegment.selectedSegmentIndex]
        let sugar = SugarLevel.allCases[sugarSegment.selectedSegmentIndex]
        let ice = IceLevel.allCases[iceSegment.selectedSegmentIndex]
        let add = AddOn.allCases[addSegment.selectedSegmentIndex]

        Task { [weak self] in
            guard let self = self else { return }
            do {
                try await self.repository.updateOrder(
                    id: self.orderID,
                    orderName: name, size: size, sugar: sugar, ice: ice, add: add
                )
                await MainActor.run {
                    self.onSaved?()
                    self.navigationController?.popViewController(animated: true)
                }
            } catch {
                await MainActor.run {
                    self.presentInfoAlert(title: "儲存失敗", message: error.localizedDescription)
                }
            }
        }
    }

    private func presentInfoAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好", style: .cancel))
        present(alert, animated: true)
    }
}
