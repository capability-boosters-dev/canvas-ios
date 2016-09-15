//
//  PhotoOrVideoUploadAction.swift
//  File
//
//  Created by Derrick Hathaway on 12/2/15.
//  Copyright © 2015 Instructure. All rights reserved.
//

import UIKit
import Photos
import MobileCoreServices

class PhotoOrVideoUploadAction: NSObject, UploadAction, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    let title: String
    let icon: UIImage
    let sourceType: UIImagePickerControllerSourceType
    let mediaTypes: [String]
    
    weak var viewController: UIViewController?
    weak var delegate: UploadActionDelegate?
    
    init(title: String, icon: UIImage, sourceType: UIImagePickerControllerSourceType, mediaTypes: [String], viewController: UIViewController?, delegate: UploadActionDelegate) {
        self.title = title
        self.icon = icon
        self.sourceType = sourceType
        self.mediaTypes = mediaTypes
        self.viewController = viewController
        self.delegate = delegate
    }
    
    func initiate() {
        
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.mediaTypes = mediaTypes
        picker.delegate = self
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            picker.modalPresentationStyle = .PageSheet
        }
        
        viewController?.presentViewController(picker, animated: true, completion: nil)
    }
    
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        var upload = NewUpload.None
        
        if let
            assetURL = info[UIImagePickerControllerReferenceURL] as? NSURL,
            asset = PHAsset.fetchAssetsWithALAssetURLs([assetURL], options: nil).firstObject as? PHAsset {
                
            upload = .FileUpload([.CameraRollAsset(asset)])
        } else if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            upload = .FileUpload([.Photo(image)])
        } else if let videoURL = info[UIImagePickerControllerMediaURL] as? NSURL {
            upload = .MediaComment(.VideoURL(videoURL))
        }
        viewController?.dismissViewControllerAnimated(true) {
            self.delegate?.chooseUpload(upload)
        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        viewController?.dismissViewControllerAnimated(true) {
            self.delegate?.actionCancelled()
        }
    }
    
    deinit {
        print("Photo action died")
    }
}


extension PhotoOrVideoUploadAction {
    static func actionsForUpload(viewController: UIViewController?, delegate: UploadActionDelegate, allowedImagePickerControllerMediaTypes: [String], allowsPhotos: Bool, allowsVideo: Bool) -> [UploadAction] {
        
        let mediaTypes = allowedImagePickerControllerMediaTypes
        guard mediaTypes.count > 0 else { return [] }

        let titles = titlesForTakingPhotoOrVideo(allowsPhotos, allowsVideo: allowsVideo)
        return [
            PhotoOrVideoUploadAction(title: titles.choosing, icon: .FileKitImageNamed("icon_cameraroll"), sourceType: .PhotoLibrary, mediaTypes: mediaTypes, viewController: viewController, delegate: delegate),
            PhotoOrVideoUploadAction(title: titles.taking, icon: .FileKitImageNamed("icon_camera"), sourceType: .Camera, mediaTypes: mediaTypes, viewController: viewController, delegate: delegate)
        ]
    }
    
    private static func titlesForTakingPhotoOrVideo(allowsPhotos: Bool, allowsVideo: Bool) -> (taking: String, choosing: String) {
        let titles: (String, String)
        switch (allowsPhotos, allowsVideo) {
        case (true, false):
            titles = (
                taking: NSLocalizedString("Take a Photo", comment: "Take a photo submission choice"),
                choosing: NSLocalizedString("Choose a Photo", comment: "Pick a photo from library")
            )
        case (false, true):
            titles = (
                taking: NSLocalizedString("Take a Video", comment: "Take a video submission choice"),
                choosing: NSLocalizedString("Choose a Video", comment: "Pick a video from library")
            )
        default:
            titles = (
                taking: NSLocalizedString("Take Photo or Video", comment: "Take a photo or video submission choice"),
                choosing: NSLocalizedString("Choose a Photo or Video", comment: "Pick a photo or video")
            )
        }
        
        return titles
    }
}