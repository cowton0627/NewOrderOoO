//
//  EditOrderViewController.swift
//  NewOrderOoO
//
//  編輯既有訂單(規格 / 訂購人 / 杯數)。
//

import UIKit

final class EditOrderViewController: UIViewController {

    var viewModel: EditOrderViewModel!
    var onSaved: (() -> Void)?

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let drinkLabel = UILabel()
    private let nameField = UITextField()
    private let quantityValueLabel = UILabel()
    private let quantityStepper = UIStepper()
    private let sizeSegment = UISegmentedControl(items: DrinkSize.allCases.map { $0.displayName })
    private let sugarSegment = UISegmentedControl(items: SugarLevel.allCases.map { $0.displayName })
    private let iceSegment = UISegmentedControl(items: IceLevel.allCases.map { $0.displayName })
    private let addSegment = UISegmentedControl(items: AddOn.allCases.map { $0.displayName })
    private let saveButton = UIButton(type: .system)

    /// saveButton 的 bottom constraint;鍵盤升起時往上推。
    private var saveButtonBottomConstraint: NSLayoutConstraint?
    private let saveButtonBaseBottom: CGFloat = -16

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "編輯訂單"
        // OrderDetailVC 開啟 prefersLargeTitles,push 過來會繼承 large title;
        // 此頁用 UIScrollView 而非 UITableView,跟 large title 收合行為不合 → 強制 inline。
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = AppTheme.pageBackground

        setupUI()
        prefill()

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillChange(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification, object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func keyboardWillChange(_ note: Notification) {
        guard let frame = (note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
              let duration = note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        let overlap = max(0, view.bounds.height - frame.minY - view.safeAreaInsets.bottom)
        saveButtonBottomConstraint?.constant = saveButtonBaseBottom - overlap
        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
    }

    @objc private func keyboardWillHide(_ note: Notification) {
        let duration = (note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
        saveButtonBottomConstraint?.constant = saveButtonBaseBottom
        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
    }

    private func prefill() {
        let order = viewModel.initialOrder
        drinkLabel.text = order.drinkName
        nameField.text = order.orderName
        sizeSegment.selectedSegmentIndex = DrinkSize.allCases.firstIndex { $0.rawValue == order.drinkSize } ?? 0
        sugarSegment.selectedSegmentIndex = SugarLevel.allCases.firstIndex { $0.rawValue == order.sugar } ?? 0
        iceSegment.selectedSegmentIndex = IceLevel.allCases.firstIndex { $0.rawValue == order.cold } ?? 0
        addSegment.selectedSegmentIndex = AddOn.allCases.firstIndex { $0.rawValue == order.add } ?? 0
        // UIStepper.value 跟 quantity 是 1:1(從 1 開始);minimumValue = 1 才不會出現 0 杯
        quantityStepper.value = Double(viewModel.initialQuantity)
        refreshQuantityLabel()
    }

    @objc private func quantityStepperChanged() {
        refreshQuantityLabel()
    }

    private func refreshQuantityLabel() {
        quantityValueLabel.text = "\(Int(quantityStepper.value)) 杯"
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
        nameField.returnKeyType = .done
        nameField.delegate = self

        drinkLabel.font = AppTheme.Font.detailTitle
        drinkLabel.textColor = AppTheme.primaryText
        drinkLabel.textAlignment = .center

        quantityValueLabel.font = .monospacedDigitSystemFont(ofSize: 17, weight: .semibold)
        quantityValueLabel.textColor = AppTheme.primaryText
        quantityValueLabel.textAlignment = .right
        quantityValueLabel.setContentHuggingPriority(.required, for: .horizontal)

        quantityStepper.tintColor = AppTheme.accent
        quantityStepper.minimumValue = 1
        quantityStepper.maximumValue = 99
        quantityStepper.stepValue = 1
        quantityStepper.value = 1
        quantityStepper.addTarget(self, action: #selector(quantityStepperChanged), for: .valueChanged)

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
        let saveBottom = saveButton.bottomAnchor.constraint(equalTo: safe.bottomAnchor, constant: saveButtonBaseBottom)
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
            saveBottom,
        ])
        saveButtonBottomConstraint = saveBottom

        nameField.heightAnchor.constraint(equalToConstant: 48).isActive = true
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

        // 數量 card:title 在左、value+stepper 在右,一行內排完
        let qtyTitle = sectionTitle("數量")
        let qtyRow = UIStackView(arrangedSubviews: [qtyTitle, UIView(), quantityValueLabel, quantityStepper])
        qtyRow.axis = .horizontal
        qtyRow.alignment = .center
        qtyRow.spacing = 8
        let quantityCard = formCard([qtyRow])

        let sizeCard = formCard([sectionTitle("大小"), sizeSegment])
        let sugarCard = formCard([sectionTitle("糖量"), sugarSegment])
        let iceCard = formCard([sectionTitle("冰塊"), iceSegment])
        let addCard = formCard([sectionTitle("加料"), addSegment])

        let stack = UIStackView(arrangedSubviews: [drinkCard, nameCard, quantityCard, sizeCard, sugarCard, iceCard, addCard])
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }

    @objc private func saveTapped() {
        view.endEditing(true)
        let name = nameField.text ?? ""
        let size = DrinkSize.allCases[sizeSegment.selectedSegmentIndex]
        let sugar = SugarLevel.allCases[sugarSegment.selectedSegmentIndex]
        let ice = IceLevel.allCases[iceSegment.selectedSegmentIndex]
        let add = AddOn.allCases[addSegment.selectedSegmentIndex]
        let quantity = Int(quantityStepper.value)

        Task { [weak self] in
            guard let self = self else { return }
            do {
                try await self.viewModel.save(name: name, size: size, sugar: sugar, ice: ice, add: add, quantity: quantity)
                await MainActor.run {
                    self.onSaved?()
                    self.navigationController?.popViewController(animated: true)
                }
            } catch let validation as OrderError {
                await MainActor.run {
                    self.presentInfoAlert(title: "注意", message: validation.errorDescription ?? "")
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

// MARK: - UITextFieldDelegate

extension EditOrderViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
