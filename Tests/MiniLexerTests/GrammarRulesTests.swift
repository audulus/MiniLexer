import XCTest
@testable import MiniLexer

public class GrammarRuleTests: XCTestCase {
    
    func testGrammarRuleDigit() throws {
        let rule = GrammarRule.digit
        let lexer = Lexer(input: "123")
        let lexer2 = Lexer(input: "abc")
        
        XCTAssert(rule.canConsume(from: lexer))
        XCTAssertFalse(rule.canConsume(from: lexer2))
        XCTAssertEqual("1", try rule.consume(from: lexer))
        XCTAssertEqual("[0-9]", rule.ruleDescription)
    }
    
    func testGrammarRuleLetter() throws {
        let rule = GrammarRule.letter
        let lexer = Lexer(input: "abc")
        let lexer2 = Lexer(input: "1")
        
        XCTAssert(rule.canConsume(from: lexer))
        XCTAssertFalse(rule.canConsume(from: lexer2))
        XCTAssertEqual("a", try rule.consume(from: lexer))
        XCTAssertEqual("[a-zA-Z]", rule.ruleDescription)
    }
    
    func testGrammarRuleWhitespace() throws {
        let rule = GrammarRule.whitespace
        let lexer = Lexer(input: " ")
        let lexer2 = Lexer(input: "1")
        
        XCTAssert(rule.canConsume(from: lexer))
        XCTAssertFalse(rule.canConsume(from: lexer2))
        XCTAssertEqual(" ", try rule.consume(from: lexer))
        XCTAssertEqual("[\\s\\t\\r\\n]", rule.ruleDescription)
    }
    
    func testGrammarRuleChar() throws {
        let rule = GrammarRule.char("@")
        let lexer1 = Lexer(input: "@test")
        let lexer2 = Lexer(input: " @test")
        let lexer3 = Lexer(input: "test")
        let lexer4 = Lexer(input: "")
        
        XCTAssertEqual("@", try rule.consume(from: lexer1))
        XCTAssertEqual("@", try rule.consume(from: lexer2))
        XCTAssertThrowsError(try rule.consume(from: lexer3))
        XCTAssertThrowsError(try rule.consume(from: lexer4))
        XCTAssertEqual("'@'", rule.ruleDescription)
    }
    
    func testGrammarRuleKeyword() throws {
        let rule = GrammarRule.keyword("test")
        let lexer1 = Lexer(input: "test")
        let lexer2 = Lexer(input: " test test")
        let lexer3 = Lexer(input: "tes")
        let lexer4 = Lexer(input: "testtest")
        
        XCTAssertEqual("test", try rule.consume(from: lexer1))
        XCTAssertEqual("test", try rule.consume(from: lexer2))
        XCTAssertThrowsError(try rule.consume(from: lexer3))
        XCTAssertEqual("test", try rule.consume(from: lexer4))
        XCTAssertEqual("test", rule.ruleDescription)
    }
    
    func testGrammarNamedRule() throws {
        let rule = GrammarRule.namedRule(name: "number", .digit+)
        let lexer1 = Lexer(input: "123")
        let lexer2 = Lexer(input: "a")
        
        XCTAssertEqual("123", try rule.consume(from: lexer1))
        XCTAssertThrowsError(try rule.consume(from: lexer2))
        XCTAssertEqual("number", rule.ruleDescription)
    }
    
    func testGrammarRuleOneOrMore() throws {
        let rule = GrammarRule.oneOrMore(.digit)
        let lexer1 = Lexer(input: "123")
        let lexer2 = Lexer(input: "a")
        
        XCTAssertEqual("123", try rule.consume(from: lexer1))
        XCTAssertThrowsError(try rule.consume(from: lexer2))
        XCTAssertEqual("[0-9]+", rule.ruleDescription)
    }
    
