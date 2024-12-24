//
//  WelcomeViewController.swift
//  StreamEase Play
//
//  Created by Unique Consulting Firm on 22/12/2024.
//

import UIKit

class WelcomeViewController: UIViewController {
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func startbtn(_ sender:UIButton)
    {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
               let newViewController = storyBoard.instantiateViewController(withIdentifier: "VideoListViewController") as! VideoListViewController
               newViewController.modalPresentationStyle = UIModalPresentationStyle.fullScreen
               newViewController.modalTransitionStyle = .crossDissolve
               self.present(newViewController, animated: true, completion: nil)
    }

}
