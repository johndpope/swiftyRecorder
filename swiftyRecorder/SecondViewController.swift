//
//  SecondViewController.swift
//  swiftyRecorder
//
//  Created by Patrik Jonell on 2018-01-17.
//  Copyright © 2018 Patrik Jonell. All rights reserved.
//

import Foundation
import UIKit

class SecondViewController: UIViewController {
    @IBOutlet weak var url_to_post_to: UITextField!
    
    @IBAction func send_data_over_http(_ sender: Any) {
        
//        do {
//        let context      = try SwiftyZeroMQ.Context()
//        let requestor    = try context.socket(.request)
//        try requestor.connect("tcp://" + self.url_to_post_to.text! + ":5012")
//
//        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("votes.txt")
//
//        let fileHandle2 = FileHandle(forReadingAtPath: fileURL!.path)
//
//        try requestor.send(data: fileHandle2!.readDataToEndOfFile())
//        let new_data = try requestor.recv()
//
//            if new_data != "thanks!"{
//
//                print("big problem")
//            }
//
//        } catch {
//            print(error)
//        }
        
    }
    
    @IBAction func go_button(_ sender: Any) {
        
  
            let myVC = storyboard?.instantiateViewController(withIdentifier:"ViewController") as! ViewController

            present(myVC, animated: true)
        
    }
    

    override func viewDidLoad() {
        
        super.viewDidLoad()
    }


}
