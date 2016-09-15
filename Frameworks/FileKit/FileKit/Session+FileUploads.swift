//
//  Session+FileUploads.swift
//  FileKit
//
//  Created by Derrick Hathaway on 1/21/16.
//  Copyright © 2016 Instructure. All rights reserved.
//

import Foundation
import TooLegit
import ReactiveCocoa
import Marshal
import SoLazy
import CoreData

struct UploadTarget {
    let url: NSURL
    let parameters: JSONObject
    
    static func parse(json: JSONObject) -> SignalProducer<UploadTarget, NSError> {
        return attemptProducer {
            UploadTarget(
                url: try json <| "upload_url",
                parameters: try json <| "upload_params"
            )
        }
    }
}

private let FileUploadErrorTitle = NSLocalizedString("File Upload Error", comment: "title for file upload errors")

private let MultipartBoundary = try! "---------------------------3klfenalksjflkjoi9auf89eshajsnl3kjnwal".UTF8Data()

extension Session {

    public enum UploadProgress {
        case Progress(sent: Int64, total: Int64)
        case Completed(File)
        
        static func fromInternalProgress(p: InternalUploadProgress) -> SignalProducer<UploadProgress, NSError> {
            switch p {
            case let .BytesSent(sent: sent, total: total):
                return SignalProducer(value: .Progress(sent: sent, total: total))
            case .Completed(let file):
                return SignalProducer(value: .Completed(file))
            default:
                return SignalProducer.empty
            }
        }
    }

    enum InternalUploadProgress {
        case BytesSent(sent: Int64, total: Int64)
        case DataCompleted(NSURL)
        case Completed(File)
    }
    
    func requestPostUploadTarget(path: String, fileName: String, size: Int, contentType: String?, folderPath: String?, overwrite: Bool) throws -> NSURLRequest {
        var parametrs: [String: AnyObject] = [
            "name": fileName,
            "size": size,
        ]
        
        if let c = contentType { parametrs["content_type"] = c }
        if let f = folderPath { parametrs["folder"] = f }
        if !overwrite { parametrs["on_duplicate"] = "rename" }
        
        return try POST(path, parameters: parametrs, encoding: .URL)
    }
    
    func encodeMultipartBody(data: NSData, parameters: [String: AnyObject]) -> SignalProducer<NSData, NSError> {
        return attemptProducer {
            let delim = try "--\(MultipartBoundary)\r\n".UTF8Data()
            
            let body = NSMutableData()
            body += delim
            for (key, value) in parameters {
                body += try "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)\r\n".UTF8Data()
                body += delim
            }
            
            body += try "Content-Disposition: form-data; name=\"file\"\r\n\r\n".UTF8Data()
            body += data
            body += try "\r\n--\(MultipartBoundary)--\r\n".UTF8Data()
            
            return body
        }
    }

    func writeDataToFile(identifier: String) -> (data: NSData) -> SignalProducer<NSURL, NSError> {
        return { data in
            let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
            let documentsURL = NSURL(fileURLWithPath: documentsPath, isDirectory: true)

            let fileName = identifier + ".tmp"

            let url = documentsURL.URLByAppendingPathComponent(fileName)

            data.writeToURL(url, atomically: true)
            return SignalProducer(value: url)
        }
    }

    func requestUploadFile(data: NSData) -> (target: UploadTarget) -> SignalProducer<(NSMutableURLRequest, NSURL), NSError> {
        return { target in
            let identifier = String(NSDate().timeIntervalSince1970)

            let request = NSMutableURLRequest(URL: target.url, cachePolicy: .ReloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60)
            request.HTTPMethod = "POST"
            
            let contentType = "multipart/form-data; boundary=\(MultipartBoundary)"
            request.addValue(contentType, forHTTPHeaderField: "Content-Type")
            
            let sessionID = self.sessionID
            
            return self.encodeMultipartBody(data, parameters: target.parameters)
                .mapError { e in
                    let description = NSLocalizedString("There was a problem preparing the file for upload", comment: "File upload error message")
                    return NSError(subdomain: "FileKit", code: 0, sessionID: sessionID, apiURL: target.url, title: FileUploadErrorTitle, description: description, failureReason: e.localizedDescription)
                }
                .flatMap(.Concat, transform: self.writeDataToFile(identifier))
                .map { (request, $0) }
        }
    }

    public func addFileUploadCompletionHandler(fileUpload: FileUpload, inContext context: NSManagedObjectContext) {
        URLSession.getAllTheTasksWithCompletionHandler { tasks in
            if let task = tasks.filter({ $0.taskIdentifier == fileUpload.taskIdentifier }).first {
                fileUpload.addTaskCompletionHandler(task, inSession: self, inContext: context)
            }
        }
    }
}
