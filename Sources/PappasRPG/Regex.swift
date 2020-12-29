//
//  File.swift
//  
//
//  Created by Jonathan Pappas on 10/3/20.
//

import Foundation

import Foundation

internal extension NSTextCheckingResult {
  var ranges: [NSRange] {
    return stride(from: 0, to: numberOfRanges, by: 1).map(range(at:))
  }
}

internal extension String {
  var entireRange: NSRange {
    return NSRange(location: 0, length: utf16.count)
  }
}


import class Foundation.NSTextCheckingResult


public struct MatchResult {
    public var matchedString: String { _result.matchedString }
    public var range: Range<String.Index> { _result.range }
    public var captures: [String?] { return _result.captures }
    public var captureRanges: [Range<String.Index>?] { _result.captureRanges }
    internal var matchResult: NSTextCheckingResult { return _result.result }
    private let _result: _MatchResult
    internal init(_ string: String, _ result: NSTextCheckingResult) {
        self._result = _MatchResult(string, result)
    }
}
private final class _MatchResult {
    private let string: String
    fileprivate let result: NSTextCheckingResult
    fileprivate init(_ string: String, _ result: NSTextCheckingResult) {
        self.string = string; self.result = result
    }
    lazy var range: Range<String.Index> = { Range(self.result.range, in: string)! }()
    lazy var captures: [String?] = {
        self.captureRanges.map { range in range.map { String(self.string[$0]) } }
    }()
    lazy var captureRanges: [Range<String.Index>?] = {
        self.result.ranges.dropFirst().map { Range($0, in: self.string) }
    }()
    lazy var matchedString: String = {
        let range = Range(self.result.range, in: self.string)!
        return String(self.string[range])
    }()
}

extension Regex {
    public struct Options: OptionSet {
        public static let ignoreCase = Options(rawValue: 1)
        public static let ignoreMetacharacters = Options(rawValue: 1 << 1)
        public static let anchorsMatchLines = Options(rawValue: 1 << 2)
        public static let dotMatchesLineSeparators = Options(rawValue: 1 << 3)
        public static let allowCommentsAndWhitespace = Options(rawValue: 1 << 4)
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
    }
}

internal extension Regex.Options {
    func toNSRegularExpressionOptions() -> NSRegularExpression.Options {
        var options = NSRegularExpression.Options()
        if contains(.ignoreCase) { options.insert(.caseInsensitive) }
        if contains(.ignoreMetacharacters) { options.insert(.ignoreMetacharacters) }
        if contains(.anchorsMatchLines) { options.insert(.anchorsMatchLines) }
        if contains(.dotMatchesLineSeparators) { options.insert(.dotMatchesLineSeparators) }
        if contains(.allowCommentsAndWhitespace) { options.insert(.allowCommentsAndWhitespace) }
        return options
    }
}

@available(*, deprecated, renamed: "Regex.Options")
public typealias Options = Regex.Options
extension Regex.Options {
    @available(*, unavailable, renamed: "ignoreCase")
    public static var IgnoreCase: Regex.Options { fatalError() }
    @available(*, unavailable, renamed: "ignoreMetacharacters")
    public static var IgnoreMetacharacters: Regex.Options { fatalError() }
    @available(*, unavailable, renamed: "anchorsMatchLines")
    public static var AnchorsMatchLines: Regex.Options { fatalError() }
    @available(*, unavailable, renamed: "dotMatchesLineSeparators")
    public static var DotMatchesLineSeparators: Regex.Options { fatalError() }
}



public struct Regex: CustomStringConvertible, CustomDebugStringConvertible {
  // MARK: Initialisation
  internal let regularExpression: NSRegularExpression

  /// Create a `Regex` based on a pattern string.
  ///
  /// If `pattern` is not a valid regular expression, an error is thrown
  /// describing the failure.
  ///
  /// - parameters:
  ///     - pattern: A pattern string describing the regex.
  ///     - options: Configure regular expression matching options.
  ///       For details, see `Regex.Options`.
  ///
  /// - throws: A value of `ErrorType` describing the invalid regular expression.
  public init(string pattern: String, options: Options = []) throws {
    self.regularExpression = try NSRegularExpression(
      pattern: pattern,
      options: options.toNSRegularExpressionOptions()
    )
  }

