//
//  QuizSubmissionController.swift
//  Quizzes
//
//  Created by Derrick Hathaway on 1/31/15.
//  Copyright (c) 2015 Instructure. All rights reserved.
//

import Foundation

import TooLegit
import SoLazy
import Result
import SoProgressive

class SubmissionController {
    
    let quiz: Quiz
    let service: QuizService
    
    private (set) var submission: Submission?
    private var submissionService: QuizSubmissionService?
    private var auditLoggingService: SubmissionAuditLoggingService?
    
    var submissionDidChange: QuizSubmissionResult->() = {_ in } {
        didSet {
            if let submission = self.submission {
                submissionDidChange(Result(value: Page(content: submission)))
            }
        }
    }
    var almostDue: ()->() = { }
    var lockQuiz: ()->() = {}
    
    init(service: QuizService, submission: Submission? = nil, quiz: Quiz) {
        self.service = service
        self.submission = submission
        self.quiz = quiz
        if let sub = submission {
            submissionService = service.serviceForSubmission(sub)
            auditLoggingService = service.serviceForAuditLoggingSubmission(sub)
        }
    }
    
    func beginTakingQuiz() {
        if self.submission != nil {
            auditLoggingService?.logSessionStarted({ _ in })
        } else {
            service.beginNewSubmission { [weak self] submissionResult in
                if let submission = submissionResult.value?.content {
                    self?.submission = submission
                    self?.submissionService = self?.service.serviceForSubmission(submission)
                    self?.auditLoggingService = self?.service.serviceForAuditLoggingSubmission(submission)
                    
                    self?.auditLoggingService?.logSessionStarted({ _ in })
                    
                    // help them out so they aren't slackers and submit things late
                    switch self!.quiz.due {
                    case .Date(let dueDate):
                        let warnDate = dueDate - 1.minutesComponents // 1 minute to give them ample time to read the warning and make a decision
                        let triggerTime = warnDate.timeIntervalSinceNow
                        if triggerTime > 0 {
                            delay(triggerTime) { [weak self] in
                                if self?.submission?.dateFinished == nil { // if it's now 1 minute prior to the due date and they haven't submitted yet
                                    self?.almostDue()
                                }
                            }
                        }
                        
                    case .NoDueDate:
                        break
                    }
                    
                    // auto submit when approaching the lock date
                    if let lockDate = self?.quiz.lockAt {
                        let autoSubmitDate = lockDate - 30.secondsComponents // 10 seconds was to little - maybe do something else? This will depend on the user's connection
                        delay(autoSubmitDate.timeIntervalSinceNow) { [weak self] in
                            if self?.submission?.dateFinished == nil { // if it's now 30 seconds prior to the lock date and they haven't submitted yet
                                self?.lockQuiz()
                            }
                        }
                    }
                }
                
                self?.submissionDidChange(submissionResult)
            }
        }
        
        // For folks who are running under an MDM or a configurator and want to lock the device down...
        // This is a fire and forget cuz well, some folks care, others don't
        UIAccessibilityRequestGuidedAccessSession(true) { _ in }
    }

    func submit(completed: QuizSubmissionResult->()) {
        if let sub = submission {
            // For folks who are running under an MDM or a configurator and want to unlock the device now...
            // This is a fire and forget cuz well, some folks care, others don't
            UIAccessibilityRequestGuidedAccessSession(false) { _ in }
            service.completeSubmission(sub, completed: completed)
        } else {
            completed(Result(error: NSError.quizErrorWithMessage("You don't appear to be taking a quiz.")))
        }
    }
    
    var controllerForSubmissionQuestions: SubmissionQuestionsController? {
        if let subService = submissionService {
            return SubmissionQuestionsController(service: subService, quiz: quiz)
        }
        
        return nil
    }
}
