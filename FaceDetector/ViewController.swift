//
//  ViewController.swift
//  FaceDetector
//
//  Created by Helge Stahlmann on 17.01.22.
//

import UIKit
import Vision

class ViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    
    lazy var faceDetectionRequest =
      VNDetectFaceRectanglesRequest(completionHandler: self.onFacesDetected)
    
    let resultsLayer = CALayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        imageView.contentMode = .scaleAspectFit
        imageView.layer.addSublayer(resultsLayer)
    }

    @IBAction func cameraButtonTapped(_ sender: UIButton) {
        let actionSheet = UIAlertController(
            title: "Detect faces",
            message: "Pick a photo to detect faces on.",
            preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(
            title: "Take a new photo",
            style: .default,
            handler: { [weak self] _ in
                self?.showImagePicker(sourceType: .camera)
            })
        let libraryAction = UIAlertAction(
            title: "Pick from your library",
            style: .default,
            handler: { [weak self] _ in
                self?.showImagePicker(sourceType: .savedPhotosAlbum)
            })
        actionSheet.addAction(cameraAction)
        actionSheet.addAction(libraryAction)
        present(actionSheet, animated: true)
    }
    
    func showImagePicker(sourceType: UIImagePickerController.SourceType) {
      let picker = UIImagePickerController()
      picker.sourceType = sourceType
      picker.delegate = self
      present(picker, animated: true)
    }
    
    func detectFaces(on image: UIImage) {
        let handler = VNImageRequestHandler(
            cgImage: image.cgImage!,
            options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
          do {
            try handler.perform([self.faceDetectionRequest])
          } catch {
            print(error)
          }
        }
    }
    
    func onFacesDetected(request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNFaceObservation] else {
            return
        }
      
        for result in results {
            print("Found face at \(result.boundingBox)")
        }
        
        DispatchQueue.main.async {
          CATransaction.begin()
          for result in results {
            print(result.boundingBox)
            self.drawFace(in: result.boundingBox)
          }
          CATransaction.commit()
        }
    }
    
    func denormalized(
      _ normalizedRect: CGRect,
      in imageView: UIImageView)-> CGRect {
      
      let imageSize = imageView.contentClippingRect.size
      let imageOrigin = imageView.contentClippingRect.origin
      
      let newOrigin = CGPoint(
        x: normalizedRect.minX * imageSize.width + imageOrigin.x,
        y: (1 - normalizedRect.maxY) * imageSize.height + imageOrigin.y)
      let newSize = CGSize(
        width: normalizedRect.width * imageSize.width,
        height: normalizedRect.height * imageSize.height)
      
      return CGRect(origin: newOrigin, size: newSize)
    }
    
    private func drawFace(in rect: CGRect) {
      let layer = CAShapeLayer()
      let rect = self.denormalized(rect, in: self.imageView)
      layer.path = UIBezierPath(rect: rect).cgPath
      layer.strokeColor = UIColor.yellow.cgColor
      layer.fillColor = nil
      layer.lineWidth = 2
      self.resultsLayer.addSublayer(layer)
    }

}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    guard let image = info[.originalImage] as? UIImage else {
      return
    }
    
    imageView.image = image
    detectFaces(on: image)
    dismiss(animated: true)
  }
}

extension UIImageView {
  var contentClippingRect: CGRect {
    guard let image = image else { return bounds }
    guard contentMode == .scaleAspectFit else { return bounds }
    guard image.size.width > 0 && image.size.height > 0 else { return bounds }
    
    let scale: CGFloat
    if image.size.width > image.size.height {
      scale = bounds.width / image.size.width
    } else {
      scale = bounds.height / image.size.height
    }
    
    let size = CGSize(
      width: image.size.width * scale,
      height: image.size.height * scale)
    let x = (bounds.width - size.width) / 2.0
    let y = (bounds.height - size.height) / 2.0
    
    return CGRect(x: x, y: y, width: size.width, height: size.height)
  }
}

