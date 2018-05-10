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
    
    private let meal_Table = "Meal"
    private let meal_ID = "ID"
    private let meal_Name = "Name"
    private let meal_Latitude = "Latitude"
    private let meal_Longitude = "Longitude"
    private let meal_Img = "Image"
    private let meal_Note = "Note"
    
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
                    
                    let createMoviesTableQuery = "CREATE TABLE \(meal_Table) ( \(meal_ID) INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, \(meal_Name) TEXT, \(meal_Longitude) TEXT, \(meal_Latitude) TEXT, \(meal_Img) BLOB,\(meal_Note) TEXT );"
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
        
        // 若有 nil 那格就存為 Null
        let null = NSNull()
        let values : [Any?] = [name , longitude , latitude , imgData , note]
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
        let query = "INSERT INTO \(meal_Table) (\(meal_Name),\(meal_Longitude),\(meal_Latitude),\(meal_Img),\(meal_Note)) VALUES (?,?,?,?,?);"
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
        
        // 若有 nil 那格就存為 Null
        let null = NSNull()
        let values : [Any?] = [name , longitude , latitude , imgData , note]
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
        let query = "UPDATE \(meal_Table) SET \(meal_Name) = ?,\(meal_Longitude) = ?,\(meal_Latitude) = ?,\(meal_Img) = ?,\(meal_Note) = ? WHERE \(meal_ID) = \(id);"
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
        let query = "SELECT * FROM \(meal_Table)"
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
        let query = "delete from \(meal_Table) where \(meal_ID)=?"
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
        let id = Int(result.int(forColumn: meal_ID))
        let name = result.string(forColumn: meal_Name)
        let latStr = result.string(forColumn: meal_Latitude)
        let lonStr = result.string(forColumn: meal_Longitude)
        let note = result.string(forColumn: meal_Note)
        let imageData = result.data(forColumn: meal_Img)
        // 將 座標轉成 Double
        let lat = self.strToDouble(str: latStr)
        let lon = self.strToDouble(str: lonStr)
        
        let data = SqlData(id: id, name: name, latitude: lat, longitude: lon, note: note, imageData: imageData)
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
