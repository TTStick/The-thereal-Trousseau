//
//  ColorPaletteService.swift
//  Extracts a 3-colour palette from an image, mirroring colorgram.py.
//

import UIKit
import simd

enum ColorPaletteService {
    /// Returns up to 3 hex strings (#rrggbb) ordered by prominence,
    /// with parchment-like background tones filtered out.
    static func palette(from image: UIImage, count: Int = 3) -> [String] {
        guard let cg = image.cgImage else { return [] }
        let target: CGFloat = 100
        let width = Int(target)
        let height = Int(target)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixels = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        let context = CGContext(
            data: &pixels,
            width: width, height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        context?.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Sample pixels (skip fully transparent).
        var samples: [SIMD3<Float>] = []
        samples.reserveCapacity(width * height)
        for i in stride(from: 0, to: pixels.count, by: bytesPerPixel) {
            let r = Float(pixels[i])
            let g = Float(pixels[i + 1])
            let b = Float(pixels[i + 2])
            let a = pixels[i + 3]
            if a < 16 { continue }
            samples.append(SIMD3(r, g, b))
        }
        guard samples.count > 4 else { return [] }

        // K-means with k = max(4, count+1); final result filtered.
        let k = max(count + 1, 4)
        let clusters = kmeans(samples: samples, k: k, iterations: 8)
        let sorted = clusters.sorted { $0.weight > $1.weight }

        // Filter out near-parchment backgrounds (#f4ecd8 → RGB 244,236,216).
        let filtered = sorted.filter { c in
            !(c.center.x > 230 && c.center.y > 220 && c.center.z > 200)
        }
        let chosen = (filtered.isEmpty ? sorted : filtered).prefix(count)
        return chosen.map { hex(from: $0.center) }
    }

    // MARK: - K-means

    private struct Cluster {
        var center: SIMD3<Float>
        var weight: Int
    }

    private static func kmeans(samples: [SIMD3<Float>], k: Int, iterations: Int) -> [Cluster] {
        guard samples.count >= k else {
            // Not enough samples: return each sample as its own 1-element cluster.
            return samples.map { Cluster(center: $0, weight: 1) }
        }
        // Init: k-means++ style (deterministic stride) — pick every n-th sample.
        var centers: [SIMD3<Float>] = []
        let step = max(1, samples.count / k)
        for i in 0..<k {
            centers.append(samples[(i * step) % samples.count])
        }

        var assignments = [Int](repeating: 0, count: samples.count)
        for _ in 0..<iterations {
            // Assign step
            var changed = false
            for i in 0..<samples.count {
                var bestIdx = 0
                var bestDist = Float.greatestFiniteMagnitude
                for c in 0..<k {
                    let d = simd_distance(samples[i], centers[c])
                    if d < bestDist {
                        bestDist = d
                        bestIdx = c
                    }
                }
                if assignments[i] != bestIdx {
                    assignments[i] = bestIdx
                    changed = true
                }
            }
            if !changed { break }

            // Update step
            var sums = [SIMD3<Float>](repeating: SIMD3(0, 0, 0), count: k)
            var counts = [Int](repeating: 0, count: k)
            for i in 0..<samples.count {
                let a = assignments[i]
                sums[a] += samples[i]
                counts[a] += 1
            }
            for c in 0..<k where counts[c] > 0 {
                centers[c] = sums[c] / Float(counts[c])
            }
        }

        var weights = [Int](repeating: 0, count: k)
        for a in assignments { weights[a] += 1 }
        return (0..<k).map { Cluster(center: centers[$0], weight: weights[$0]) }
    }

    private static func hex(from rgb: SIMD3<Float>) -> String {
        let r = max(0, min(255, Int(rgb.x.rounded())))
        let g = max(0, min(255, Int(rgb.y.rounded())))
        let b = max(0, min(255, Int(rgb.z.rounded())))
        return String(format: "#%02x%02x%02x", r, g, b)
    }
}
