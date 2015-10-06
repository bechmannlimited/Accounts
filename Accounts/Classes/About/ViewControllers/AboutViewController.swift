//
//  AboutViewController.swift
//  Accounts
//
//  Created by Alex Bechmann on 04/10/2015.
//  Copyright © 2015 Alex Bechmann. All rights reserved.
//

import UIKit

class AboutViewController: ACBaseViewController {

    let textView: UITextView = UITextView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupTextView()
    }

    func setupTextView() {
        
        textView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textView)
        textView.fillSuperView(UIEdgeInsetsZero)
        textView.text = "By using this app your accept that we cannot be held responsible for the accuracy or reliability of the data in this app. We will do our best to maintain it and provide updates when neccessary."
    }

}
