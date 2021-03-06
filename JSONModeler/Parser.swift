//
//  Parser.swift
//  JSONModeler
//
//  Created by William Snook on 6/7/17.
//  Copyright © 2017 mobileforming. All rights reserved.
//

import Foundation


typealias DictionaryType = [String:Any]
typealias ArrayType = [Any]

enum ParseDictionaryState {

    case waitForKey
    case waitForColon
    case waitForValue
    case waitForDictionaryEnd
    case dictionaryDone
    
    case dictMessedUp
    
    case end
}

enum ParseArrayState {
    
    case waitForEntry
    case waitForArrayEnd
    case arrayDone
    
    case arrayMessedUp
    
    case end
}

class Parser {
   
    var commaCount = 0
    var colonCount = 0
    var otherCount = 0

    var tokens: [String]
    var tokenCount: Int
    
    
    init(_ tokenList: [String]) {
        tokens = tokenList
        tokenCount = tokens.count
    }
    
    
    func processTokens() -> AnyObject? {
        
        let token = tokens.first
        var index = 1
        
        if token == "{" {
            return processDictionary( &index )
        } else {
            return processArray( &index )
        }
    }
    
    func processDictionary(_ index: inout Int) -> AnyObject? {

        // index points to token after '{'
        var currentKey = ""
        var currentDictionary = DictionaryType()
        var state = ParseDictionaryState.waitForKey
        
        while ( index < tokenCount ) && ( state != .dictionaryDone ) {   // Check token, check state, do operation, next state
            let token = tokens[index]
            index += 1
            if state == .dictMessedUp {
                return nil
            }
            switch token {
                
            case "{":
                switch state {
                    
                case .waitForValue:
                    state = .waitForDictionaryEnd
                    currentDictionary[currentKey] = processDictionary( &index )
                    
                default:
                    print( "Error, dictionary start symbol not expected, state: \(state)" )
                    state = .dictMessedUp
                }
                
            case "}":
                switch state {
                    
                case .waitForDictionaryEnd:
                    state = .dictionaryDone
                    
                default:
                    print( "Error, dictionary end symbol found when not expected, state: \(state)" )
                    state = .dictMessedUp
                }
                
            case "[":
                switch state {
                    
                case .waitForValue:
                    state = .waitForDictionaryEnd
                    currentDictionary[currentKey] = processArray( &index )
                    
                default:
                    print( "Error, array start symbol not expected, state: \(state)" )
                    state = .dictMessedUp
                }
                
            case "]":
                print( "Error, array end symbol found when not expected, state: \(state)" )
                state = .dictMessedUp
                
            case ",":
                commaCount += 1
                switch state {
                    
                case .waitForDictionaryEnd:
                    state = .waitForKey
                    
                default:
                    print( "Error, ',' symbol not expected, state: \(state)" )
                    state = .dictMessedUp
                }

            case ":":
                colonCount += 1
                switch state {
                    
                case .waitForColon:
                    state = .waitForValue
                    
                default:
                    print( "Error, ':' symbol not expected, state: \(state)" )
                    state = .dictMessedUp
                }
                
            default:
                otherCount += 1
                switch state {
                    
                case .waitForKey:
                    state = .waitForColon
                    currentKey = token
                    
                case .waitForValue:
                    state = .waitForDictionaryEnd
                    currentDictionary[currentKey] = token
                    
                default:
                    print( "Got dictionary entry: \(token), in unexpected state: \(state)" )
                    state = .dictMessedUp
                }
            }
        }

        switch state {
            
        case .dictMessedUp:
            print( "Error, exit parser due to state error" )
            
        case .dictionaryDone:
            return currentDictionary as AnyObject

        default:
            print( "Error, at end but not in the dictionaryDone state" )
        }
        return nil
    }
   
    func processArray(_ index: inout Int) -> AnyObject? {
        
        var currentArray = ArrayType()
        
        var state = ParseArrayState.waitForEntry
        
        while ( index < tokenCount ) && ( state != .arrayDone ) {   // Check token, check state, do operation, next state
            let token = tokens[index]
            index += 1
            if state == .arrayMessedUp {
                break
            }
            switch token {
                
            case "{":
                switch state {
                    
                case .waitForEntry:
                    state = .waitForArrayEnd
                    let subDictionary = processDictionary( &index )
                    if subDictionary != nil {
                        currentArray.append( subDictionary as Any )
                    }
                    
                default:
                    print( "Error, dictionary start symbol not expected, state: \(state)" )
                    state = .arrayMessedUp
                }
                
            case "}":
                print( "Error, dictionary end symbol found when not expected, state: \(state)" )
                state = .arrayMessedUp
                
            case "[":
                switch state {
                    
                case .waitForEntry:
                    state = .waitForArrayEnd
                    let subArray = processArray( &index )
                    if subArray != nil {
                        currentArray.append( subArray as Any )
                    }
                    
                default:
                    print( "Error, array start symbol not expected, state: \(state)" )
                    state = .arrayMessedUp
                }
                
            case "]":
                switch state {
                    
                case .waitForArrayEnd, .waitForEntry:
                    state = .arrayDone
                    
                default:
                    print( "Error, array end symbol found when not expected, state: \(state)" )
                    state = .arrayMessedUp
                }
                
            case ",":
                commaCount += 1
                switch state {
                    
                case .waitForArrayEnd:
                    state = .waitForEntry
                    
                default:
                    print( "Error, ',' symbol not expected, state: \(state)" )
                    state = .arrayMessedUp
                }
                
            case ":":
                colonCount += 1
                print( "Error, ':' symbol not expected, state: \(state)" )
                state = .arrayMessedUp
                
            default:
                otherCount += 1
                switch state {
                    
                case .waitForEntry:
                    state = .waitForArrayEnd
                    currentArray.append( token )
                    
                default:
                    state = .arrayMessedUp
                    print( "Error, array entry symbol was unexpected, state: \(state)" )
                }
            }
        }
        
        switch state {
        case .arrayMessedUp:
            print( "Error, exit parser due to state error" )
            
        case .arrayDone:
            return currentArray as AnyObject

        default:
            print( "Error, at end but not in the arrayDone state" )
        }
        return nil
    }

}
