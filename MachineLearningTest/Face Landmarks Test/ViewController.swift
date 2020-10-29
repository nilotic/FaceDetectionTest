//
//  ViewController.swift
//  Face Landmarks Test
//
//  Created by Den Jo on 2020/02/05.
//  Copyright © 2020 Den Jo. All rights reserved.
//

import UIKit
import Vision

final class ViewController: UIViewController {

    // MARK: - IBOutlet
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var imageView2: UIImageView!
    @IBOutlet private var imageView3: UIImageView!
    
  
    
    // MARK: - Value
    // MARK: Private
    private let imageURL = URL(string: "https://imgix.bustle.com/uploads/image/2019/1/14/8d18dc14-4aa3-4da4-be7f-dc308225084b-shutterstock_732091921.jpg?w=1020&h=574&fit=crop&crop=faces&auto=format%2Ccompress&cs=srgb&q=70")!
    
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setImage()
    }
        
        
        
    // MARK: - Function
    // MARK: Private
    private func setImage() {
        DispatchQueue.global().async {
            guard let data = try? Data(contentsOf: self.imageURL), let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self.imageView.image = image
                self.requestLandmarks()
            }
        }
    }
    
    private func requestLandmarks() {
        guard let image = imageView.image, let cgImage = image.cgImage else { return }
        
        // let request        = VNDetectFaceLandmarksRequest()
        let request        = VNDetectFaceRectanglesRequest()
        // let requestHandler = VNImageRequestHandler(url: imageURL)
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try requestHandler.perform([request])
            
            guard let faceObservation = request.results?.first as? VNFaceObservation else {
                debugPrint("Failed to get faceObservations")
                return
            }
            
            // Set Bounding Box
            var scale = imageView.frame.width / image.size.width
            
            let boundingBoxSize  = CGSize(width: image.size.width * faceObservation.boundingBox.width, height: image.size.height * faceObservation.boundingBox.height)
            let boundingBoxPoint = CGPoint(x: imageView.frame.size.width * faceObservation.boundingBox.origin.x, y: image.size.height * (1.0 - faceObservation.boundingBox.origin.y) - boundingBoxSize.height * scale / 2.0)
            
            var boundingBox = CGRect(origin: boundingBoxPoint, size: CGSize(width: boundingBoxSize.width * scale, height: boundingBoxSize.height * scale))
            
            // Draw Bounding Box Border on the Image
            let drawView = UIImageView(frame: CGRect(origin: .zero, size: image.size))
            drawView.image = image
    
            boundingBox = CGRect(x: image.size.width * faceObservation.boundingBox.origin.x, y: image.size.height - image.size.height * faceObservation.boundingBox.origin.y - boundingBoxSize.height,
                                 width: boundingBoxSize.width, height: boundingBoxSize.height)
            
            let boundingBoxView2 = UIView(frame: boundingBox)
            boundingBoxView2.layer.borderColor  = #colorLiteral(red: 0.3647058904, green: 0.06666667014, blue: 0.9686274529, alpha: 1).cgColor
            boundingBoxView2.layer.borderWidth  = 3.0
            boundingBoxView2.layer.cornerRadius = 5.0
            
            drawView.addSubview(boundingBoxView2)
            imageView.image = drawView.renderedImage
            
            
            // Draw by Renderer (Main thread)
            scale = image.size.width / imageView2.frame.width
            let drawRect = CGRect(x: 0, y: boundingBox.origin.y - (imageView2.frame.height * scale - boundingBox.size.height) / 2.0, width: image.size.width, height: imageView2.frame.height * scale)

            let croppedImage = UIGraphicsImageRenderer(bounds: drawRect).image { rendererContext in
                UIImageView(image: image).layer.render(in: rendererContext.cgContext)
            }
            
            imageView2.image = croppedImage
            
            
            // Draw by Cropping (Global thread)
            DispatchQueue.global().async {
                guard let croppedCGImage = cgImage.cropping(to: drawRect) else { return }
                let image3 = UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
                DispatchQueue.main.async { self.imageView3.image = image3 }
            }
            
        } catch {
            debugPrint(error.localizedDescription)
        }
    }
}





extension UIView {
    
    var renderedImage: UIImage? {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in layer.render(in: rendererContext.cgContext) }
    }
}