    func testGrammarRuleZeroOrMore() throws {
        let rule = GrammarRule.zeroOrMore(.digit)
        let lexer1 = Lexer(input: "123")
        let lexer2 = Lexer(input: "a")
        
        XCTAssertEqual("123", try rule.consume(from: lexer1))
        XCTAssertEqual("", try rule.consume(from: lexer2))
        XCTAssertEqual("[0-9]*", rule.ruleDescription)
    }
    
    func testGrammarRuleOr() throws {
        let rule = GrammarRule.or([.digit, .letter])
        let lexer = Lexer(input: "a1")
        
        XCTAssertEqual("a", try rule.consume(from: lexer))
        XCTAssertEqual("1", try rule.consume(from: lexer))
        XCTAssertEqual("[0-9] | [a-zA-Z]", rule.ruleDescription)
    }
    
    func testGramarRuleOrStopsAtFirstMatchFound() throws {
        // test:
        //   ('@keyword' [0-9]+) | ('@keyword' 'abc') | ('@keyword' | 'a')
        //
        // ident:
        //   [a-zA-Z] [a-zA-Z0-9]*
        //
        // number:
        //   [0-9]+
        //
        
        let test =
            (.keyword("@keyword") .. .digit+) | (.keyword("@keyword") .. .keyword("abc")) | (.keyword("@keyword") .. "a")
        
        let lexer1 = Lexer(input: "@keyword 123")
        let lexer2 = Lexer(input: "@keyword abc")
        let lexer3 = Lexer(input: "@keyword a")
        let lexer4 = Lexer(input: "@keyword _abc")
        
        XCTAssertEqual("@keyword 123", try test.consume(from: lexer1))
        XCTAssertEqual("@keyword abc", try test.consume(from: lexer2))
        XCTAssertEqual("@keyword a", try test.consume(from: lexer3))
        XCTAssertThrowsError(try test.consume(from: lexer4))
    }
    
    func testGrammarRuleOneOrMoreOr() throws {
        let rule = GrammarRule.oneOrMore(.or([.digit, .letter]))
        let lexer1 = Lexer(input: "ab123")
        let lexer2 = Lexer(input: "ab 123")
        
        XCTAssertEqual("ab123", try rule.consume(from: lexer1))
        XCTAssertEqual("ab", try rule.consume(from: lexer2))
        XCTAssertEqual("([0-9] | [a-zA-Z])+", rule.ruleDescription)
    }
    
    func testGrammarRuleOptional() throws {
        let rule = GrammarRule.optional(.digit)
        let lexer1 = Lexer(input: "12")
        let lexer2 = Lexer(input: "")
        
        XCTAssertEqual("1", try rule.consume(from: lexer1))
        XCTAssertEqual("", try rule.consume(from: lexer2))
        XCTAssertEqual("[0-9]?", rule.ruleDescription)
    }
    
    func testGrammarRuleOptionalRuleDescriptionWithMany() throws {
        XCTAssertEqual("[0-9]?", GrammarRule.optional(.digit).ruleDescription)
        XCTAssertEqual("([0-9])?", GrammarRule.optional(.sequence([.digit])).ruleDescription)
        XCTAssertEqual("([0-9] [a-zA-Z])?", GrammarRule.optional(.sequence([.digit, .letter])).ruleDescription)
        XCTAssertEqual("([0-9][a-zA-Z])?", GrammarRule.optional(.directSequence([.digit, .letter])).ruleDescription)
    }
    
    func testGrammarRuleSequence() throws {
        let rule = GrammarRule.sequence([.letter, .digit])
        let lexer1 = Lexer(input: "a 1")
        let lexer2 = Lexer(input: "aa 2")
        
        XCTAssert(rule.canConsume(from: lexer1))
        XCTAssert(rule.canConsume(from: lexer2))
        XCTAssertEqual("a 1", try rule.consume(from: lexer1))
        XCTAssertThrowsError(try rule.consume(from: lexer2))
        XCTAssertEqual("[a-zA-Z] [0-9]", rule.ruleDescription)
    }
    
