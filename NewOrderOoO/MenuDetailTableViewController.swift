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
    @IBOutlet weak var dtImgView: UIImageView!
    @IBOutlet weak var dtNameLabel: UILabel!
    @IBOutlet weak var dtPriceLabel: UILabel!       //新增的貨幣金額
    @IBOutlet weak var productCountLabel: UILabel!  //新增的訂購量, 訂購量不會在訂單結果顯示

    @IBOutlet weak var dtStepper: UIStepper!

    @IBOutlet weak var orderNameTextField: UITextField!
    @IBOutlet weak var orderSizeSegCon: UISegmentedControl!
    @IBOutlet weak var orderSugarSegCon: UISegmentedControl!
    @IBOutlet weak var orderIceSegCon: UISegmentedControl!
    @IBOutlet weak var orderAddSegCon: UISegmentedControl!

    var db: Firestore!
    var productData: ProductData!

    /*
    storyboard產生的controller需定義coder: NSCoder,
    其他地方產生如用super.init(nibName: nil, bundle: nil), 則不需coder參數

     init?(_ coder: NSCoder, productData: ProductData, _ database: Firestore) {
         self.productData = productData
         self.db = database
         super.init(coder: coder)
     }

     required init?(coder: NSCoder) {
         fatalError("init(coder: ) has not been inplemented.")
     }

       使用init定義controller的這個傳值方法, 麻煩在於controller裡的變數都得定義,
     於是乎, 在傳送頁竟要多宣告一個不會用到的 let bd: Firestore!
     並在viewDidLoad裡 bd = Firestore.firestore()初始化
    */

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.isScrollEnabled = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = .systemGroupedBackground

        applyStyle()

        dtImgView.image = UIImage(named: productData.imgName)
        dtNameLabel.text = productData.name
        updatePriceLabel(priceData: productData.price, senderValue: dtStepper.value)

        db = Firestore.firestore()
    }

    private func applyStyle() {
        let accent = UIColor(named: "AccentColor") ?? .systemOrange

        dtImgView.contentMode = .scaleAspectFill
        dtImgView.layer.cornerRadius = 16
        dtImgView.layer.cornerCurve = .continuous
        dtImgView.layer.masksToBounds = true
        dtImgView.backgroundColor = .tertiarySystemFill

        dtNameLabel.font = .systemFont(ofSize: 24, weight: .bold)
        dtNameLabel.textColor = .label

        dtPriceLabel.font = .monospacedDigitSystemFont(ofSize: 22, weight: .bold)
        dtPriceLabel.textColor = accent

        productCountLabel.font = .systemFont(ofSize: 15, weight: .medium)
        productCountLabel.textColor = .secondaryLabel

        dtStepper.tintColor = accent

        orderNameTextField.borderStyle = .none
        orderNameTextField.backgroundColor = .tertiarySystemFill
        orderNameTextField.layer.cornerRadius = 10
        orderNameTextField.layer.cornerCurve = .continuous
        orderNameTextField.layer.masksToBounds = true
        orderNameTextField.font = .systemFont(ofSize: 16, weight: .regular)
        let leftPad = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        orderNameTextField.leftView = leftPad
        orderNameTextField.leftViewMode = .always
        orderNameTextField.attributedPlaceholder = NSAttributedString(
            string: "請輸入姓名",
            attributes: [.foregroundColor: UIColor.tertiaryLabel]
        )

        let segments: [UISegmentedControl?] = [orderSizeSegCon, orderSugarSegCon, orderIceSegCon, orderAddSegCon]
        for seg in segments {
            seg?.selectedSegmentTintColor = accent
            seg?.setTitleTextAttributes([
                .foregroundColor: UIColor.label,
                .font: UIFont.systemFont(ofSize: 14, weight: .medium)
            ], for: .normal)
            seg?.setTitleTextAttributes([
                .foregroundColor: UIColor.white,
                .font: UIFont.systemFont(ofSize: 14, weight: .semibold)
            ], for: .selected)
        }

        styleSendButton()
    }

    private func styleSendButton() {
        guard let button = tableView.tableFooterView as? UIButton else { return }

        button.removeFromSuperview()
        tableView.tableFooterView = nil

        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 14
        button.layer.cornerCurve = .continuous
        button.layer.masksToBounds = false
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.18
        button.layer.shadowRadius = 14
        button.layer.shadowOffset = CGSize(width: 0, height: 6)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)

        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            button.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            button.heightAnchor.constraint(equalToConstant: 56),
        ])

        tableView.contentInset.bottom = 84
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // 拿掉 storyboard 的 systemGray4 / 5 / 6 條紋
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear

        let cardTag = 0xC0DE
        if cell.viewWithTag(cardTag) == nil {
            let card = UIView()
            card.tag = cardTag
            card.backgroundColor = .secondarySystemGroupedBackground
            card.layer.cornerRadius = 14
            card.layer.cornerCurve = .continuous
            card.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.insertSubview(card, at: 0)
            NSLayoutConstraint.activate([
                card.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                card.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                card.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 4),
                card.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -4),
            ])
        }
    }

    //為stepper寫的轉換字串, 用以更新 dtPriceLabel、productCountLabel
    func updatePriceLabel(priceData: String, senderValue: Double?) {
        let moneySubStr = priceData.dropFirst()
        let moneyStr = String(moneySubStr)
        let moneyDouble = Double(moneyStr)
        guard let moneyDouble = moneyDouble else { return }

        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "zh_tw")
        formatter.numberStyle = .currencyISOCode
        //顯示為沒有小數點的貨幣
        formatter.maximumFractionDigits = 0

        if senderValue != 0 {
            let dtPriceStr = formatter.string(from: NSNumber(value: moneyDouble * (senderValue! + 1)))
            dtPriceLabel.text = dtPriceStr
        } else {
            let dtPriceStr = formatter.string(from: NSNumber(value: moneyDouble))
            dtPriceLabel.text = dtPriceStr
        }

        //顯示訂購量
        productCountLabel.text = " " + "\(Int(dtStepper.value + 1))" + "杯"
    }

    //以下UI元件
    @IBAction func stepperTapped(_ sender: UIStepper) {
        updatePriceLabel(priceData: productData!.price, senderValue: sender.value)
        print(sender.value)
    }


    @IBAction func orderSended(_ sender: UIButton) {
        if orderNameTextField.text?.trimmingCharacters(in: .whitespaces).isEmpty == false {

            db?.collection("orderList").addDocument(data: [

                "orderName": orderNameTextField.text ?? "",
                "drinkName": dtNameLabel.text ?? "",
                "drinkSize": orderSizeSegCon.titleForSegment(at: orderSizeSegCon.selectedSegmentIndex) ?? "",
                "sugar": orderSugarSegCon.titleForSegment(at: orderSugarSegCon.selectedSegmentIndex) ?? "",
                "cold": orderIceSegCon.titleForSegment(at: orderIceSegCon.selectedSegmentIndex) ?? "",
                "add": orderAddSegCon.titleForSegment(at: orderAddSegCon.selectedSegmentIndex) ?? "",
                "price": dtPriceLabel.text ?? ""

            ]) { error in
                if let error = error { print(error) }
            }

            let content = UNMutableNotificationContent()
            content.title = "wow！恭喜您～"
            content.subtitle = "訂購成功"

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
            let request = UNNotificationRequest(identifier: "noti", content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request) { error in
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
