//
//  SMCompoundRequest.swift
//  VRGSoftIOSNetworkKit
//
//  Created by OLEKSANDR SEMENIUK on 7/17/18.
//  Copyright © 2018 VRG Soft. All rights reserved.
//

import UIKit

open class SMCompoundRequest: SMRequest {
    
    open var canceled: Bool = false
    open var finished: Bool = false
    open var executing: Bool = false
    open var currentExecutingIndex: Int = 0
    
    open var executingRequestingParallel: Bool = false
    open var putResponseToOneResult: Bool = false
    open var continueRequestssIfAtLeastOneFail: Bool = false
    
    open var requests: [SMRequest] = [SMRequest]()
    
    public init(withRequests aRequests: [SMRequest]) {
        
        if aRequests.count == 0 {
            
            assert(false)
        }
        
        requests = aRequests
        
        super.init()
    }
    
    open override func canExecute() -> Bool {
        
        var result: Bool = true
        
        for request: SMRequest in requests {
            
            if !request.canExecute() {
                
                result = false
                break
            }
        }
        
        return result
    }
    
    @discardableResult
    open override func start() -> Self {
        
        retainSelf()
        
        canceled = false
        executing = true
        finished = false
        
        if executingRequestingParallel {
            
            startParallel()
        } else {
            
            startSequence()
        }
        
        return self
    }
    
    private func startParallel() {
        
        let requestGroup: DispatchGroup = DispatchGroup()
        
        var responses: [SMResponse] = [SMResponse](repeating: SMResponse(), count: requests.count)
        
        for index: Int in 0...requests.count - 1 {
            
            let request: SMRequest = requests[index]
            
            requestGroup.enter()
            
            request.startWithResponseBlockInMainQueue { response in
                responses[index] = response
                requestGroup.leave()
            }
        }
        
        requestGroup.notify(queue: DispatchQueue.main) { [weak self] in
            self?.finishedAllRequestsWithResponces(aResponses: responses)
        }
    }
    
    private func startSequence() {
        
        startRequest(withIndex: 0)
        
        var responses: [SMResponse] = [SMResponse](repeating: SMResponse(), count: requests.count)
        
        for index: Int in 0...responses.count - 1 {
            
            requests[index].addResponseBlock({ [weak self] (aResponse) in
                
                guard let strongSelf: SMCompoundRequest = self else { return }
                
                responses[index] = aResponse
                
                if aResponse.isSuccess {
                    
                        if index < strongSelf.requests.count - 1 {
                            
                            strongSelf.startRequest(withIndex: index + 1)
                        } else {
                            strongSelf.finishedAllRequestsWithResponces(aResponses: responses)
                        }
                } else {
                    
                    if strongSelf.continueRequestssIfAtLeastOneFail {
                        
                        if index < strongSelf.requests.count - 1 {
                            
                            strongSelf.startRequest(withIndex: index + 1)
                        } else {
                            strongSelf.finishedAllRequestsWithResponces(aResponses: responses)
                        }
                    } else {
                        
                        strongSelf.finishedAllRequestsWithResponces(aResponses: responses)
                    }
                }
            }, responseQueue: DispatchQueue.global(qos: .background))
        }
        
    }
    
    open func finishedAllRequestsWithResponces(aResponses: [SMResponse]) {
        
        let result: SMResponse = SMResponse()
        result.isSuccess = true
        
        if putResponseToOneResult {
            
            result.boArray = aResponses
        } else {
            
            for response: SMResponse in aResponses {
                
                if !response.isSuccess && result.isSuccess {
                    
                    result.isSuccess =  response.isSuccess
                    result.error = response.error
                    result.titleMessage = response.titleMessage
                    result.textMessage = response.textMessage
                }
                
                result.boArray.append(response.boArray as AnyObject)
                response.dataDictionary.forEach { (key, value) in
                    result.dataDictionary[key] = value
                    
                }
            }
        }
        
        executing = false
        finished = true
        
        executeAllResponseBlocks(response: result)
        
        retainSelf()
    }
    
    open override func cancel() {
        
        canceled = true
        executing = false
        finished = true
        
        requests[currentExecutingIndex].cancel()
    }
    
    open func startRequest(withIndex aIndex: Int) {
        
        currentExecutingIndex = aIndex
        requests[currentExecutingIndex].start()
    }
}
