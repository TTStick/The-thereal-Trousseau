//
//  BackgroundRemovalService.swift
//  Local foreground segmentation via Apple's Vision framework.
//  No model downloads, no network — pure on-device inference.
//
//  Uses VNInstanceMaskObservation (iOS 17+), which is the modern equivalent
//  of rembg's u2net pipeline. Falls back to saliency-based foreground when
//  the instance mask returns nothing (rare).
//

import Foundation
import Vision
import CoreImage
import UIKit

enum BackgroundRemovalError: Error {
    case noForegroundFound
    case visionFailure(Error)
}

final class BackgroundRemovalService {

    static let shared = BackgroundRemovalService()

    private let ciContext = CIContext(options: [.cacheIntermediates: false])

    /// Mirror of the web version's `process_image`:
    ///  1. segment subject from background (rembg / Vision instance mask)
    ///  2. crop tight bbox
    ///  3. center on parchment canvas (800x800)
    ///  4. subject occupies 85% of canvas (target_size = 680)
    func process(input: UIImage) async throws -> UIImage {
        guard let ci = CIImage(image: input) else {
            throw BackgroundRemovalError.noForegroundFound
        }

        let handler = VNImageRequestHandler(ciImage: ci, orientation: .up, options: [:])

        // --- 1. foreground instance mask (iOS 17+) ---
        let request = VNGenerateForegroundInstanceMaskRequest()
        do {
            try handler.perform([request])
        } catch {
            // Fallback path: saliency (iOS 13+). Lower fidelity but always works.
            return try await fallbackSaliency(input: input, ci: ci, handler: handler)
        }

        guard let result = request.results?.first,
              !result.allInstances.isEmpty else {
            return try await fallbackSaliency(input: input, ci: ci, handler: handler)
        }

        let pixelBuffer: CVPixelBuffer
        do {
            pixelBuffer = try result.generateMaskedImage(
                ofInstances: result.allInstances,
                from: handler,
                croppedToInstancesExtent: true
            )
        } catch {
            throw BackgroundRemovalError.visionFailure(error)
        }

        let maskedCI = CIImage(cvPixelBuffer: pixelBuffer)

        // --- 2. embed masked subject back onto parchment canvas ---
        return mountOnParchment(maskedCI)
    }

    // MARK: - Saliency fallback

    private func fallbackSaliency(input: UIImage, ci: CIImage, handler: VNImageRequestHandler) async throws -> UIImage {
        let saliencyRequest = VNGenerateAttentionBasedSaliencyImageRequest()
        do {
            try handler.perform([saliencyRequest])
        } catch {
            throw BackgroundRemovalError.visionFailure(error)
        }
        guard let observation = saliencyRequest.results?.first,
              let salientObjects = observation.salientObjects,
              let primary = salientObjects.first else {
            throw BackgroundRemovalError.noForegroundFound
        }

        // Build a soft mask from the salient object's bounding box by
        // compositing: keep pixels inside bbox, alpha=0 outside.
        let bbox = primary.boundingBox.intersection(CGRect(x: 0, y: 0, width: 1, height: 1))
        let imageSize = ci.extent.size
        let pixelRect = VNImageRectForNormalizedRect(bbox, Int(imageSize.width), Int(imageSize.height))

        // Fallback: simply crop to the bbox and drop the background.
        let cropped = ci.cropped(to: pixelRect)
        return mountOnParchment(cropped)
    }

    // MARK: - Parchment canvas mounting

    private func mountOnParchment(_ subject: CIImage) -> UIImage {
        let canvasSize: CGFloat = 800
        let parchmentRGB: (CGFloat, CGFloat, CGFloat) = (244/255, 236/255, 216/255)
        let target: CGFloat = canvasSize * 0.85

        // Letterbox-fit subject into target x target box.
        let scaled: CIImage
        let extent = subject.extent
        let scale = min(target / max(extent.width, 1), target / max(extent.height, 1))
        scaled = subject.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        let canvas = CIImage(color: CIColor(red: parchmentRGB.0, green: parchmentRGB.1, blue: parchmentRGB.2))
            .cropped(to: CGRect(x: 0, y: 0, width: canvasSize, height: canvasSize))

        let xOffset = (canvasSize - scaled.extent.width) / 2
        let yOffset = (canvasSize - scaled.extent.height) / 2
        let composed = scaled.transformed(by: CGAffineTransform(translationX: xOffset, y: yOffset))
            .composited(over: canvas)

        guard let cg = ciContext.createCGImage(composed, from: CGRect(x: 0, y: 0, width: canvasSize, height: canvasSize)) else {
            return UIImage(ciImage: composed)
        }
        return UIImage(cgImage: cg, scale: 1, orientation: .up)
    }
}
