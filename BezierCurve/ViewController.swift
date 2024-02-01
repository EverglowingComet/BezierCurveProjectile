//
//  ViewController.swift
//  BezierCurve
//
//  Created by Comet on 1/31/24.
//

import UIKit
import AVKit

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
    
    @IBAction func createVideoTapped(_ sender: Any) {
        let renderer = BezierRenderer(image: UIImage(named: "covid_19_bg")!, data: BezierCurve.data, duration: CMTime(seconds: 10, preferredTimescale: 30))
        let output = urlOfFile(name: "visualization.mp4")
        let writter = BezierWritter(outputFileURL: output, render: renderer, videoSize: BezierCurve.data.frame.size)
        writter.startRender(url: output) { url in
            DispatchQueue.main.async {
                let player = AVPlayer(url: url)
                let vc = AVPlayerViewController()
                vc.player = player
                self.present(vc, animated: true)
            }
        }
    }
    
    private func urlOfFile(name: String) -> URL {
        let output = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(name)
        if FileManager.default.fileExists(atPath: output.path) {
            try? FileManager.default.removeItem(at: output)
        }
        
        print("url of file: \(output)")
        
        return output
    }
}

