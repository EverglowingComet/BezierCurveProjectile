//
//  CGImage.swift
//  BezierCurve
//
//  Created by Comet on 2/1/24.
//

import CoreGraphics
import MetalKit

extension CGImage {
    public func pixelBuffer() -> CVPixelBuffer? {
        return pixelBuffer(width: width, height: height, orientation: .up)
    }
    
    public func pixelBuffer(width: Int, height: Int,
                            orientation: CGImagePropertyOrientation) -> CVPixelBuffer? {
        return pixelBuffer(width: width, height: height,
                         pixelFormatType: kCVPixelFormatType_32ARGB,
                         colorSpace: CGColorSpaceCreateDeviceRGB(),
                         alphaInfo: .noneSkipFirst,
                         orientation: orientation)
    }
    
    public func pixelBuffer(width: Int, height: Int,
                              pixelFormatType: OSType,
                              colorSpace: CGColorSpace,
                              alphaInfo: CGImageAlphaInfo,
                              orientation: CGImagePropertyOrientation) -> CVPixelBuffer? {
        assert(orientation == .up)
        
        var maybePixelBuffer: CVPixelBuffer?
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferMetalCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferIOSurfaceCoreAnimationCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferIOSurfaceOpenGLESTextureCompatibilityKey: kCFBooleanTrue,]
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         width,
                                         height,
                                         pixelFormatType,
                                         attrs as CFDictionary,
                                         &maybePixelBuffer)
        
        guard status == kCVReturnSuccess, let pixelBuffer = maybePixelBuffer else {
          return nil
        }
        
        let flags = CVPixelBufferLockFlags(rawValue: 0)
        guard kCVReturnSuccess == CVPixelBufferLockBaseAddress(pixelBuffer, flags) else {
          return nil
        }
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, flags) }
        
        guard let context = CGContext(data: CVPixelBufferGetBaseAddress(pixelBuffer),
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                                      space: colorSpace,
                                      bitmapInfo: alphaInfo.rawValue)
        else {
          return nil
        }
        
        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
        return pixelBuffer
    }
}
