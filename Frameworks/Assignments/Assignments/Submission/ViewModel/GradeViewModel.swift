//
//  GradeViewModel.swift
//  Assignments
//
//  Created by Nathan Lambson on 3/14/16.
//  Copyright © 2016 Instructure. All rights reserved.
//

import Foundation
import AssignmentKit
import UIKit

public enum GradeViewModel {
    
    case None
    case AwaitingGrade
    case Ungraded
    case LetterGradeOrGPA(String, points: Double, possible: Double)
    case Points(points: Double, possible: Double)
    case Percent(String, points: Double, possible: Double)
    case CompleteOrIncomplete(String, points: Double, possible: Double)
    
    public func detailsWithFormatter(formatter: Double->String) -> (grade: String, gradeDetails: String, circlePercent: CGFloat, gradeLabelOffset: CGFloat) {
        var details = (
            grade: "",
            gradeDetails: "",
            circlePercent: CGFloat(0.0),
            gradeLabelOffset: CGFloat(-21.0)
        )
        
        switch self {
        case .None:
            details.gradeLabelOffset = 0.0
            
        case .AwaitingGrade:
            details.grade = formatter(0.0)
            details.gradeDetails = NSLocalizedString("Awaiting Grade", comment: "This assignment hasn't been graded yet but can be graded")
            details.circlePercent = CGFloat(0.0/1.0)
            
        case .Ungraded:
            details.grade = NSLocalizedString("Ungraded", comment: "This assignment is not graded")
            details.gradeLabelOffset = 0.0
            
        case let .LetterGradeOrGPA(grade, points, possible):
            details.grade = grade
            details.gradeDetails = NSLocalizedString("\(formatter(points)) of \(formatter(possible))", comment: "grade details for points based grade i.e. \"10 of 12\"")
            details.circlePercent = possible <= 0 ? 0.0 : CGFloat(points/possible)
            
        case let .Points(points, possible):
            details.grade = formatter(points) ?? ""
            details.gradeDetails = NSLocalizedString(" of \(formatter(possible))", comment: "grade details for points based grade i.e. \"10 of 12\"")
            details.circlePercent = possible <= 0 ? 0.0 : CGFloat(points/possible)
            
        case let .Percent(percentText, points, possible):
            details.grade = percentText
            details.gradeDetails = NSLocalizedString("\(formatter(points)) of \(formatter(possible))", comment: "grade details for points based grade i.e. \"10 of 12\"")
            details.circlePercent = possible <= 0 ? 0.0 : CGFloat(points/possible)
            
        case let .CompleteOrIncomplete(label, points, possible):
            details.grade = label.capitalizedString
            details.gradeDetails = NSLocalizedString("\(formatter(points)) of \(formatter(possible))", comment: "grade details for points based grade i.e. \"10 of 12\"")
            details.circlePercent = possible <= 0 ? 0.0 : CGFloat(points/possible)
        }
        return details
    }
    
    func updateGradeView(view: CircularGradeView, animated: Bool) {
        CATransaction.begin()
        CATransaction.setDisableActions(!animated)
        let details = detailsWithFormatter({ CircularGradeView.numberFormatter.stringFromNumber($0) ?? "" } )
        view.gradeLabel.text = details.grade
        view.gradeDetailLabel.text = details.gradeDetails
        view.gradeLayer.strokeEnd = details.circlePercent
        view.gradeLabelOffsetConstraint.constant = details.gradeLabelOffset
        CATransaction.commit()
    }
    
    public static func gradeViewModelForAssignment(assignment: Assignment) -> GradeViewModel {
        var grade = GradeViewModel.None
        
        
        if (assignment.gradedAt == nil && assignment.gradingType != GradingType.NotGraded) {
            grade = .AwaitingGrade
            return grade
        }
        
        
        let currentScore = assignment.currentScore?.doubleValue ?? 0
        switch assignment.gradingType {
        case GradingType.NotGraded:
            grade = .Ungraded
        case GradingType.LetterGrade, GradingType.GPAScale:
            let letterGrade = assignment.currentGrade ?? ""
            grade = .LetterGradeOrGPA(letterGrade, points: currentScore, possible: assignment.pointsPossible)
        case GradingType.PassFail:
            let completeIncomplete = assignment.currentGrade ?? ""
            grade = .CompleteOrIncomplete(completeIncomplete, points: currentScore, possible: assignment.pointsPossible)
        case GradingType.Percent:
            let letterGrade = assignment.currentGrade ?? ""
            grade = .Percent(letterGrade, points: currentScore, possible: assignment.pointsPossible)
        case GradingType.Points:
            grade = .Points(points: currentScore, possible: assignment.pointsPossible)
        default: print("Error this shouldn't happen")
        }
        
        return grade
    }
}

// MARK: - Equatable

extension GradeViewModel: Equatable {}
public func ==(lhs: GradeViewModel, rhs: GradeViewModel) -> Bool {
    switch (lhs, rhs) {
    case (.None, .None), (.AwaitingGrade, .AwaitingGrade), (.Ungraded, .Ungraded):
        return true
    case let (.LetterGradeOrGPA(grade1, points1, possible1), .LetterGradeOrGPA(grade2, points2, possible2)):
        return grade1 == grade2 && points1 == points2 && possible1 == possible2
    case let (.Points(points1, possible1), .Points(points2, possible2)):
        return points1 == points2 && possible1 == possible2
    case let (.Percent(text1, points1, possible1), .Percent(text2, points2, possible2)):
        return text1 == text2 && points1 == points2 && possible1 == possible2
    case let (.CompleteOrIncomplete(label1, points1, possible1), .CompleteOrIncomplete(label2, points2, possible2)):
        return label1 == label2 && points1 == points2 && possible1 == possible2
    default: return false
    }
}

