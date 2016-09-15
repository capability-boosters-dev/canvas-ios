//
//  Page.swift
//  Pages
//
//  Created by Joseph Davison on 5/12/16.
//  Copyright © 2016 Instructure. All rights reserved.
//

import Foundation
import CoreData
import SoPersistent
import TooLegit

public final class Page: NSManagedObject, LockableModel {
    
    @NSManaged internal (set) public var url: String // Unique locator for the page
    @NSManaged internal (set) public var title: String
    @NSManaged internal (set) public var createdAt: NSDate
    @NSManaged internal (set) public var updatedAt: NSDate // Date the page was last updated
    @NSManaged internal (set) public var editingRoles: String // Roles allowed to edit page
    @NSManaged internal (set) public var body: String? // HTML body of page
    @NSManaged internal (set) public var published: Bool // Page published (true) or in draft state (false)
    @NSManaged internal (set) public var frontPage: Bool // Whether page is front page for wiki
    
    // MARK: - Course / Group ID
    
    @NSManaged var primitiveContextID: String
    public var contextID: ContextID {
        get {
            return ContextID(canvasContext: primitiveContextID)!
        } set {
            primitiveContextID = newValue.canvasContextID
        }
    }
    
    // MARK: - Last Editor
    
    @NSManaged internal (set) public var lastEditedByName: String? // Display Name of last editor
    @NSManaged internal (set) public var lastEditedByAvatarUrl: NSURL? // Avatar URL of last editor
    
    // MARK: - Locking
    
    @NSManaged public var lockedForUser: Bool
    @NSManaged public var lockExplanation: String? // Explanation of why page is locked for user
    @NSManaged public var canView: Bool
}

import Marshal
import SoLazy

extension Page: SynchronizedModel {
    
    public static func uniquePredicateForObject(json: JSONObject) throws -> NSPredicate {
        let url: String = try json <| "url"
        return NSPredicate(format: "%K == %@", "url", url)
    }

    public func updateValues(json: JSONObject, inContext context: NSManagedObjectContext) throws {
        url             = try json <| "url"
        title           = try json <| "title"
        createdAt       = try json <| "created_at"
        updatedAt       = try json <| "updated_at" ?? createdAt
        editingRoles    = try json <| "editing_roles" ?? ""
        
        // MARK: - Break down last editor information
        
        if let lastEditedJson: JSONObject = try json <| "last_edited_by" {
            lastEditedByName = try lastEditedJson <| "display_name"
            lastEditedByAvatarUrl = try lastEditedJson <| "avatar_image_url"
        }

        body            = try json <| "body" ?? body // body value when calling table view
        published       = try json <| "published"
        frontPage       = try json <| "front_page"
        
        try updateLockStatus(json)
    }
    
}
