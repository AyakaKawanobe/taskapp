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

class InputViewController: UIViewController {

    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var contentsTextView: UITextView!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var categoryTextField: UITextField!
    
    let realm = try! Realm()
    var task: Task!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        //背景をタップしたらdismissKeyboardメソッドを実行
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)
        
        titleTextField.text = task.title
        contentsTextView.text = task.contents
        datePicker.date = task.date
        categoryTextField.text = task.category
    }
    
    //保存ボタンを押したときの処理
    @IBAction func saveButton(_ sender: Any) {
        try! realm.write{
            self.task.title = self.titleTextField.text!
            self.task.contents = self.contentsTextView.text
            self.task.date = self.datePicker.date
            self.task.category = self.categoryTextField.text!
            self.realm.add(self.task, update: .modified)
        }
        setNotification(task: task)
    }
    
    //    animatedは遷移の際にアニメーションをつけるか否か
    //    segueでの遷移の場合は基本trueが入っている
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
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

}