    func testGrammarRuleDirectSequence() throws {
        let rule = GrammarRule.directSequence([.letter, .digit])
        let lexer1 = Lexer(input: "a1")
        let lexer2 = Lexer(input: "a 1")
        let lexer3 = Lexer(input: "aa2")
        let lexer4 = Lexer(input: " a2")
        
        XCTAssert(rule.canConsume(from: lexer1))
        XCTAssert(rule.canConsume(from: lexer2)) // TODO: these two could be easy to check as false,
        XCTAssert(rule.canConsume(from: lexer3)) // should we ignore possible recursions and do it anyway?
        XCTAssertFalse(rule.canConsume(from: lexer4))
        XCTAssertEqual("a1", try rule.consume(from: lexer1))
        XCTAssertThrowsError(try rule.consume(from: lexer2))
        XCTAssertThrowsError(try rule.consume(from: lexer3))
        XCTAssertEqual("[a-zA-Z][0-9]", rule.ruleDescription)
    }
    
    func testGrammarRecursive() throws {
        // Test a recursive rule as follows:
        //
        // argList:
        //   arg (',' argList)*
        //
        // arg:
        //   ident
        //
        // ident:
        //   [a-zA-Z]+
        //
        
        // Arrange
        let ident: GrammarRule = .namedRule(name: "ident", .letter+)
        let arg: GrammarRule = .namedRule(name: "arg", ident)
        
        let argList = RecursiveGrammarRule(ruleName: "argList", rule: .digit)
        let recArg = GrammarRule.recursive(argList)
        
        argList.setRule(rule: [arg, [",", recArg]* ])
        
        let lexer1 = Lexer(input: "abc, def, ghi")
        // let lexer2 = Lexer(input: "abc, def,")
        
        // Act
        let result = try argList.consume(from: lexer1)
        
        // Assert
        // XCTAssertThrowsError(try argList.consume(from: lexer2)) // TODO: Should this error or not?
        XCTAssertEqual("abc, def, ghi", result)
        XCTAssertEqual("arg (',' argList)*", argList.ruleDescription)
    }
    
    func testGrammarRuleOperatorZeroOrMore() {
        let rule = GrammarRule.digit
        let zeroOrMore = rule*
        
        switch zeroOrMore {
        case .zeroOrMore:
            // Success!
            break
        default:
            XCTFail("Expected '*' operator to compose as .zeroOrMore")
        }
    }
    
    func testGrammarRuleOperatorZeroOrMoreOnArray() {
        let rule: [GrammarRule] = [.digit, .letter]
        let zeroOrMore = rule*
        
        switch zeroOrMore {
        case .zeroOrMore(.sequence):
            // Success!
            break
        default:
            XCTFail("Expected '*' operator on array of rules to compose as .zeroOrMore(.sequence)")
        }
    }
    
    func testGrammarRuleOperatorOneOrMore() {
        let rule = GrammarRule.digit
        let oneOrMore = rule+
        
        switch oneOrMore {
        case .oneOrMore:
            // Success!
            break
        default:
            XCTFail("Expected '+' operator to compose as .oneOrMore")
        }
    }
    
    func testGrammarRuleOperatorOneOrMoreOnArray() {
        let rule: [GrammarRule] = [.digit, .letter]
        let oneOrMore = rule+
        
        switch oneOrMore {
        case .oneOrMore(.sequence):
            // Success!
            break
        default:
            XCTFail("Expected '+' operator on array of rules to compose as .oneOrMore(.sequence)")
        }
    }
    
    func testGrammarRuleOperatorOr() {
        let rule1 = GrammarRule.digit
        let rule2 = GrammarRule.letter
        let oneOrMore = rule1 | rule2
        
        switch oneOrMore {
        case .or(let ar):
            XCTAssertEqual(ar.count, 2)
            
            if case .digit = ar[0], case .letter = ar[1] {
                // Success!
                return
            }
            
            XCTFail("Failed to generate proper OR operands")
            break
        default:
            XCTFail("Expected '+' operator to compose as .oneOrMore")
        }
    }
    
