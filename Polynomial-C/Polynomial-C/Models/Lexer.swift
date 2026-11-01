import Foundation

enum Token: Equatable {
	case openBracket, closeBracket, colon, semicolon, eof
	case plus, minus, star, slash, modulo
	case equalEqual, notEqual, lessThan, greaterThan, lessEqual, greaterEqual
	case logicalAnd, logicalOr, logicalNot
	case openParen, closeParen
	case openBrace, closeBrace
	case comma, atSign
	case assign
	case keyword(String)
	case identifier(String)
	case intNumber(Int)
	case floatNumber(Float)
	case stringLiteral(String)
	case boolean(Bool)
}

class Lexer {
	private var input: [Character]
	private var position: Int = 0
	
	init(input: String) {
		self.input = Array(input)
	}
	
	private var currentChar: Character? {
		guard position < input.count else { return nil }
		return input[position]
	}
	
	private func advance() {
		position += 1
	}
	
	private func skipWhitespace() {
		while let char = currentChar, char.isWhitespace {
			advance()
		}
	}
	
	private func readIdentifier() -> String {
		var result = ""
		while let char = currentChar, char.isLetter || char.isNumber || char == "_" {
			result.append(char)
			advance()
		}
		return result
	}
	
	private func readNumber() -> Float {
		var result = ""
		while let char = currentChar, char.isNumber || char == "." {
			result.append(char)
			advance()
		}
		return Float(result) ?? 0.0
	}
	
	func tokenize() -> [Token] {
		var tokens: [Token] = []
		
		while let char = currentChar {
			if char.isWhitespace {
				skipWhitespace()
				continue
			}
			
			if char == "\"" {
				tokens.append(.stringLiteral(readString()))
				continue
			}
			
			if char.isLetter {
				let text = readIdentifier()
				tokens.append(identifierOrKeyword(text))
				continue
			}
			
			if char.isNumber {
				tokens.append(readNumberToken())
				continue
			}
			
			switch char {
			case "[": tokens.append(.openBracket); advance()
			case "]": tokens.append(.closeBracket); advance()
			case ":": tokens.append(.colon); advance()
			case ";": tokens.append(.semicolon); advance()
			case "+": tokens.append(.plus); advance()
			case "-": tokens.append(.minus); advance()
			case "*": tokens.append(.star); advance()
			case "%": tokens.append(.modulo); advance()
			case "(": tokens.append(.openParen); advance()
			case ")": tokens.append(.closeParen); advance()
			case "{": tokens.append(.openBrace); advance()
			case "}": tokens.append(.closeBrace); advance()
			case ",": tokens.append(.comma); advance()
			case "@": tokens.append(.atSign); advance()
			case "/":
				if peekChar == "/" {
					while let c = currentChar, c != "\n" { advance() }
					continue
				} else if peekChar == "*" {
					advance(); advance()
					while let c = currentChar {
						if c == "*" && peekChar == "/" { advance(); advance(); break }
					}
					continue
				} else {
					tokens.append(.slash); advance()
				}
			case "=":
				if peekChar == "=" { tokens.append(.equalEqual); advance(); advance() }
				else { tokens.append(.assign); advance() }
			case "!":
				if peekChar == "=" { tokens.append(.notEqual); advance(); advance() }
				else { tokens.append(.logicalNot); advance() }
			case "<":
				if peekChar == "=" { tokens.append(.lessEqual); advance(); advance() }
				else { tokens.append(.lessThan); advance() }
			case ">":
				if peekChar == "=" { tokens.append(.greaterEqual); advance(); advance() }
				else { tokens.append(.greaterThan) }
			case "&":
				if peekChar == "&" { tokens.append(.logicalAnd); advance(); advance() }
				else { advance() }
			case "|":
				if peekChar == "|" { tokens.append(.logicalOr); advance(); advance() }
				else { advance() }
			default:
				advance()
			}
		}
		
		tokens.append(.eof)
		return tokens
	}
	
	private func identifierOrKeyword(_ text: String) -> Token {
		let keywords = ["const", "int", "float", "string", "bool", "if", "else", "while", "array", "void", "async"]
		if keywords.contains(text) { return .keyword(text) }
		if text == "true" { return .boolean(true) }
		if text == "false" { return .identifier(text) }
		
		return .identifier(text)
	}
	
	private func readString() -> String {
		advance()
		var result = ""
		while let char = currentChar, char != "\"" {
			result.append(char)
			advance()
		}
		advance()
		return result
	}
	
	private func readNumberToken() -> Token {
		var result = ""
		var isFloat = false
		
		while let char = currentChar, char.isNumber || char == "." {
			if char == "." { isFloat = true }
			result.append(char)
			advance()
		}
		
		if isFloat {
			return .floatNumber(Float(result) ?? 0.0)
		} else {
			return .intNumber(Int(result) ?? 0)
		}
	}
	
	private var peekChar: Character? {
		guard position + 1 < input.count else { return nil }
		return input[position + 1]
	}
}
