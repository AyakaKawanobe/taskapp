//
//  CategoryViewController.swift
//  taskapp
//
//  Created by aykawano on 2020/12/11.
//  Copyright © 2020 ayaka. All rights reserved.
//

import UIKit
import RealmSwift

class CategoryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
    
    let realm = try! Realm()
    var category: Category!
    let categoryArray = try!Realm().objects(Category.self)
    let taskArray = try!Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true )
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var categoryTextField: UITextField!
        
    override func viewDidLoad() {
           super.viewDidLoad()

           tableView.delegate = self
           tableView.dataSource = self
           
       }
    
    //保存ボタンを押したときの処理
    @IBAction func saveButton(_ sender: Any) {
        print(category.categoryId)
        try! realm.write{
            self.category.categoryName = self.categoryTextField.text!
            self.realm.add(self.category, update: .modified)
        }
    }
    
    //データの数(=セルの数)を返すメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categoryArray.count
    }
 
    //各セルの内容を返すメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //再利用可能なcellを得る
        let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath)
        
        //cellに値を設定する
        let category = categoryArray[indexPath.row]
        cell.textLabel?.text = category.categoryName
    
        return cell
    }
    
    //セルの削除が可能なことを伝えるメソッド
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    //deleteボタン文言変更
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "削除"
    }
    
    //Deleteボタンが押された時に実行されるメソッド
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete{
            //削除するタスクを取得する
            let category = self.categoryArray[indexPath.row]
            
            //データベースから削除する
            try! realm.write{
                self.realm.delete(category)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }
    }
    
}