    func testGrammarRuleOperatorOrCollapseSequential() {
        let oneOrMore: GrammarRule = .digit | .letter | .char("@")
        
        switch oneOrMore {
        case .or(let ar):
            XCTAssertEqual(ar.count, 3)
            
            if case .digit = ar[0], case .letter = ar[1], case .char("@") = ar[2] {
                // Success!
                return
            }
            
            XCTFail("Failed to generate proper OR operands")
            break
        default:
            XCTFail("Expected '+' operator to compose as .oneOrMore")
        }
    }
    
    func testGrammarRuleOperatorSequence() {
        let rule1 = GrammarRule.digit
        let rule2 = GrammarRule.letter
        let oneOrMore = rule1 .. rule2
        
        switch oneOrMore {
        case .sequence(let ar):
            XCTAssertEqual(ar.count, 2)
            
            if case .digit = ar[0], case .letter = ar[1] {
                // Success!
                return
            }
            
            XCTFail("Failed to generate proper sequence operands")
            break
        default:
            XCTFail("Expected '..' operator to compose as .sequence")
        }
    }
    
    func testGrammarRuleOperatorSequenceCollapseSequential() {
        let oneOrMore: GrammarRule = .digit .. .letter .. .char("@")
        
        switch oneOrMore {
        case .sequence(let ar):
            XCTAssertEqual(ar.count, 3)
            
            if case .digit = ar[0], case .letter = ar[1], case .char("@") = ar[2] {
                // Success!
                return
            }
            
            XCTFail("Failed to generate proper sequence operands")
            break
        default:
            XCTFail("Expected '..' operator to compose as .sequence")
        }
    }
    
    func testRecursiveGrammarRuleCreate() throws {
        let rule = RecursiveGrammarRule.create(named: "list") { (rec) -> GrammarRule in
            return .sequence([.letter, [",", .recursive(rec)]*])
        }
        
        let lexer1 = Lexer(input: "a, b, c")
        let lexer2 = Lexer(input: ", , b")
        
        XCTAssertEqual("a, b, c", try rule.consume(from: lexer1))
        XCTAssertThrowsError(try rule.consume(from: lexer2))
    }
    
    func testRecursiveGrammarRuleDescription() {
        let rule1 = RecursiveGrammarRule(ruleName: "rule_rec1", rule: .digit)
        let rule2 = RecursiveGrammarRule(ruleName: "rule_rec2", rule: .recursive(rule1))
        
        XCTAssertEqual("[0-9]", rule1.ruleDescription)
        XCTAssertEqual("rule_rec1", rule2.ruleDescription)
    }
    
    func testGrammarRuleComplexNonRecursive() throws {
        // Tests a fully flexed complex grammar for a list of items enclosed
        // within parens, avoiding a recursive rule
        //
        // propertyModifierList:
        //   '(' modifierList ')'
        //
        // modifierList:
        //   modifier (',' modifier)*
        //
        // modifier:
        //   ident
        //
        // ident:
        //   [a-zA-Z_] [a-zA-Z_0-9]*
        //
        
        // Arrange
        let ident: GrammarRule = [.letter | "_", (.letter | "_" | .digit)*]
        let modifier: GrammarRule = .namedRule(name: "modifier", ident)
        
        let modifierList: GrammarRule =
            modifier .. ("," .. modifier)*
        
        let propertyModifierList: GrammarRule = ["(", modifierList, ")"]
        
        let lexer1 = Lexer(input: "(mod1, mod2)")
        let lexer2 = Lexer(input: "(mod1, )")
        
        // Act/assert
        XCTAssertEqual("(mod1, mod2)", try propertyModifierList.consume(from: lexer1))
        XCTAssertThrowsError(try propertyModifierList.consume(from: lexer2))
    }
    
