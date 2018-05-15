//
//  DBManager.swift
//  HelloSwiftARKit
//
//  Created by Uran on 2018/3/9.
//  Copyright © 2018年 Uran. All rights reserved.
//

import UIKit
class DBManager: NSObject {
    static let shared : DBManager = DBManager()
    
    private let MealTable = "Meal"
    private let MealID = "ID"
    private let MealName = "Name"
    private let MealLatitude = "Latitude"
    private let MealLongitude = "Longitude"
    private let MealImg = "Image"
    private let MealNote = "Note"
    private let MealAddress = "Address"
    private let MealRating = "Rating"
    
    private var databasePath : String!
    private let databaseFileName = "Meal.sqlite"
    private var database : FMDatabase!
    
    override init() {
        super.init()
        let documentsDirectory = NSHomeDirectory() + "/Documents"
        databasePath = documentsDirectory.appending("/\(databaseFileName)")
        NSLog("database path : \(databasePath)")
    }
    
    
    /// 建立 Database
    ///
    /// - Returns: 回傳是否建立成功
    func createDatabase() -> Bool {
        var created = false
        // 若 FileManager 還未拿到檔案
        if !FileManager.default.fileExists(atPath: self.databasePath) {
            // 設定 Database
            database = FMDatabase(path: self.databasePath!)
            // 若 Database 不是 Nil
            if database != nil {
                // Open the database. 這時 Database會被建立
                if database.open() {
                    // 執行建立 Table 的 Query
                    let createMoviesTableQuery = "CREATE TABLE \(MealTable) ( \(MealID) INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, \(MealName) TEXT, \(MealLongitude) TEXT, \(MealLatitude) TEXT, \(MealImg) BLOB,\(MealNote) TEXT,\(MealAddress) TEXT,\(MealRating) DOUBLE );"
                    do {
                        // 嘗試執行 Database
                        try database.executeUpdate(createMoviesTableQuery, values: nil)
                        created = true
                    }
                    catch {
                        print("Could not create table.")
                        print(error.localizedDescription)
                    }
                    // 關閉 Database
                    database.close()
                }
                else {
                    print("Could not open the database.")
                }
            }
        }
        return created
    }
    /// 開啟 Database
    func openDatabase() -> Bool{
        if self.database == nil {
            if FileManager.default.fileExists(atPath: databasePath){
                self.database = FMDatabase(path: databasePath)
            }
        }
        if database != nil{
            if database.open(){
                return true
            }
        }
        return false
    }
    /// 新增 到 Database 中
    ///
    /// - Parameter data: 要被新增的 Data，其中的屬性：
    ///   - name: 店名
    ///   - longitude: 經度
    ///   - latitude: 緯度
    ///   - imageData: 圖片 Data
    ///   - note: 備註
    /// - Returns: 回傳是否成功
    func insertData(_ data : SqlData) -> Bool{
        var success = false
        if !self.openDatabase() {
            return false
        }
        let name = data.name
        let longitude = data.longitude
        let latitude = data.latitude
        let imgData = data.imageData
        let note = data.note
        let address = data.address
        let rating = data.rating
        // 若有 nil 那格就存為 Null
        let null = NSNull()
        let values : [Any?] = [name , longitude , latitude , imgData , note , address , rating]
        // 準備要加入的值
        var valueArray = [Any]()
        // 若是 Nil 就替換成 NSNull
        for value in values {
            if let value = value {
                valueArray.append(value)
            }else{
                valueArray.append(null)
            }
        }
        // 準備 Query
        let query = "INSERT INTO \(MealTable) (\(MealName),\(MealLongitude),\(MealLatitude),\(MealImg),\(MealNote),\(MealAddress),\(MealRating)) VALUES (?,?,?,?,?,?,?);"
        // 執行 Sql 並把值帶入
        do {
            try database.executeUpdate(query, values: valueArray)
            success = true
        } catch  {
            NSLog("saveError : \(error.localizedDescription)")
        }
        self.database.close()
        return success
    }
    
    /// 更新資料庫的 Data
    ///
    /// - Parameter data: SqlData
    /// - Returns: 是否更新成功
    func updateData(_ data:SqlData) -> Bool{
        var success = false
        if !self.openDatabase() {
            return success
        }
        let id = data.id!
        let name = data.name
        let longitude = data.longitude
        let latitude = data.latitude
        let imgData = data.imageData
        let note = data.note
        let address = data.address
        let rating = data.rating
        // 若有 nil 那格就存為 Null
        let null = NSNull()
        let values : [Any?] = [name , longitude , latitude , imgData , note , address , rating]
        // 準備要加入的值
        var valueArray = [Any]()
        // 若是 Nil 就替換成 NSNull
        for value in values {
            if let value = value {
                valueArray.append(value)
            }else{
                valueArray.append(null)
            }
        }
        // 準備 Query
        let query = "UPDATE \(MealTable) SET \(MealName) = ?,\(MealLongitude) = ?,\(MealLatitude) = ?,\(MealImg) = ?,\(MealNote) = ? ,\(MealAddress) = ? ,\(MealRating) = ? WHERE \(MealID) = \(id);"
        // 執行 Sql 並把值帶入
        do {
            try database.executeUpdate(query, values: valueArray)
            success = true
        } catch  {
            NSLog("saveError : \(error.localizedDescription)")
        }
        self.database.close()
        return success
    }
    /// 取得 Sql Data 中所有的資料
    func searchAllData() -> [SqlData]{
        var dataArray = [SqlData]()
        if !openDatabase() {
            return dataArray
        }
        let query = "SELECT * FROM \(MealTable)"
        do {
            let results = try self.database.executeQuery(query, values: nil)
//            dataArray.append(self.loadInformation(results))
            // 若有下一筆 就繼續取的 Data並新增
            while results.next() {
                dataArray.append(self.loadInformation(results))
            }
        } catch {
            print("search error : \(error.localizedDescription)")
        }
        self.database.close()
        
        
        return dataArray
    }
    
    /// 根據 ID 刪除資料
    ///
    /// - Parameter ID: 要被刪除的 ID
    /// - Returns: 是否有刪除成功
    func deleteData(withID id:Int) -> Bool{
        var delete = false
        if !self.openDatabase(){
            return delete
        }
        let query = "delete from \(MealTable) where \(MealID)=?"
        do {
            try database.executeUpdate(query, values: [id])
            delete = true
        } catch  {
            NSLog("delete Error : \(error.localizedDescription)")
        }
        return delete
    }
    
    /// 將 Data 內的資料轉換
    ///
    /// - Parameter result: 被取得的 Result
    /// - Returns: 轉換完的 DataArray
    private func loadInformation(_ result : FMResultSet) -> SqlData{
        let id = Int(result.int(forColumn: MealID))
        let name = result.string(forColumn: MealName)
        let latStr = result.string(forColumn: MealLatitude)
        let lonStr = result.string(forColumn: MealLongitude)
        let address = result.string(forColumn: MealAddress)
        let rating = result.double(forColumn: MealRating)
        let note = result.string(forColumn: MealNote)
        let imageData = result.data(forColumn: MealImg)
        // 將 座標轉成 Double
        let lat = self.strToDouble(str: latStr)
        let lon = self.strToDouble(str: lonStr)
        
        let data = SqlData(id: id, name: name, latitude: lat, longitude: lon, note: note, address: address, rating: rating, imageData: imageData)
        return data
    }
    private func strToDouble(str:String?) -> Double?{
        guard let intStr = str else {
            return nil
        }
        let doubleValue = Double(intStr)
        return doubleValue
    }
}