  /// Create a `Regex` based on a static pattern string.
  ///
  /// Unlike `Regex.init(string:)` this initialiser is not failable. If `pattern`
  /// is an invalid regular expression, it is considered programmer error rather
  /// than a recoverable runtime error, so this initialiser instead raises a
  /// precondition failure.
  ///
  /// - requires: `pattern` is a valid regular expression.
  ///
  /// - parameters:
  ///     - pattern: A pattern string describing the regex.
  ///     - options: Configure regular expression matching options.
  ///       For details, see `Regex.Options`.
  public init(_ pattern: StaticString, options: Options = []) {
    do {
      self.regularExpression = try NSRegularExpression(
        pattern: pattern.description,
        options: options.toNSRegularExpressionOptions()
      )
    } catch {
      preconditionFailure("unexpected error creating regex: \(error)")
    }
  }

  // MARK: Matching
  /// Returns `true` if the regex matches `string`, otherwise returns `false`.
  ///
  /// - parameter string: The string to test.
  ///
  /// - returns: `true` if the regular expression matches, otherwise `false`.
  ///
  /// - note: If the match is successful, `Regex.lastMatch` will be set with the
  ///   result of the match.
  public func matches(_ string: String) -> Bool {
    return firstMatch(in: string) != nil
  }

  /// If the regex matches `string`, returns a `MatchResult` describing the
  /// first matched string and any captures. If there are no matches, returns
  /// `nil`.
  ///
  /// - parameter string: The string to match against.
  ///
  /// - returns: An optional `MatchResult` describing the first match, or `nil`.
  ///
  /// - note: If the match is successful, the result is also stored in `Regex.lastMatch`.
  public func firstMatch(in string: String) -> MatchResult? {
    let match = regularExpression
      .firstMatch(in: string, options: [], range: string.entireRange)
      .map { MatchResult(string, $0) }
    Regex._lastMatch = match
    return match
  }

  /// If the regex matches `string`, returns an array of `MatchResult`, describing
  /// every match inside `string`. If there are no matches, returns an empty
  /// array.
  ///
  /// - parameter string: The string to match against.
  ///
  /// - returns: An array of `MatchResult` describing every match in `string`.
  ///
  /// - note: If there is at least one match, the first is stored in `Regex.lastMatch`.
  public func allMatches(in string: String) -> [MatchResult] {
    let matches = regularExpression
      .matches(in: string, options: [], range: string.entireRange)
      .map { MatchResult(string, $0) }
    if let firstMatch = matches.first { Regex._lastMatch = firstMatch }
    return matches
  }

  // MARK: Accessing the last match
  /// After any match, the result will be stored in this property for later use.
  /// This is useful when pattern matching:
  ///
  ///     switch "hello" {
  ///     case Regex("l+"):
  ///       let count = Regex.lastMatch!.matchedString.characters.count
  ///       print("matched \(count) characters")
  ///     default:
  ///       break
  ///     }
  ///
  /// This property uses thread-local storage, and thus is thread safe.
  public static var lastMatch: MatchResult? {
    return _lastMatch
  }

  private static let _lastMatchKey = "me.sharplet.Regex.lastMatch"

  private static var _lastMatch: MatchResult? {
    get { return ThreadLocal(_lastMatchKey).value }
    set { ThreadLocal(_lastMatchKey).value = newValue }
  }

  // MARK: Describing
  public var description: String {
    return regularExpression.pattern
  }

  public var debugDescription: String {
    return "/\(description)/"
  }
}

// MARK: Pattern matching
/// Match `regex` on the left with some `string` on the right. Equivalent to
/// `regex.matches(string)`, and allows for the use of a `Regex` in pattern
/// matching contexts, e.g.:
///
///     switch Regex("hello (\\w+)") {
///     case "hello world":
///       // successful match
///     }
///
/// - parameters:
///     - regex: The regular expression to match against.
///     - string: The string to test.
///
/// - returns: `true` if the regular expression matches, otherwise `false`.
public func ~= (regex: Regex, string: String) -> Bool {
  return regex.matches(string)
}

/// Match `string` on the left with some `regex` on the right. Equivalent to
/// `regex.matches(string)`, and allows for the use of a `Regex` in pattern
/// matching contexts, e.g.:
///
///     switch "hello world" {
///     case Regex("hello (\\w+)"):
///       // successful match
///     }
///
/// - parameters:
///     - regex: The regular expression to match against.
///     - string: The string to test.
///
/// - returns: `true` if the regular expression matches, otherwise `false`.
public func ~= (string: String, regex: Regex) -> Bool {
  return regex.matches(string)
}

// MARK: Conformances
extension Regex: Hashable {}

extension Regex: Codable {
  public init(from decoder: Decoder) throws {
    let string = try decoder.singleValueContainer().decode(String.self)
    try self.init(string: string)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(regularExpression.pattern)
  }
}

