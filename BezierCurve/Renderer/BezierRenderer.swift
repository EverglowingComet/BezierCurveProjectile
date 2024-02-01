//
//  BezierRenderer.swift
//  BezierCurve
//
//  Created by Comet on 2/1/24.
//

import Foundation
import AVKit
import MetalKit

public class BezierRenderer {
    var duration: CMTime
    var data: BezierData
    
    var presentationTime : CMTime = CMTime.zero
    var frameCount = 0
    var frameRate : Float
    
    var pixelBuffer: CVPixelBuffer?
    
    var textureCache: CVMetalTextureCache?
    var commandQueue: MTLCommandQueue!
    var computePipelineState: MTLComputePipelineState!
    var bgBuffer: CVPixelBuffer? = nil
    var bgImage: UIImage
    
    init(image: UIImage, data: BezierData, duration: CMTime) {
        bgImage = image
        self.data = data
        frameRate = 1 / 30
        self.duration = duration
        
        let metalDevice = MTLCreateSystemDefaultDevice()!
        
        // Initialize the cache to convert the pixel buffer into a Metal texture.
        var textCache: CVMetalTextureCache?
        if CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, metalDevice, nil, &textCache) != kCVReturnSuccess {
            fatalError("Unable to allocate texture cache.")
        }
        else {
            textureCache = textCache
        }
        
        // Create a command queue.
        commandQueue = metalDevice.makeCommandQueue()!
        
        // Create the metal library containing the shaders
        let bundle = Bundle.main
        let url = bundle.url(forResource: "default", withExtension: "metallib")
        let library = try! metalDevice.makeLibrary(filepath: url!.path)
        
        // Create a function with a specific name.
        let function = library.makeFunction(name: "bezierCompute")!
        
        // Create a compute pipeline with the above function.
        computePipelineState = try! metalDevice.makeComputePipelineState(function: function)
    }
    
    public func initFunction() {
        
    }
    
    public func nextBg() -> CVPixelBuffer? {
        return bgImage.cgImage?.pixelBuffer(width: Int(data.frame.width), height: Int(data.frame.height), orientation: .up)
    }
    
    func next() -> (CVPixelBuffer, CMTime)? {
        
        if presentationTime.seconds < duration.seconds, let frame = nextBg() {
            
            presentationTime = CMTimeMake(value: Int64(frameCount), timescale: 30)
            
            if let targetTexture = render(pixelBuffer: frame, time: presentationTime) {
                var outPixelbuffer: CVPixelBuffer?
                if let datas = targetTexture.buffer?.contents() {
                    CVPixelBufferCreateWithBytes(kCFAllocatorDefault, targetTexture.width,
                                                 targetTexture.height, kCVPixelFormatType_64RGBAHalf, datas,
                                                 targetTexture.bufferBytesPerRow, nil, nil, nil, &outPixelbuffer);
                    if outPixelbuffer != nil {
                        frameCount += 1
                        
                        return (outPixelbuffer!, presentationTime)
                    }
                    
                }
            }
            
            
            print("comet")
            frameCount += 1
            
            return (frame, presentationTime)
        }
        
        return nil
        
    }
    
    public func render(pixelBuffer: CVPixelBuffer, time: CMTime) -> MTLTexture? {
        // here the metal code
        // Check if the pixel buffer exists
        
        // Get width and height for the pixel buffer
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        // Converts the pixel buffer in a Metal texture.
        var cvTextureOut: CVMetalTexture?
        
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.textureCache!, pixelBuffer, nil, .bgra8Unorm, width, height, 0, &cvTextureOut)
        guard let cvTexture = cvTextureOut, let inputTexture = CVMetalTextureGetTexture(cvTexture) else {
            print("Failed to create metal texture")
            return nil
        }
        
        var cvTextureOut2: CVMetalTexture?
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.textureCache!, pixelBuffer, nil, .bgra8Unorm, width, height, 0, &cvTextureOut2)
        guard let cvTexture2 = cvTextureOut2 , let outputTexture = CVMetalTextureGetTexture(cvTexture2) else {
            print("Failed to create metal texture")
            return nil
        }
        
        // Check if Core Animation provided a drawable.
        
        // Create a command buffer
        let commandBuffer = commandQueue.makeCommandBuffer()
        
        // Create a compute command encoder.
        let computeCommandEncoder = commandBuffer!.makeComputeCommandEncoder()
        
        // Set the compute pipeline state for the command encoder.
        computeCommandEncoder!.setComputePipelineState(computePipelineState)
        
        // Set the input and output textures for the compute shader.
        computeCommandEncoder!.setTexture(inputTexture, index: 0)
        computeCommandEncoder!.setTexture(outputTexture, index: 1)
        
        let threadGroupCount = MTLSizeMake(8, 8, 1)
        
        let threadGroups: MTLSize = {
            MTLSizeMake(Int(width) / threadGroupCount.width, Int(height) / threadGroupCount.height, 1)
        }()
        // Convert the time in a metal buffer.
        let progress: CGFloat = CGFloat(presentationTime.seconds) / CGFloat(duration.seconds)
        print("progress", progress)
        var radius: Float = 10
        var lineWidth: Float = 7
        let pointsArr = data.getPoints(progress: progress)
        let startPoint = data.getStartPoint()
        var start: [Float] = [Float(startPoint.x), Float(startPoint.y)]
        let endPoint = pointsArr[pointsArr.count - 1]
        var end: [Float] = [Float(endPoint.x), Float(endPoint.y)]
        let linePoint = data.getLinePoint(progress: progress)
        var line: [Float] = [Float(linePoint.x), Float(linePoint.y)]
        var points = data.getPointsArray(progress: progress)
        var pointCount = data.pointCount
        
        computeCommandEncoder!.setBytes(&radius, length: MemoryLayout<Float>.size, index: 0)
        computeCommandEncoder!.setBytes(&lineWidth, length: MemoryLayout<Float>.size, index: 1)
        computeCommandEncoder!.setBytes(&start, length: 2 * MemoryLayout<Float>.size, index: 2)
        computeCommandEncoder!.setBytes(&end, length: 2 * MemoryLayout<Float>.size, index: 3)
        computeCommandEncoder!.setBytes(&line, length: 2 * MemoryLayout<Float>.size, index: 4)
        computeCommandEncoder!.setBytes(&points, length: points.count * MemoryLayout<Float>.size, index: 5)
        computeCommandEncoder!.setBytes(&pointCount, length: MemoryLayout<Int>.size, index: 6)
        
        // Encode a threadgroup's execution of a compute function
        computeCommandEncoder!.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupCount)
        
        // End the encoding of the command.
        computeCommandEncoder!.endEncoding()
        
        // Register the current drawable for rendering.
        //commandBuffer!.present(drawable)
        
        // Commit the command buffer for execution.
        commandBuffer!.commit()
        commandBuffer!.waitUntilCompleted()
        
        return outputTexture
    }
}
