/*
 This source file is part of the Swift.org open source project

 Copyright 2015 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors
*/


// This syntax is super neat!
public enum _______Foo: _______Foo?, Enum {
    case bar = "bas"
    case bas = "bar"
    //case batt = "bar"
    case bat = 0
    case batt = 1
}


public protocol Enum: CaseIterable, ExpressibleByStringLiteral {}
extension Enum {
    public static func ==(lhs: Self, rhs: Self) -> Bool { "\(lhs)" == "\(rhs)" }
    public init(stringLiteral value: String) { self = Self.allCases.first { "\($0)" == value }! }
}
//print(Foo.bar == Foo.bas)


public extension Int {
    /// Turn an Int into a Double
    var db: Double { return Double(self) }
}



enum Hii: Bool? {
    typealias RawValue = Bool?
    case boo = true
    case bot = false
    case too = 0 // This turns to `nil`
}
extension Optional: ExpressibleByIntegerLiteral  {
    public init(integerLiteral value: Int) {
        self = nil
    }
}

// This syntax is super neat!
public enum Hi: Hi?, CaseIterable {
    // public typealias RawValue = Hi?
    case boo = "boo"
    case bot = "bot"
    case too = 0
}
extension Hi: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = Hi.allCases.filter { "\($0)" == value }.first!
    }
}




public enum ThisIsNice: String {
    case one = "3894983939"
    
}





public enum BoolRawValueBug: Bool {
    case bar = true
    case foo = false
    case bas = 1
    case bat = 2
}

extension Bool: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) { self = true }
}

import Foundation

