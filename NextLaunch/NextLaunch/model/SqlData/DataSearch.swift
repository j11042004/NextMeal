//
//  DataSearch.swift
//  NextLaunch
//
//  Created by Uran on 2018/5/10.
//  Copyright © 2018年 Uran. All rights reserved.
//

import UIKit

class DataSearch: NSObject {
    static let shardInstance = DataSearch()
    private let database = DBManager.shared
    /// 根據 關鍵字搜尋 SqlDataBase
    /// - Parameters:
    ///   - query: 關鍵字
    ///   - complete: 完成後可能回傳 [SqlData]? 或是 錯誤訊息
    func searchData(query:String , complete:(_ data: [SqlData]? , _ errorMessage : String?) -> Void){
        let allData = database.searchAllData()
        if query.count == 0 {
            let errorMsg = "輸入的搜尋字數為 0"
            complete(nil , errorMsg)
            return
        }
        // 看 data 中是否有包含關鍵字，若是回傳 true ，給到 datas 中
        let datas = allData.filter { (data) -> Bool in
            // 全轉成小寫，再進行比對
            let text = query.lowercased()
            guard let note = data.note?.lowercased() else{
                return false
            }
            let noteBool = note.contains(text)
            guard let name = data.name?.lowercased() else{
                return false
            }
            let nameBool = name.contains(text)
            return noteBool || nameBool
        }
        complete(datas , nil)
    }
    
    
    /// 根據 關鍵字搜尋 SqlDataBase 的 na,e
    /// - Parameters:
    ///   - query: 關鍵字
    ///   - complete: 完成後可能回傳 [SqlData]? 或是 錯誤訊息
    func searchDataName(query:String , complete:(_ data: [SqlData]? , _ errorMessage : String?) -> Void){
        let allData = database.searchAllData()
        if query.count == 0 {
            let errorMsg = "輸入的搜尋字數為 0"
            complete(nil , errorMsg)
            return
        }
        // 看 data 中是否有包含關鍵字，若是回傳 true ，給到 datas 中
        let datas = allData.filter { (data) -> Bool in
            // 全轉成小寫，再進行比對
            let text = query.lowercased()
            guard let name = data.name?.lowercased() else{
                return false
            }
            let nameBool = name.contains(text)
            return nameBool
        }
        if datas.count == 0{
            complete(nil , "未搜尋到符合的資料")
        }
        complete(datas , nil)
    }
}
