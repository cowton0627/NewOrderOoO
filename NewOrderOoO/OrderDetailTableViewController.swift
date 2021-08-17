//
//  OrderDetailTableViewController.swift
//  NewOrderOoO
//
//  Created by 鄭淳澧 on 2021/8/15.
//

import UIKit
import Firebase
import FirebaseFirestoreSwift

class OrderDetailTableViewCell: UITableViewCell {
 
    @IBOutlet weak var portraitImgView: UIImageView!
    @IBOutlet weak var orderNameLabel: UILabel!     //新增的訂購名
    @IBOutlet weak var drinkNameLabel: UILabel!
    @IBOutlet weak var drinkSizeLabel: UILabel!
    @IBOutlet weak var sugarLabel: UILabel!
    @IBOutlet weak var coldLabel: UILabel!
    @IBOutlet weak var addLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!

}


class OrderDetailTableViewController: UITableViewController {
    @IBOutlet weak var animeImgView: UIImageView!
    
    var db: Firestore!
    
    struct cellKey {
        static let OrderDetailTableViewCell = "OrderDetailTableViewCell"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let data = NSDataAsset(name: "anime")?.data {
            let cfData = data as CFData
            CGAnimateImageDataWithBlock(cfData, nil) { (_, cgImage, _) in
                     self.animeImgView.image = UIImage(cgImage: cgImage)
            }
        }
        
        db = Firestore.firestore()
        fetchData()

    }
    

//    var documentId: [String] = []
//    var orderNameList: [String] = []
//    var drinkNameList: [String] = []
//    var drinkSizeList: [String] = []
//    var sugarList: [String] = []
//    var coldList: [String] = []
//    var addList: [String] = []
//    var priceList: [String] = []
    
    var orderDatas = [OrderData]()
    
    func fetchData() {
            db.collection("orderList").getDocuments { (querySnapshot, error) in
                guard let querySnapshot = querySnapshot else { return }
                let orderDatas = querySnapshot.documents.compactMap { queryDocumentSnapshot in
                    try? queryDocumentSnapshot.data(as: OrderData.self)
                }
                self.orderDatas = orderDatas
                
                 DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                print(self.orderDatas)
            }
//                for document in querySnapshot.documents {
//                        print(document.data())
//
//                        self.documentId.append(document.documentID)
//                        self.orderNameList.append(document.data()["orderName"] as? String ?? "")
//                        self.drinkNameList.append(document.data()["drinkName"] as? String ?? "")
//                        self.drinkSizeList.append(document.data()["dirnkSize"] as? String ?? "")
//                        self.sugarList.append(document.data()["sugar"] as? String ?? "")
//                        self.coldList.append(document.data()["cold"] as? String ?? "")
//                        self.addList.append(document.data()["add"] as? String ?? "")
//                        self.priceList.append(document.data()["price"] as? String ?? "")
//                    }
           
    }
    

    //以下設定tableviewcell
    override func numberOfSections(in tableView: UITableView) -> Int { 1 }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { orderDatas.count }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //        let cell = tableView.dequeueReusableCell(withIdentifier: cellKey.OrderDetailTableViewCell, for: indexPath) as! OrderDetailTableViewCell
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellKey.OrderDetailTableViewCell, for: indexPath) as? OrderDetailTableViewCell else { return UITableViewCell() }
        let orderData = orderDatas[indexPath.row]
        
        cell.portraitImgView.image = UIImage(named: "00"+"\(Int.random(in: 1...8))")
        cell.portraitImgView.layer.cornerRadius = 125 / 2
        cell.orderNameLabel.text = orderData.orderName
        cell.orderNameLabel.textColor = #colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1)
        cell.drinkNameLabel.text = orderData.drinkName
        cell.drinkSizeLabel.text = orderData.drinkSize
        cell.sugarLabel.text = orderData.sugar
        cell.coldLabel.text = orderData.cold
        cell.addLabel.text = orderData.add
        cell.priceLabel.text = orderData.price
        
        return cell
    }

//    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 125 }
   
    //設定cell可swipe
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let deleteAction = UIContextualAction(style: .destructive, title: "刪除") { (action, view, completionHandler) in
            
            guard let id = self.orderDatas[indexPath.row].id else { return }
            self.db.collection("orderList").document(id).delete { error in
                if let error = error {
                    print("Error: \(error)")
                } else {
                    print("Current list has been deleted!")
                }
            }

            self.orderDatas.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            completionHandler(true)
        }
        
        let doNothingAction = UIContextualAction(style: .normal, title: "考慮") { (action, view, completionHandler) in
            completionHandler(true)
        }
        
        doNothingAction.backgroundColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
        
        UISwipeActionsConfiguration(actions: [deleteAction, doNothingAction]).performsFirstActionWithFullSwipe = true
        return UISwipeActionsConfiguration(actions: [deleteAction, doNothingAction])
    }
    
}
