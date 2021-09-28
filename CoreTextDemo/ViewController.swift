//
//  ViewController.swift
//  CoreTextDemo
//
//  Created by 曹龙 on 2021/9/24.
//

import UIKit

class ViewController: UIViewController {
    lazy var simple: SimpleDraw = {
        let simple = SimpleDraw()
        simple.backgroundColor = .white
        return simple
    }()
    
    lazy var truncate: TruncateDraw = {
        let trun = TruncateDraw()
        trun.backgroundColor = .white
        return trun
    }()
    
    lazy var imageLabel: ImageText = {
        let img = ImageText()
        img.backgroundColor = .white
        return img
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        installViews()
        viewsLayout()
    }

    private func installViews() {
        view.addSubview(simple)
        view.addSubview(truncate)
        view.addSubview(imageLabel)
    }
    private func viewsLayout() {
        simple.frame = CGRect(x: 20, y: 60, width: 100, height: 40)
        truncate.frame = CGRect(x: 20, y: 100, width: 100, height: 40)
        imageLabel.frame = CGRect(x: 20, y: 140, width: 320, height: 280)
    }
}

