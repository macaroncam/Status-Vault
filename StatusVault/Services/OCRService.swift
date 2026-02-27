import Foundation
import Vision
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

class OCRService {
    static let shared = OCRService()

    private init() {}

    func performOCR(on image: UIImage) async throws -> String {
        // Enhanced preprocessing for better OCR accuracy
        guard let preprocessedImage = preprocessImage(image) else {
            throw OCRError.imageProcessingFailed
        }

        guard let cgImage = preprocessedImage.cgImage else {
            throw OCRError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }

                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(3).map { $0.string }.joined(separator: " | ")
                }

                let result = recognizedStrings.joined(separator: "\n")
                continuation.resume(returning: result)
            }

            // Configure for maximum accuracy
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false // Disable auto-correction for dates/numbers
            request.revision = VNRecognizeTextRequestRevision3

            // Process smaller regions for better accuracy
            request.regionOfInterest = CGRect(x: 0, y: 0, width: 1, height: 1)

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private func preprocessImage(_ image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }

        let context = CIContext()

        // 1. Convert to grayscale for better contrast
        guard let grayscaleFilter = CIFilter(name: "CIPhotoEffectMono") else { return nil }
        grayscaleFilter.setValue(ciImage, forKey: kCIInputImageKey)
        guard let grayscaleOutput = grayscaleFilter.outputImage else { return nil }

        // 2. Increase contrast significantly
        guard let contrastFilter = CIFilter(name: "CIColorControls") else { return nil }
        contrastFilter.setValue(grayscaleOutput, forKey: kCIInputImageKey)
        contrastFilter.setValue(2.0, forKey: kCIInputContrastKey) // Boost contrast
        contrastFilter.setValue(0.1, forKey: kCIInputBrightnessKey) // Slight brightness increase
        guard let contrastOutput = contrastFilter.outputImage else { return nil }

        // 3. Apply sharpening to enhance text edges
        guard let sharpenFilter = CIFilter(name: "CISharpenLuminance") else { return nil }
        sharpenFilter.setValue(contrastOutput, forKey: kCIInputImageKey)
        sharpenFilter.setValue(1.5, forKey: kCIInputSharpnessKey) // Strong sharpening
        guard let sharpenedOutput = sharpenFilter.outputImage else { return nil }

        // 4. Apply unsharp mask for additional clarity
        guard let unsharpFilter = CIFilter(name: "CIUnsharpMask") else { return nil }
        unsharpFilter.setValue(sharpenedOutput, forKey: kCIInputImageKey)
        unsharpFilter.setValue(2.5, forKey: kCIInputRadiusKey)
        unsharpFilter.setValue(0.5, forKey: kCIInputIntensityKey)
        guard let finalOutput = unsharpFilter.outputImage else { return nil }

        // Convert back to UIImage
        guard let cgImage = context.createCGImage(finalOutput, from: finalOutput.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    func extractMultipleRegions(from image: UIImage, regions: [CGRect]) async throws -> [String] {
        var results: [String] = []

        for region in regions {
            if let croppedImage = cropImage(image, toRect: region) {
                let text = try await performOCR(on: croppedImage)
                results.append(text)
            }
        }

        return results
    }

    private func cropImage(_ image: UIImage, toRect rect: CGRect) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        // Convert normalized rect (0-1) to pixel coordinates
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)

        let pixelRect = CGRect(
            x: rect.origin.x * width,
            y: rect.origin.y * height,
            width: rect.size.width * width,
            height: rect.size.height * height
        )

        guard let cropped = cgImage.cropping(to: pixelRect) else { return nil }
        return UIImage(cgImage: cropped)
    }
}

enum OCRError: Error {
    case invalidImage
    case noTextFound
    case imageProcessingFailed
}