// MARK: Deprecations / Removals
extension Regex {
  @available(*, unavailable, renamed: "firstMatch(in:)")
  public func match(_ string: String) -> MatchResult? {
    fatalError()
  }

  @available(*, unavailable, renamed: "allMatches(in:)")
  public func allMatches(_ string: String) -> [MatchResult] {
    fatalError()
  }
}


extension String {
  // MARK: Replacing the first match (mutating)
  /// If `regex` matches at least one substring, replace the first match with
  /// `template`.
  ///
  /// The template string may be a literal string, or include template variables:
  /// the variable `$0` will be replaced with the entire matched substring, `$1`
  /// with the first capture group, etc.
  ///
  /// For example, to include the literal string "$1" in the replacement string,
  /// you must escape the "$": `\$1`.
  ///
  /// - parameters:
  ///     - regex: A regular expression to match against `self`.
  ///     - template: A template string used to replace matches.
  public mutating func replaceFirst(matching regex: Regex, with template: String) {
    if let match = regex.firstMatch(in: self) {
      let replacement = regex
        .regularExpression
        .replacementString(
          for: match.matchResult,
          in: self,
          offset: 0,
          template: template
        )

      replaceSubrange(match.range, with: replacement)
    }
  }

  /// If the regular expression described by `pattern` matches at least one
  /// substring, replace the first match with `template`.
  ///
  /// Convenience overload that accepts a `StaticString` instead of a `Regex`.
  ///
  /// The template string may be a literal string, or include template variables:
  /// the variable `$0` will be replaced with the entire matched substring, `$1`
  /// with the first capture group, etc.
  ///
  /// For example, to include the literal string "$1" in the replacement string,
  /// you must escape the "$": `\$1`.
  ///
  /// - requires: `pattern` is a valid regular expression. Invalid regular
  ///   expressions will cause this method to trap.
  ///
  /// - parameters:
  ///     - pattern: A regular expression pattern to match against `self`.
  ///     - template: A template string used to replace matches.
  public mutating func replaceFirst(matching pattern: StaticString, with template: String) {
    replaceFirst(matching: Regex(pattern), with: template)
  }

  // MARK: Replacing the first match (nonmutating)
  /// Returns a new string where the first match of `regex` is replaced with
  /// `template`.
  ///
  /// The template string may be a literal string, or include template variables:
  /// the variable `$0` will be replaced with the entire matched substring, `$1`
  /// with the first capture group, etc.
  ///
  /// For example, to include the literal string "$1" in the replacement string,
  /// you must escape the "$": `\$1`.
  ///
  /// - parameters:
  ///     - regex: A regular expression to match against `self`.
  ///     - template: A template string used to replace matches.
  ///
  /// - returns: A string with the first match of `regex` replaced by `template`.
  public func replacingFirst(matching regex: Regex, with template: String) -> String {
    var string = self
    string.replaceFirst(matching: regex, with: template)
    return string
  }

  /// Returns a new string where the first match of the regular expression
  /// described by `pattern` is replaced with `template`.
  ///
  /// Convenience overload that accepts a `StaticString` instead of a `Regex`.
  ///
  /// The template string may be a literal string, or include template variables:
  /// the variable `$0` will be replaced with the entire matched substring, `$1`
  /// with the first capture group, etc.
  ///
  /// For example, to include the literal string "$1" in the replacement string,
  /// you must escape the "$": `\$1`.
  ///
  /// - requires: `pattern` is a valid regular expression. Invalid regular
  ///   expressions will cause this method to trap.
  ///
  /// - parameters:
  ///     - pattern: A regular expression pattern to match against `self`.
  ///     - template: A template string used to replace matches.
  ///
  /// - returns: A string with the first match of `pattern` replaced by `template`.
  public func replacingFirst(matching pattern: StaticString, with template: String) -> String {
    return replacingFirst(matching: Regex(pattern), with: template)
  }

  // MARK: Replacing all matches (mutating)
  /// Replace each substring matched by `regex` with `template`.
  ///
  /// The template string may be a literal string, or include template variables:
  /// the variable `$0` will be replaced with the entire matched substring, `$1`
  /// with the first capture group, etc.
  ///
  /// For example, to include the literal string "$1" in the replacement string,
  /// you must escape the "$": `\$1`.
  ///
  /// - parameters:
  ///     - regex: A regular expression to match against `self`.
  ///     - template: A template string used to replace matches.
  public mutating func replaceAll(matching regex: Regex, with template: String) {
    for match in regex.allMatches(in: self).reversed() {
      let replacement = regex
        .regularExpression
        .replacementString(
          for: match.matchResult,
          in: self,
          offset: 0,
          template: template
        )

      replaceSubrange(match.range, with: replacement)
    }
  }