    func testGrammarRuleComplexRecursive() throws {
        // Tests a fully flexed complex grammar for a list of items enclosed
        // within parens, including a recursive rule
        //
        // propertyModifierList:
        //   '(' modifierList ')'
        //
        // modifierList:
        //   modifier (',' modifier)*
        //
        // modifier:
        //   ident
        //
        // ident:
        //   [a-zA-Z_] [a-zA-Z_0-9]*
        //
        
        // Arrange
        let ident: GrammarRule =
            (.letter | "_") .. (.letter | "_" | .digit)*
        let modifier: GrammarRule =
            .namedRule(name: "modifier", ident)
        
        let modifierList = RecursiveGrammarRule.create(named: "modifierList") {
            .sequence([modifier, [",", .recursive($0)]*])
        }
        
        let propertyModifierList =
            "(" .. modifierList .. ")"
        
        let lexer1 = Lexer(input: "(mod1, mod2)")
        let lexer2 = Lexer(input: "()")
        let lexer3 = Lexer(input: "(mod1, )")
        let lexer4 = Lexer(input: "(mod1, ")
        let lexer5 = Lexer(input: "( ")
        
        // Act/assert
        XCTAssertEqual("(mod1, mod2)", try propertyModifierList.consume(from: lexer1))
        XCTAssertThrowsError(try propertyModifierList.consume(from: lexer2))
        XCTAssertThrowsError(try propertyModifierList.consume(from: lexer3))
        XCTAssertThrowsError(try propertyModifierList.consume(from: lexer4))
        XCTAssertThrowsError(try propertyModifierList.consume(from: lexer5))
    }
    
    func testGrammarRuleComplexRecursiveWithLookaheadWithKeyword() throws {
        // Tests a recursive lookahead parsing
        //
        // propertyModifierList:
        //   '(' modifierList ')'
        //
        // modifierList:
        //   modifier (',' modifier)*
        //
        // modifier:
        //   compound
        //
        // compound:
        //   ('@keyword' 'abc') | ('@keyword' number) | ('@keyword' | 'a')
        //
        // number:
        //   [0-9]+
        //
        
        // Arrange
        let number: GrammarRule =
            .digit+
        
        let compound =
            (.keyword("@keyword") .. .keyword("abc")) | (.keyword("@keyword") .. number) | (.keyword("@keyword") .. "a")
        
        let modifier: GrammarRule =
            .namedRule(name: "modifier", compound)
        
        let modifierList = RecursiveGrammarRule.create(named: "modifierList") {
            modifier .. ("," .. .recursive($0))*
        }
        
        let propertyModifierList =
            "(" .. modifierList .. ")"
        
        let lexer1 = Lexer(input: "(@keyword 123, @keyword abc, @keyword a)")
        let lexer2 = Lexer(input: "(@keyword mod, @keyword 123, @keyword a, @keyword abc)")
        let lexer3 = Lexer(input: "(@keyword ace)")
        let lexer4 = Lexer(input: "(@keyword b)")
        let lexer5 = Lexer(input: "(mod1, ")
        let lexer6 = Lexer(input: "( ")
        
        // Act/assert
        XCTAssertEqual("(@keyword 123, @keyword abc, @keyword a)", try propertyModifierList.consume(from: lexer1))
        XCTAssertThrowsError(try propertyModifierList.consume(from: lexer2))
        XCTAssertThrowsError(try propertyModifierList.consume(from: lexer3))
        XCTAssertThrowsError(try propertyModifierList.consume(from: lexer4))
        XCTAssertThrowsError(try propertyModifierList.consume(from: lexer5))
        XCTAssertThrowsError(try propertyModifierList.consume(from: lexer6))
    }
    
