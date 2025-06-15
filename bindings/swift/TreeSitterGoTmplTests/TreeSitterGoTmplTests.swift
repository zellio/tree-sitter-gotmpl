import XCTest
import SwiftTreeSitter
import TreeSitterGotmpl

final class TreeSitterGotmplTests: XCTestCase {
    func testCanLoadGrammar() throws {
        let parser = Parser()
        let language = Language(language: tree_sitter_gotmpl())
        XCTAssertNoThrow(try parser.setLanguage(language),
                         "Error loading Go Template grammar")
    }
}