  /// Replace each substring matched by the regular expression described in
  /// `pattern` with `template`.
  ///
  /// Convenience overload that accepts a `StaticString` instead of a `Regex`.
  ///
  /// The template string may be a literal string, or include template variables:
  /// the variable `$0` will be replaced with the entire matched substring, `$1`
  /// with the first capture group, etc.
  ///
  /// For example, to include the literal string "$1" in the replacement string,
  /// you must escape the "$": `\$1`.
  ///
  /// - requires: `pattern` is a valid regular expression. Invalid regular
  ///   expressions will cause this method to trap.
  ///
  /// - parameters:
  ///     - pattern: A regular expression pattern to match against `self`.
  ///     - template: A template string used to replace matches.
  public mutating func replaceAll(matching pattern: StaticString, with template: String) {
    replaceAll(matching: Regex(pattern), with: template)
  }

  // MARK: Replacing all matches (nonmutating)
  /// Returns a new string where each substring matched by `regex` is replaced
  /// with `template`.
  ///
  /// The template string may be a literal string, or include template variables:
  /// the variable `$0` will be replaced with the entire matched substring, `$1`
  /// with the first capture group, etc.
  ///
  /// For example, to include the literal string "$1" in the replacement string,
  /// you must escape the "$": `\$1`.
  ///
  /// - parameters:
  ///     - regex: A regular expression to match against `self`.
  ///     - template: A template string used to replace matches.
  ///
  /// - returns: A string with all matches of `regex` replaced by `template`.
  public func replacingAll(matching regex: Regex, with template: String) -> String {
    var string = self
    string.replaceAll(matching: regex, with: template)
    return string
  }

  /// Returns a new string where each substring matched by the regular
  /// expression described in `pattern` is replaced with `template`.
  ///
  /// Convenience overload that accepts a `StaticString` instead of a `Regex`.
  ///
  /// The template string may be a literal string, or include template variables:
  /// the variable `$0` will be replaced with the entire matched substring, `$1`
  /// with the first capture group, etc.
  ///
  /// For example, to include the literal string "$1" in the replacement string,
  /// you must escape the "$": `\$1`.
  ///
  /// - requires: `pattern` is a valid regular expression. Invalid regular
  ///   expressions will cause this method to trap.
  ///
  /// - parameters:
  ///     - pattern: A regular expression pattern to match against `self`.
  ///     - template: A template string used to replace matches.
  ///
  /// - returns: A string with all matches of `pattern` replaced by `template`.
  public func replacingAll(matching pattern: StaticString, with template: String) -> String {
    return replacingAll(matching: Regex(pattern), with: template)
  }
}

public extension String {
  @available(*, unavailable, renamed: "replaceFirst(matching:with:)")
  mutating func replaceFirstMatching(_: Regex, with _: String) {
    fatalError()
  }

  @available(*, unavailable, renamed: "replacingFirst(matching:with:)")
  func replacingFirstMatching(_: Regex, with _: String) -> String {
    fatalError()
  }

  @available(*, unavailable, renamed: "replaceFirst(matching:with:)")
  mutating func replaceFirstMatching(_: String, with _: String) {
    fatalError()
  }

  @available(*, unavailable, renamed: "replacingFirst(matching:with:)")
  func replacingFirstMatching(_: String, with _: String) -> String {
    fatalError()
  }

  @available(*, unavailable, renamed: "replaceAll(matching:with:)")
  mutating func replaceAllMatching(_: Regex, with _: String) {
    fatalError()
  }

  @available(*, unavailable, renamed: "replacingAll(matching:with:)")
  func replacingAllMatching(_: Regex, with _: String) -> String {
    fatalError()
  }

  @available(*, unavailable, renamed: "replaceAll(matching:with:)")
  mutating func replaceAllMatching(_: String, with _: String) {
    fatalError()
  }

  @available(*, unavailable, renamed: "replacingAll(matching:with:)")
  func replacingAllMatching(_: String, with _: String) -> String {
    fatalError()
  }
}

/// Convenience wrapper for generically storing values of type `T` in thread-local storage.
internal final class ThreadLocal<T> {
  let key: String

  init(_ key: String) {
    self.key = key
  }

  var value: T? {
    get {
      return Thread.current.threadDictionary[key] as? T
    }
    set {
      Thread.current.threadDictionary[key] = newValue
    }
  }
}