    func testGramarRuleLookahead() throws {
        // test:
        //   ('a' ident) | ('a' number) | ('a' | '@keyword')
        //
        // ident:
        //   [a-zA-Z] [a-zA-Z0-9]*
        //
        // number:
        //   [0-9]+
        //
        
        let number: GrammarRule =
            .digit+
        
        let ident: GrammarRule =
            (.letter) .. (.letter | .digit)*
        
        let test =
            ("a" .. ident) | ("a" .. number) | ("a" .. .keyword("@keyword"))
        
        let lexer1 = Lexer(input: "a 123")
        let lexer2 = Lexer(input: "a abc")
        let lexer3 = Lexer(input: "a @keyword")
        let lexer4 = Lexer(input: "a _abc")
        
        XCTAssertEqual("a 123", try test.consume(from: lexer1))
        XCTAssertEqual("a abc", try test.consume(from: lexer2))
        XCTAssertEqual("a @keyword", try test.consume(from: lexer3))
        XCTAssertThrowsError(try test.consume(from: lexer4))
    }
    
    func testGramarRuleLookaheadWithKeyword() throws {
        // test:
        //   ('@keyword' ident) | ('@keyword' number) | ('@keyword' | '@a')
        //
        // ident:
        //   [a-zA-Z] [a-zA-Z0-9]*
        //
        // number:
        //   [0-9]+
        //
        
        let number: GrammarRule =
            .digit+
        
        let ident: GrammarRule =
            (.letter) .. (.letter | .digit)*
        
        let test =
            (.keyword("@keyword") .. ident) | (.keyword("@keyword") .. number) | (.keyword("@keyword") .. "a")
        
        let lexer1 = Lexer(input: "@keyword 123")
        let lexer2 = Lexer(input: "@keyword abc")
        let lexer3 = Lexer(input: "@keyword a")
        let lexer4 = Lexer(input: "@keyword _abc")
        
        XCTAssertEqual("@keyword 123", try test.consume(from: lexer1))
        XCTAssertEqual("@keyword abc", try test.consume(from: lexer2))
        XCTAssertEqual("@keyword a", try test.consume(from: lexer3))
        XCTAssertThrowsError(try test.consume(from: lexer4))
    }
    
    func testGrammarRulePerformance() {
        // With non-recursive modifierList
        
        // propertyModifierList:
        //   '(' modifierList ')'
        //
        // modifierList:
        //   modifier (',' modifier)*
        //
        // modifier:
        //   ident
        //
        // ident:
        //   [a-zA-Z_] [a-zA-Z_0-9]*
        //
        
        let ident: GrammarRule =
            (.letter | "_") .. (.letter | "_" | .digit)*
        let modifier: GrammarRule =
            .namedRule(name: "modifier", ident)
        
        let modifierList =
            modifier .. ("," .. modifier)*
        
        let propertyModifierList =
            "(" .. modifierList .. ")"
        
        measure {
            for _ in 0...100 {
                let lexer = Lexer(input: "(mod1, mod2, mod3, mod4, mod5, mod6, mod7, mod8, mod9, mod10)")
                _=try! propertyModifierList.consume(from: lexer)
            }
        }
    }
    
    func testGrammarRuleRecursivePerformance() {
        // With recursive modifierList
        
        // propertyModifierList:
        //   '(' modifierList ')'
        //
        // modifierList:
        //   modifier (',' modifierList)*
        //
        // modifier:
        //   ident
        //
        // ident:
        //   [a-zA-Z_] [a-zA-Z_0-9]*
        //
        
        let ident: GrammarRule =
            (.letter | "_") .. (.letter | "_" | .digit)*
        
        let modifier: GrammarRule =
            .namedRule(name: "modifier", ident)
        
        let modifierList = RecursiveGrammarRule.create(named: "modifierList") {
            modifier .. ("," .. .recursive($0))*
        }
        
        let propertyModifierList =
            "(" .. modifierList .. ")"
        
        measure {
            for _ in 0...100 {
                let lexer = Lexer(input: "(mod1, mod2, mod3, mod4, mod5, mod6, mod7, mod8, mod9, mod10)")
                _=try! propertyModifierList.consume(from: lexer)
            }
        }
    }
}
