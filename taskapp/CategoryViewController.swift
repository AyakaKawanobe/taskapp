//
//  CategoryViewController.swift
//  taskapp
//
//  Created by aykawano on 2020/12/11.
//  Copyright © 2020 ayaka. All rights reserved.
//

import UIKit
import RealmSwift

class CategoryViewController: UIViewController {
    
    let realm = try! Realm()
    var category: Category!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
    }
    
    @IBOutlet weak var categoryTextField: UITextField!
        
    //保存ボタンを押したときの処理
    @IBAction func saveButton(_ sender: Any) {
        print(category.categoryId)
        try! realm.write{
            self.category.categoryName = self.categoryTextField.text!
            self.realm.add(self.category, update: .modified)
        }
    }
 
    

}
