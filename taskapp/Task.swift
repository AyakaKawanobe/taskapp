//
//  Task.swift
//  taskapp
//
//  Created by aykawano on 2020/12/08.
//  Copyright © 2020 ayaka. All rights reserved.
//

import RealmSwift

class Task: Object{
    //管理用ID。プライマリーキー
    @objc dynamic var id = 0
    
    //タイトル
    @objc dynamic var title = ""
    
    //内容
    @objc dynamic var contents = ""
    
    //日時
    @objc dynamic var date = Date()
    
    //カテゴリ
    @objc dynamic var category = ""
    
    //idをプライマリーキーとして設定
    override static func primaryKey() -> String?{
        return "id"
    }
}

class Category: Object{

    //カテゴリID。
    @objc dynamic var categoryId = 0
    
    //カテゴリ名
    @objc dynamic var categoryName = ""
    
    //idをプライマリーキーとして設定
    override static func primaryKey() -> String?{
        return "categoryId"
    }
}
