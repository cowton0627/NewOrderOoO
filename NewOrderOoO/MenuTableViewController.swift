//
//  MenuTableViewController.swift
//  NewOrderOoO
//
//  Created by 鄭淳澧 on 2021/8/15.
//

import UIKit
import Firebase
import FirebaseFirestoreSwift

class MenuTableViewCell: UITableViewCell {
    @IBOutlet weak var pdImgView: UIImageView!
    @IBOutlet weak var pdNameLabel: UILabel!
    @IBOutlet weak var pdPriceLabel: UILabel!
    @IBOutlet weak var pdContentLabel: UILabel!
    @IBOutlet weak var pdDescriptionLabel: UILabel!
    
}

class MenuTableViewController: UITableViewController {
    let contents = [
        
        ProductData(imgName: "drink001.jpg", name: "拿鐵咖啡", price: "$45.00", content: "熱鮮奶、咖啡", description: "Caffè Latte就是所謂加了牛奶的咖啡，通常直接音譯為「拿鐵咖啡」甚至「拿鐵」或「那提」。"),
        ProductData(imgName: "drink002.jpg", name: "魔幻美人魚", price: "$105.00", content: "調味咖啡", description: "混合红色火龍果和芒果醬，撒上藍莓粉和鮮奶油，最後裝飾上巧克力魚尾，繽紛粉嫩的色調肯定是2020年夏季必喝飲品。"),
        ProductData(imgName: "drink003.jpg", name: "芋頭牛奶", price: "$65.00", content: "芋頭、牛奶", description: "嚴選新鮮大甲芋頭加上二砂， 純手工翻攪熬煮及悶煮將近1小時才能起鍋。"),
        ProductData(imgName: "drink004.jpg", name: "阿華田", price: "$55.00", content: "偽裝美祿", description: "包括51.6%糖（每30g含15.5克糖）、麥芽精華及乳清，後期加入可可粉。"),
        ProductData(imgName: "drink005.jpg", name: "四季春", price: "$55.00", content: "四季春茶葉", description: "香氣十足卻因茶湯苦澀， 以致價格低廉且多僅做罐裝茶飲及手搖茶原料。"),
        ProductData(imgName: "drink006.jpg", name: "文山包種", price: "$75.00", content: "文山包種茶葉", description: "色澤翠綠，水色蜜綠鮮豔帶黃金，香氣清香幽雅似花香，滋味甘醇滑潤帶活，香氣越濃郁品質越高級。"),
        ProductData(imgName: "drink007.jpg", name: "珍珠奶茶", price: "$55.00", content: "奶茶、大顆粉圓", description: "有兩家臺灣茶飲業者宣稱自己是發明者，一是源自臺中的春水堂，另一是源自臺南的翰林茶館。"),
        ProductData(imgName: "drink008.jpg", name: "墨汁", price: "$66.00", content: "煤煙、松煙、明膠", description: " 透過硯用水研磨可以產生用於毛筆書寫的墨汁，在水中以膠體的溶液存在。"),
        ProductData(imgName: "drink009.jpg", name: "檸檬汁", price: "$87.00", content: "維生素C、鉀、葉酸", description: "每100g，含蛋白質1g、脂肪0.3g、碳水化合物6.9g、纖維2.1g，提供121.4KJ熱量。"),
        ProductData(imgName: "drink010.jpg", name: "養樂多", price: "$15.00", content: "水、各種化學物質", description: "市面上充斥各種冒牌貨，內容物並無乳酸菌，不幫助消化，其實本家的也差不多啦！"),
        ProductData(imgName: "drink011.jpg", name: "桂圓茶", price: "$44.00", content: "水、桂圓", description: "用比桂圓重的水泡出來的桂圓茶，而且紅棗用完了所以半價，不建議女性直飲，燥熱。"),
        ProductData(imgName: "drink012.jpg", name: "薑母茶", price: "$88.00", content: "熱水、薑母片", description: "據說對禦寒有功效，如果喝完還是覺得冷，那是你體質差。"),
        
    ]
    
    struct cellKey {
        static let MenuTableViewCell = "MenuTableViewCell"
    }
        
//    var bd: Firestore!
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        bd = Firestore.firestore()
        
    }

    @IBSegueAction func dataPassed(_ coder: NSCoder) -> MenuDetailTableViewController? {
        guard let row = tableView.indexPathForSelectedRow?.row else { return nil }
//        let productData = cellContents[row]
//        return MenuDetailTableViewController(coder, productData: productData, bd)
        
        let controller = MenuDetailTableViewController(coder: coder)
        controller?.productData = contents[row]
        return controller
    }
    
    
    
    //以下設定tableviewcell
    override func numberOfSections(in tableView: UITableView) -> Int { 1 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { contents.count }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellKey.MenuTableViewCell, for: indexPath) as? MenuTableViewCell else { return UITableViewCell() }
        let cellRow = contents[indexPath.row]
        print(cellRow.name)
        cell.pdImgView.image = UIImage(named: cellRow.imgName)
        cell.pdNameLabel.text = cellRow.name
        cell.pdPriceLabel.text = cellRow.price
        cell.pdPriceLabel.textColor = #colorLiteral(red: 1, green: 0.7408380418, blue: 0, alpha: 1)
        cell.pdContentLabel.text = cellRow.content
        cell.pdDescriptionLabel.text = cellRow.description
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 125 }
    

}


