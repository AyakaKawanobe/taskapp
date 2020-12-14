//
//  ViewController.swift
//  taskapp
//
//  Created by aykawano on 2020/12/07.
//  Copyright © 2020 ayaka. All rights reserved.
//

import UIKit
import RealmSwift

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UIPickerViewDelegate, UIPickerViewDataSource{

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var categoryTextField: UITextField!
    
    //Realmのインスタンスを取得
    //try!でtry-catchと省略できる
    let realm = try! Realm()
    
    //カテゴリPicerView処理
    var pickerView = UIPickerView()
    var categoryArray = try!Realm().objects(Category.self)
    
    //DB内のタスクが格納されているリスト
    //日付の近い順でソート：昇順
    //以降内容をアップデートするとリスト内は自動的に更新される
    //クラスを値として渡すときは.selfをつける
    var taskArray = try!Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true )
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        
        //ピッカー設定
        pickerView.delegate = self
        pickerView.dataSource = self
        
        //決定バーの生成
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 35))
        //let editItem = UIBarButtonItem(title: "Edit", style: .done, target: self, action: #selector(edit))
        let spaceItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        toolbar.setItems([spaceItem, doneItem], animated: true)
        
        //インプットビュー設定
        categoryTextField.inputView = pickerView
        categoryTextField.inputAccessoryView = toolbar
    }

    //データの数(=セルの数)を返すメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return taskArray.count
    }
    
    //各セルの内容を返すメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //再利用可能なcellを得る
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        //cellに値を設定する
        let task = taskArray[indexPath.row]
        
        cell.textLabel?.text = task.title
        
        let formatter = DateFormatter()
        //formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "yyyy-MM-dd HH:mm", options: 0, locale: Locale(identifier: "ja_JP"))
        let dateString:String = formatter.string(from: task.date)
        cell.detailTextLabel?.text = dateString
          
        //現在日付取得
        let now = Date()
        let nowDatetime = formatter.string(from: now)
        //タスク実行日時の１日前
        let modifiedDate = Calendar.current.date(byAdding: .day, value: -1, to: task.date)!
        let modifiedDateString = formatter.string(from: modifiedDate)
        
        //タスク実行１日前〜タスク実行日時のセルの背景色を変える
        if modifiedDateString <= nowDatetime && nowDatetime <= dateString{
            cell.backgroundColor = #colorLiteral(red: 0.6257948279, green: 0.9187778234, blue: 0.8746688962, alpha: 1)
        }
        
        return cell

    }
    
    //各セルを選択した時に実行されるメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "cellSegue", sender: nil)
    }
    
    //segueで画面遷移するときに呼ばれる
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let inputViewController: InputViewController = segue.destination as! InputViewController
        
        //セルを選択したときの処理
        if segue.identifier == "cellSegue"{
            let indexPath = self.tableView.indexPathForSelectedRow
            inputViewController.task = taskArray[indexPath!.row]
            inputViewController.category = categoryArray[indexPath!.row]
        }else{
            //+ボタンを押下したときの処理
            let task =  Task()
            let category = Category()
            let allTasks = realm.objects(Task.self)
            if allTasks.count != 0{
                task.id = allTasks.max(ofProperty: "id")! + 1
            }
            inputViewController.task = task
            inputViewController.category = category
        }
    }
    
    //入力画面から戻ってきた時にTableViewを更新させる
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    //セルの削除が可能なことを伝えるメソッド
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    //Deleteボタンが押された時に実行されるメソッド
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete{
            //削除するタスクを取得する
            let task = self.taskArray[indexPath.row]
            
            //ローカル通知をキャンセルする
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [String(task.id)])
            
            //データベースから削除する
            try! realm.write{
                self.realm.delete(task)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            
            //未通知のローカル通知一覧をログ出力
            center.getPendingNotificationRequests{(requests: [UNNotificationRequest]) in
                for request in requests{
                    print("/------------")
                    print(request)
                    print("------------/")
                }
            }
        }
    }
    
    //検索ボタン押下時の呼び出しメソッド
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if searchBar.text == ""{
            taskArray = try!Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true )
        }else{
//            //categoryに合致
//            let predicate = NSPredicate(format: category == %@", searchBar.text!)
            //タイトル、内容、カテゴリ部分一致検索
            let predicate = NSPredicate(format: "title CONTAINS %@ OR contents CONTAINS %@", searchBar.text!, searchBar.text!)
            taskArray = realm.objects(Task.self).sorted(byKeyPath: "date", ascending: true ).filter(predicate)
            print(taskArray)
        }

        //テーブルを再読み込みする。
        tableView.reloadData()
    }
    
    //カテゴリ絞り込み
    //ドラムロールの列数
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // ドラムロールの行数
     func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        print(categoryArray)
         return categoryArray.count
     }
    
    // ドラムロールの各タイトル
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let category = categoryArray[row]
        return category.categoryName
    }
    
    //選択したカテゴリをtextFieldに入力
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let category = categoryArray[row]
        categoryTextField.text = category.categoryName
        print(category)
//        let categoryPredicate = NSPredicate(format: "categoryName == %@", category.categoryName)
//        categoryArray = realm.objects(Category.self).filter(categoryPredicate)
        let taskPredicate = NSPredicate(format: "category == %@", category)
        taskArray = realm.objects(Task.self).sorted(byKeyPath: "date", ascending: true ).filter(taskPredicate)
        print(taskArray)
        //テーブルを再読み込みする。
        tableView.reloadData()
    }
    
    //Doneボタンが押されたら該当カテゴリでセルを絞り込み
    @objc func done() {
        view.endEditing(true)
//        let categoryPredicate = NSPredicate(format: "categoryName == %@", categoryTextField.text!)
//        categoryArray = realm.objects(Category.self).filter(categoryPredicate)
//        let taskPredicate = NSPredicate(format: "category == %@", categoryArray)
//        taskArray = realm.objects(Task.self).sorted(byKeyPath: "date", ascending: true ).filter(taskPredicate)
//        //テーブルを再読み込みする。
//        tableView.reloadData()
    }
    
}

