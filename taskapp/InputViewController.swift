//
//  InputViewController.swift
//  taskapp
//
//  Created by aykawano on 2020/12/07.
//  Copyright © 2020 ayaka. All rights reserved.
//

import UIKit
import RealmSwift
import UserNotifications

class InputViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var contentsTextView: UITextView!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var categoryTextField: UITextField!
    
    let realm = try! Realm()
    var task: Task!
    
    //カテゴリPicerView処理
    var pickerView = UIPickerView()
    var categoryArray = try!Realm().objects(Category.self)
    var category: Category!
    
    var categoryRow = 0
    var taskRow = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //背景をタップしたらdismissKeyboardメソッドを実行
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)
        
        //ピッカー設定
        pickerView.delegate = self
        pickerView.dataSource = self
        
        //決定バーの生成
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 35))
        let spaceItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let doneItem = UIBarButtonItem(title: "選択", style: .done, target: self, action: #selector(done))
        toolbar.setItems([spaceItem, doneItem], animated: true)
        
        //インプットビュー設定
        categoryTextField.inputView = pickerView
        categoryTextField.inputAccessoryView = toolbar

        //枠線指定
        contentsTextView.layer.borderColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        contentsTextView.layer.borderWidth = 1.0
        contentsTextView.layer.cornerRadius = 8.0
        
        //Backボタン文言変更
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "戻る", style: .plain, target: nil, action: nil)
        
        titleTextField.text = task.title
        contentsTextView.text = task.contents
        datePicker.date = task.date
        categoryTextField.text = task.category?.categoryName
    }
    
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
        print(categoryArray[row])
        return category.categoryName
    }
    
    //選択したカテゴリをtextFieldに入力
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        categoryRow = row
        let category = categoryArray[row]
        print(category.categoryName)
        categoryTextField.text = category.categoryName
        
    }
    
    //Doneボタンが押されたらPickerViewを閉じる
    @objc func done() {
        view.endEditing(true)
    }
    
    //保存ボタンを押したときの処理
    @IBAction func saveButton(_ sender: Any) {
        try! realm.write{
            self.task.title = self.titleTextField.text!
            self.task.contents = self.contentsTextView.text
            self.task.date = self.datePicker.date
            //self.category.categoryName = self.categoryTextField.text!
            self.task.category = self.categoryArray[categoryRow]
            self.realm.add(self.task, update: .modified)
        }
        setNotification(task: task)
        
        //一つ前の画面にも戻る
        self.navigationController?.popViewController(animated: true)
    }
    
    
//    //    animatedは遷移の際にアニメーションをつけるか否か
//    //    segueでの遷移の場合は基本trueが入っている
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//    }
    
    //カテゴリ編集/追加ボタンを押下
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let categoryViewController: CategoryViewController = segue.destination as! CategoryViewController
        let category = Category()
        let allCategory = realm.objects(Category.self)
        if allCategory.count != 0{
            category.categoryId = allCategory.max(ofProperty: "categoryId")! + 1
        }
        categoryViewController.category = category
    }
    
    //タスク通知を登録する
    func setNotification(task: Task){
        //通知内容のコンポーネント
        let content = UNMutableNotificationContent()
        //タイトルと内容を設定（中身がない場合はメッセージなしで音だけの通知になるので「（xxなし）」を表示する）
        if task.title == "" {
            content.title = "(タイトルなし)"
        }else{
            content.title = task.title
        }
        
        if task.contents == "" {
            content.body = "(内容なし)"
        }else{
            content.body = task.contents
        }
        
        content.sound = UNNotificationSound.default
        
        
        //ローカル通知が発動するtrigger(日付マッチ)を設定
        let calender = Calendar.current
        let dateComponents = calender.dateComponents([.year, .month, .day, .hour, .minute], from: task.date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        //identifier,content,triggerからローカル通知を作成（identifierが同じだとローカル通知を上書き保存）
        let request = UNNotificationRequest(identifier: String(task.id), content: content, trigger: trigger)
        
        //通知関連の機能を管理
        let center = UNUserNotificationCenter.current()
        //ローカル通知を登録
        center.add(request) {(error) in
            //errorがnilなら登録に成功したと表示する。errorが存在すればエラーを表示
            print(error ?? "ローカル通知登録　OK")
        }
        
        //未通知のローカル通知一覧をログで出力
        center.getPendingNotificationRequests{(requests: [UNNotificationRequest]) in
            for request in requests {
                print("/-------------")
                print(request)
                print("-------------/")
            }
        }
    }
    
    
    @objc func dismissKeyboard(){
        //キーボードを閉じる
        view.endEditing(true)
    }

    @IBAction func unwind(_ segue: UIStoryboardSegue) {
        
    }
}
