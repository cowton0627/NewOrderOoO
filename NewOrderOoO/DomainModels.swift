//
//  DomainModels.swift
//  NewOrderOoO
//
//  集中:價格 (Money)、飲料規格 enum、下單輸入 (OrderInput)、產品目錄 (ProductCatalog)。
//  目的:從散落於 view controller 的字串硬編碼往強型別搬,後續 ViewModel / Repository 共用。
//

import Foundation

// MARK: - Money

/// 用 Decimal 表示金額,避免 Double 浮點誤差。
struct Money: Equatable {
    var amount: Decimal
    var currencyCode: String

    init(amount: Decimal, currencyCode: String = "TWD") {
        self.amount = amount
        self.currencyCode = currencyCode
    }

    static let zero = Money(amount: 0)

    /// 嘗試從 "$45.00" / "TWD 45" / "45" 等格式解析。
    static func parse(_ str: String) -> Money? {
        let cleaned = str
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "TWD", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)
        guard let d = Decimal(string: cleaned) else { return nil }
        return Money(amount: d)
    }

    static func * (lhs: Money, rhs: Int) -> Money {
        Money(amount: lhs.amount * Decimal(rhs), currencyCode: lhs.currencyCode)
    }

    /// 給總額顯示用:"TWD 90"。
    func formattedISO() -> String {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "zh_TW")
        f.numberStyle = .currencyISOCode
        f.maximumFractionDigits = 0
        return f.string(from: amount as NSDecimalNumber) ?? "\(currencyCode) \(amount)"
    }

    /// 寫入 Firestore 用的字串格式,維持與舊資料相容("$45.00")。
    func storageString() -> String {
        let n = NSDecimalNumber(decimal: amount)
        let f = NumberFormatter()
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        f.usesGroupingSeparator = false
        return "$" + (f.string(from: n) ?? "0.00")
    }
}

// MARK: - 飲料規格 enum

/// 規格的共同協定,UI 自動產生 segmented control 用。
protocol DrinkOption: CaseIterable, RawRepresentable where RawValue == String {
    var displayName: String { get }
}
extension DrinkOption {
    var displayName: String { rawValue }
}

enum DrinkSize: String, DrinkOption {
    case tall = "Tall"
    case grande = "Grande"
    case venti = "Venti"
}

enum SugarLevel: String, DrinkOption {
    case full = "正常糖"
    case half = "半糖"
    case none = "無糖"
}

enum IceLevel: String, DrinkOption {
    case normal = "正常冰"
    case less = "少冰"
    case none = "去冰"
}

enum AddOn: String, DrinkOption {
    case pearl = "珍珠"
    case aiyu = "愛玉"
    case grassJelly = "仙草"
}

// MARK: - 下單輸入

/// 送往 Repository.placeOrder 的 input,跟 OrderData (從 Firestore 讀回) 區分。
struct OrderInput {
    var orderName: String
    var drinkName: String
    var size: DrinkSize
    var sugar: SugarLevel
    var ice: IceLevel
    var add: AddOn
    var unitPrice: Money
    var quantity: Int

    var totalPrice: Money { unitPrice * quantity }
}

enum OrderError: LocalizedError {
    case missingName
    case invalidPrice

    var errorDescription: String? {
        switch self {
        case .missingName: return "姓名欄不得為空"
        case .invalidPrice: return "價格格式錯誤"
        }
    }
}

// MARK: - 產品目錄

/// 暫時的產品來源(後續可改從 Firestore 拿)。把寫死資料從 view controller 拉出來。
enum ProductCatalog {
    static let all: [ProductData] = [
        ProductData(imgName: "drink001.jpg", name: "拿鐵咖啡", price: "$45.00", content: "熱鮮奶、咖啡", description: "Caffè Latte就是所謂加了牛奶的咖啡,通常直接音譯為「拿鐵咖啡」甚至「拿鐵」或「那提」。"),
        ProductData(imgName: "drink002.jpg", name: "魔幻美人魚", price: "$105.00", content: "調味咖啡", description: "混合红色火龍果和芒果醬,撒上藍莓粉和鮮奶油,最後裝飾上巧克力魚尾,繽紛粉嫩的色調肯定是2020年夏季必喝飲品。"),
        ProductData(imgName: "drink003.jpg", name: "芋頭牛奶", price: "$65.00", content: "芋頭、牛奶", description: "嚴選新鮮大甲芋頭加上二砂, 純手工翻攪熬煮及悶煮將近1小時才能起鍋。"),
        ProductData(imgName: "drink004.jpg", name: "阿華田", price: "$55.00", content: "偽裝美祿", description: "包括51.6%糖(每30g含15.5克糖)、麥芽精華及乳清,後期加入可可粉。"),
        ProductData(imgName: "drink005.jpg", name: "四季春", price: "$55.00", content: "四季春茶葉", description: "香氣十足卻因茶湯苦澀, 以致價格低廉且多僅做罐裝茶飲及手搖茶原料。"),
        ProductData(imgName: "drink006.jpg", name: "文山包種", price: "$75.00", content: "文山包種茶葉", description: "色澤翠綠,水色蜜綠鮮豔帶黃金,香氣清香幽雅似花香,滋味甘醇滑潤帶活,香氣越濃郁品質越高級。"),
        ProductData(imgName: "drink007.jpg", name: "珍珠奶茶", price: "$55.00", content: "奶茶、大顆粉圓", description: "有兩家臺灣茶飲業者宣稱自己是發明者,一是源自臺中的春水堂,另一是源自臺南的翰林茶館。"),
        ProductData(imgName: "drink008.jpg", name: "墨汁", price: "$66.00", content: "煤煙、松煙、明膠", description: " 透過硯用水研磨可以產生用於毛筆書寫的墨汁,在水中以膠體的溶液存在。"),
        ProductData(imgName: "drink009.jpg", name: "檸檬汁", price: "$87.00", content: "維生素C、鉀、葉酸", description: "每100g,含蛋白質1g、脂肪0.3g、碳水化合物6.9g、纖維2.1g,提供121.4KJ熱量。"),
        ProductData(imgName: "drink010.jpg", name: "養樂多", price: "$15.00", content: "水、各種化學物質", description: "市面上充斥各種冒牌貨,內容物並無乳酸菌,不幫助消化,其實本家的也差不多啦!"),
        ProductData(imgName: "drink011.jpg", name: "桂圓茶", price: "$44.00", content: "水、桂圓", description: "用比桂圓重的水泡出來的桂圓茶,而且紅棗用完了所以半價,不建議女性直飲,燥熱。"),
        ProductData(imgName: "drink012.jpg", name: "薑母茶", price: "$88.00", content: "熱水、薑母片", description: "據說對禦寒有功效,如果喝完還是覺得冷,那是你體質差。"),
    ]
}
