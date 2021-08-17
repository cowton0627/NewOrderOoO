//
//  MenuDetailTableViewController.swift
//  NewOrderOoO
//
//  Created by 鄭淳澧 on 2021/8/15.
//

import UIKit
import Foundation
import Firebase
import FirebaseFirestoreSwift

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
        self.tableView.isScrollEnabled = false
        dtImgView.image = UIImage(named: productData.imgName)
        dtNameLabel.text = productData.name
        dtNameLabel.textColor = #colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1)
        updatePriceLabel(priceData: productData.price, senderValue: dtStepper.value)

        db = Firestore.firestore()
        
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

