//
//  ViewController.swift
//  BezierCurve
//
//  Created by Comet on 1/31/24.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var bezier: BezierCurve!
    @IBOutlet weak var slider: UISlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let listener = UIPanGestureRecognizer(target: self, action: #selector(panGestureHandler(_:)))
        bezier.addGestureRecognizer(listener)
        self.bezier.setProgress(update: 1)
    }

    @objc func panGestureHandler(_ sender: UIPanGestureRecognizer) {
        let pt = sender.location(in: self.bezier)
        
        bezier.setSeedPoint(point: pt)
    }

    @IBAction func onAnimateTapped(_ sender: Any) {
        self.bezier.setProgress(update: 0)
        UIView.animate(withDuration: 2, delay: 0, options: .curveEaseInOut) {
            self.bezier.progress = 1
        }
    }
    
    @IBAction func onSlideChange(_ sender: Any) {
        bezier.setProgress(update: CGFloat(slider.value))
    }
    
}

