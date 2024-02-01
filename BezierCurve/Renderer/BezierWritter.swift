//
//  BezierWritter.swift
//  BezierCurve
//
//  Created by Comet on 2/2/24.
//

import Foundation
import AVKit

final class BezierWritter {
    
    let glContext : EAGLContext
    let ciContext : CIContext
    let writer : AVAssetWriter
    
    class func setupWriter(outputFileURL: URL) -> AVAssetWriter {
        let fileManager = FileManager.default
        
        let outputFileExists = fileManager.fileExists(atPath: outputFileURL.path)
        if outputFileExists {
            try? fileManager.removeItem(at: outputFileURL)
        }
        
        var error : NSError?
        let writer = try! AVAssetWriter(outputURL: outputFileURL, fileType: AVFileType.mp4)
        assert(error == nil, "init video writer should not failed: \(error)")
        
        return writer
    }
    
    let videoSize: CGSize
    
    var videoWidth : CGFloat {
        return videoSize.width
    }
    
    var videoHeight : CGFloat {
        return videoSize.height
    }
    
    var videoOutputSettings : [String: Any] {
        return [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 1000000],
            AVVideoWidthKey: videoWidth,
            AVVideoHeightKey: videoHeight
        ]
    }
    
    var sourcePixelBufferAttributes: [String: Any] {
        return [
            String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_32BGRA,
            String(kCVPixelBufferWidthKey): videoWidth,
            String(kCVPixelBufferHeightKey): videoHeight
        ]
    }
    
    var videoInput: AVAssetWriterInput!
    var writerInputAdapater: AVAssetWriterInputPixelBufferAdaptor!
    
    let render: BezierRenderer
    
    // create an YMVideoWriter will remove the file specified at outputFileURL if the file exists
    init(outputFileURL: URL, render: BezierRenderer, videoSize: CGSize = CGSize(width: 640.0, height: 640.0)) {
        
        self.render = render
        self.videoSize = videoSize
        
        glContext = EAGLContext(api: .openGLES2)!
        ciContext = CIContext(eaglContext: glContext)
        writer = BezierWritter.setupWriter(outputFileURL: outputFileURL)
        
        videoInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoOutputSettings)
        writer.add(videoInput)
        
        writerInputAdapater = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInput, sourcePixelBufferAttributes: sourcePixelBufferAttributes)
        
        writer.startWriting()
        writer.startSession(atSourceTime: CMTime.zero)
        
    }
    
    
    private func finishWriting(completion: @escaping () -> ()) {
        videoInput.markAsFinished()
        writer.endSession(atSourceTime: lastTime)
        writer.finishWriting(completionHandler: completion)
    }
    
    private var lastTime: CMTime = CMTime.zero
    
    //private var inputQueue = dispatch_queue_create("writequeue.kaipai.tv", DISPATCH_QUEUE_SERIAL)
    
    // write image in CIContext, may failed if no available space
    private func write(buffer: CVPixelBuffer, withPresentationTime time: CMTime) {
        lastTime = time
        
        print("write image at time \(CMTimeGetSeconds(time))")
        
        writerInputAdapater.append(buffer, withPresentationTime: time)
    }
    
    func startRender(url : URL, success: @escaping ((URL)->())) {
        
        videoInput.requestMediaDataWhenReady(on: DispatchQueue.main, using: { [self]() -> Void in
            
            while self.videoInput.isReadyForMoreMediaData {
                
                if let (frame, time) =  self.render.next() {
                    self.write(buffer: frame, withPresentationTime: time)
                } else {
                    self.finishWriting(completion: { () -> () in
                        print("finish writing")
                        success(url)
                    })
                    break
                }
                
            }
            
        })
        
    }
    
}