// Recursive Dictionary Raw Value
extension Dictionary: LosslessStringConvertible where Key: LosslessStringConvertible, Value: LosslessStringConvertible {
    public init?(_ description: String) {
        let regex1 = Regex.init(#"^ *\[(.*)\] *$"#)
        if !regex1.matches(description) { return nil }
        let newValue = description.replacingAll(matching: regex1, with: "$1")
        
        if newValue.contains("[") {
            var keys = [""]
            var values = [""]
            var count = 0
            var keysTurn = true
            for i in newValue {
                if i == "[" { count += 1 }
                if count == 0, i == ":" { keysTurn.toggle(); values.append(""); continue }
                if count == 0, i == " " { continue }
                if count == 0, i == "," { keysTurn.toggle(); keys.append(""); continue }
                if keysTurn {
                    keys[keys.count - 1].append(String(i))
                } else {
                    values[values.count - 1].append(String(i))
                }
                if i == "]" { count -= 1 }
            }
            let allKeys = keys.map { Key($0)! }
            if values.count > 1 {
                values = values.filter { $0 != "" }
                //values = values.dropFirst().map { String($0) }
            }
            let allVals = values.map { Value($0)! }
            
            var newDict: [Key:Value] = [:]
            for i in 0..<allKeys.count {
                if let _ = newDict[allKeys[i]] { fatalError("Dict has duplicate Keys") }
                newDict[allKeys[i]] = allVals[i]
            }
            self = newDict
        } else {
            let arr = newValue.split(separator: ",").map { String($0) }
            if arr == [":"] { self = [Key:Value](); return }
            
            var dict: [Key:Value] = [:]
            for i in arr {
                let keyValue = i.split(separator: ":").map { String($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
                let thisKey = Key(keyValue[0])!
                let thisVal = Value(keyValue[1])!
                if let _ = dict[thisKey] { fatalError("Dictionary has multiple of the same KEYS") }
                dict[thisKey] = thisVal
            }
            self = dict
        }
    }
}

// Dictionary Raw Value
extension Dictionary: ExpressibleByUnicodeScalarLiteral where Key: LosslessStringConvertible, Value: LosslessStringConvertible {
    public typealias UnicodeScalarLiteralType = String
}
extension Dictionary: ExpressibleByExtendedGraphemeClusterLiteral where Key: LosslessStringConvertible, Value: LosslessStringConvertible {
    public typealias ExtendedGraphemeClusterLiteralType = String
}
extension Dictionary: ExpressibleByStringLiteral where Key: LosslessStringConvertible, Value: LosslessStringConvertible {
    public typealias StringLiteralType = String
    public init(stringLiteral value: String) {
        self = Dictionary(value)!
    }
}




// Recursive Array Raw Value
extension Array: LosslessStringConvertible where Element: LosslessStringConvertible {
    public init?(_ description: String) {
        let regex1 = Regex.init(#"^ *\[(.*)\] *$"#)
        if !regex1.matches(description) { return nil }
        let newValue = description.replacingAll(matching: regex1, with: "$1")
        
        if newValue.contains("[") {
            var elementals = [""]
            var count = 0
            for i in newValue {
                if i == "[" { count += 1 }
                if count == 0, i == " " {
                    elementals.append("")
                } else if count != 0 {
                    elementals[elementals.count - 1].append(String(i))
                }
                if i == "]" { count -= 1 }
            }
            print(elementals)
            self = elementals.map { Element($0)! }
            return
        } else {
            let arr = newValue.split(separator: ",").compactMap {Element($0.trimmingCharacters(in: .whitespacesAndNewlines))}
            if Element.self == String.self {
                self = (arr as! [String]).map {
                    String($0[$0.index(after: $0.startIndex)..<$0.index(before: $0.endIndex)])
                    } as! [Element]
            } else {
                self = arr
            }
        }
    }
}

// Array Raw Value
extension Array: ExpressibleByUnicodeScalarLiteral where Element: LosslessStringConvertible {
    public typealias UnicodeScalarLiteralType = String
}
extension Array: ExpressibleByExtendedGraphemeClusterLiteral where Element: LosslessStringConvertible {
    public typealias ExtendedGraphemeClusterLiteralType = String
}
extension Array: ExpressibleByStringLiteral where Element: LosslessStringConvertible {
    public typealias StringLiteralType = String
    public init(stringLiteral value: String) {
        self = Array(value)!
    }
}


// Set Raw Value
extension Set: ExpressibleByUnicodeScalarLiteral where Element: LosslessStringConvertible {
    public typealias UnicodeScalarLiteralType = String
}
extension Set: ExpressibleByExtendedGraphemeClusterLiteral where Element: LosslessStringConvertible {
    public typealias ExtendedGraphemeClusterLiteralType = String
}
extension Set: ExpressibleByStringLiteral where Element: LosslessStringConvertible {
    public typealias StringLiteralType = String
    public init(stringLiteral value: String) {
        self = Set(Array(value)!)
    }
}



// Closed Range Raw Value
extension ClosedRange: ExpressibleByUnicodeScalarLiteral where Bound: LosslessStringConvertible {
    public typealias UnicodeScalarLiteralType = String
}
extension ClosedRange: ExpressibleByExtendedGraphemeClusterLiteral where Bound: LosslessStringConvertible {
    public typealias ExtendedGraphemeClusterLiteralType = String
}
extension ClosedRange: ExpressibleByStringLiteral where Bound: LosslessStringConvertible {
    public typealias StringLiteralType = String
    public init(stringLiteral value: String) {
        let side1 = Regex(#"^.+\.\.\."#)
        let side2 = Regex(#"\.\.\..+$"#)
        let theLowerBound = value.replacingFirst(matching: side2, with: "")
        let theUpperBound = value.replacingFirst(matching: side1, with: "")
        self = (Bound(theLowerBound)!)...(Bound(theUpperBound)!)
    }
}

// Range Raw Value
extension Range: ExpressibleByUnicodeScalarLiteral where Bound: LosslessStringConvertible {
    public typealias UnicodeScalarLiteralType = String
}
extension Range: ExpressibleByExtendedGraphemeClusterLiteral where Bound: LosslessStringConvertible {
    public typealias ExtendedGraphemeClusterLiteralType = String
}
extension Range: ExpressibleByStringLiteral where Bound: LosslessStringConvertible {
    public typealias StringLiteralType = String
    public init(stringLiteral value: String) {
        let side1 = Regex(#"^.+\.\.\<"#)
        let side2 = Regex(#"\.\.\<.+$"#)
        let theLowerBound = value.replacingFirst(matching: side2, with: "")
        let theUpperBound = value.replacingFirst(matching: side1, with: "")
        self = (Bound(theLowerBound)!)..<(Bound(theUpperBound)!)
    }
}











public prefix func !(this: String) { print(this) }











public struct PlayingCard: Equatable, Hashable {
    public let rank: Rank
    public let suit: Suit

    public init(rank: Rank, suit: Suit) {
        self.rank = rank
        self.suit = suit
    }
}

// MARK: - Comparable

extension PlayingCard: Comparable {
    public static func <(lhs: PlayingCard, rhs: PlayingCard) -> Bool {
        return lhs.rank == rhs.rank ? lhs.suit < rhs.suit : lhs.rank < rhs.rank
    }
}

// MARK: - CustomStringConvertible

extension PlayingCard: CustomStringConvertible {
    public var description: String {
        return "\(suit) \(rank)"
    }
}
