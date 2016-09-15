//
//  Tab+CollectionsTest.swift
//  Enrollments
//
//  Created by Egan Anderson on 7/1/16.
//  Copyright © 2016 Instructure Inc. All rights reserved.
//

import XCTest
@testable import EnrollmentKit
import TooLegit
import CoreData
import SoAutomated
import SoPersistent
import Marshal

class TabCollectionsTests: UnitTestCase {
    let session = Session.art
    var context: NSManagedObjectContext!
   
    // MARK: collection

    func testTab_collection_sortsByPosition() {
        attempt {
            context = try session.enrollmentManagedObjectContext()
            let first = Tab.build(context)
            try first.updateValues(tabJSON(1), inContext: context)
            let third = Tab.build(context)
            try third.updateValues(tabJSON(3), inContext: context)
            let second = Tab.build(context)
            try second.updateValues(tabJSON(2), inContext: context)
            let contextID: ContextID = ContextID(url: NSURL(string: "https://mobiledev.instructure.com/api/v1/courses/1422605")!)!
            let collection = try Tab.collection(session, contextID: contextID)
            XCTAssertEqual([first, second, third], collection.allObjects, "favoritesCollection sorts by position")
        }
    }
    
    func testTab_shortcuts() {
        attempt {
            context = try session.enrollmentManagedObjectContext()
            let tab = Tab.build(context)
            try tab.updateValues(tabJSON(1), inContext: context)
            let contextID: ContextID = ContextID(url: NSURL(string: "https://mobiledev.instructure.com/api/v1/courses/1422605")!)!
            let shortcuts = try Tab.shortcuts(session, contextID: contextID)
            XCTAssertEqual([tab], shortcuts.allObjects, "favoritesCollection sorts by position")
        }
    }
    
    // MARK: refresher
    
    func testTab_refresher() {
        attempt {
            context = try session.enrollmentManagedObjectContext()
            let contextID: ContextID = ContextID(url: NSURL(string: "https://mobiledev.instructure.com/api/v1/courses/1422605")!)!
            let refresher = try Tab.refresher(session, contextID: contextID)
            assertDifference({ Tab.count(inContext: context) }, 5, "refresher syncs tabs") {
                stub(session, "refresh-all-tabs") { expectation in
                    refresher.refreshingCompleted.observeNext(self.refreshCompletedWithExpectation(expectation))
                    refresher.refresh(true)
                }
            }
        }
    }
    
    private func tabJSON(position: Int) -> JSONObject {
        return [
            "url": "https://mobiledev.instructure.com/api/v1/courses/1422605",
            "id": "files",
            "position": position,
            "label": "1",
        ]
    }
}

//MARK: tableViewController

class TabTableViewControllerTests: UnitTestCase {
    let session = Session.art
    let tvc = Tab.TableViewController()
    let viewModelFactory = ViewModelFactory<Tab>.new { _ in UITableViewCell() }
    
    func testTableViewController_prepare_setsCollection() {
        attempt {
            let contextID: ContextID = ContextID(url: NSURL(string: "https://mobiledev.instructure.com/api/v1/courses/1422605")!)!
            let collection = try Tab.collection(session, contextID: contextID)
            tvc.prepare(collection, viewModelFactory: viewModelFactory)
            XCTAssertEqual(collection, tvc.collection, "prepare sets the collection")
        }
    }
    
    func testTableViewController_prepare_setsRefresher() {
        attempt {
            let contextID: ContextID = ContextID(url: NSURL(string: "https://mobiledev.instructure.com/api/v1/courses/1422605")!)!
            let collection = try Tab.collection(session, contextID: contextID)
            let refresher = try Tab.refresher(session, contextID: contextID)
            tvc.prepare(collection, refresher: refresher, viewModelFactory: viewModelFactory)
            XCTAssertNotNil(tvc.refresher, "prepare sets the refresher")
        }
    }
    
    func testTableViewController_prepare_setsDataSource() {
        attempt {
            let contextID: ContextID = ContextID(url: NSURL(string: "https://mobiledev.instructure.com/api/v1/courses/1422605")!)!
            let collection = try Tab.collection(session, contextID: contextID)
            tvc.prepare(collection, viewModelFactory: viewModelFactory)
            XCTAssertNotNil(tvc.dataSource, "prepare sets the data source")
        }
    }
}

