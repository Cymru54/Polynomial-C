import Foundation

class Parser {
	private var tokens: [Token]
	private var position: Int = 0
	
	private func getPrecedence(for token: Token) -> Int {
		switch token {
		case .logicalOr: return 1
		case .logicalAnd: return 2
		case .equalEqual, .notEqual: return 3
		case .lessThan, .greaterThan, .lessEqual, .greaterEqual: return 4
		case .plus, .minus: return 5
		case .star, .slash, .modulo: return 6
		default: return 0
		}
	}
	
	init(tokens: [Token]) {
		self.tokens = tokens
	}
	
	private var currentToken: Token {
		guard position < tokens.count else { return .eof }
		return tokens[position]
	}
	
	private func advance() {
		position += 1
	}
	
	private func error(_ message: String) -> Never {
		fatalError("Parsing error: \(message)")
	}
	
	func parse() -> ProgramNode {
		var statements: [ASTNode] = []
		
		while currentToken != .eof {
			statements.append(parseStatement())
		}
		
		return ProgramNode(statements: statements)
	}
	
	private func parseStatement() -> ASTNode {
		if currentToken == .minus {
			advance(); guard currentToken == .openParen else { fatalError("Parsing error: '(' is required when declaring a method.") }; advance()
			guard case .keyword("void") = currentToken else { fatalError("Parsing error: Currently, only void return types are supported.") }; advance()
			guard currentToken == .closeParen else { fatalError("Parsing error: ')' is required.") }; advance()
			guard case .identifier(let funcName) = currentToken else { fatalError("Parsing error: Function name is required.") }; advance()
			let body = parseBlock()
			return FunctionDeclNode(name: funcName, body: body)
		}
		
		if currentToken == .openBrace {
			return parseBlock()
		}
		
		if case .keyword(let kw) = currentToken {
			if kw == "if" { return parseIfStatement() }
			if kw == "while" { return parseWhileStatement() }
			if kw == "async" { return parseAsyncStatement() }
			
			if ["const", "int", "float", "string", "bool", "array"].contains(kw) {
				let node = parseVariableDeclaration()
				expectSemicolon()
				return node
			}
		}
		
		if case .identifier(let varName) = currentToken {
			advance()
			
			if currentToken == .assign {
				advance()
				let valueNode = parseExpression()
				expectSemicolon()
				return AssignmentNode(name: varName, value: valueNode)
			} else {
				
			}
		}
		
		let node = parseExpression()
		expectSemicolon()
		return node
	}
	
	private func expectSemicolon() {
		if currentToken == .semicolon {
			advance()
		} else {
			fatalError("Parsing error: semicolon is missing at the end of the sentence. (current token: \(currentToken))")
		}
	}
	
	private func parseBlock() -> BlockNode {
		advance()
		var statements: [ASTNode] = []
		
		while currentToken != .closeBrace && currentToken != .eof {
			statements.append(parseStatement())
		}
		
		if currentToken == .closeBrace { advance() }
		else { fatalError("Parsing error: '}' closing block is missing.") }
		
		return BlockNode(statements: statements)
	}
	
	private func parseIfStatement() -> ASTNode {
		advance()
		
		guard currentToken == .openParen else { fatalError("Parsing error: if after that '(' is required.") }
		advance()
		let condition = parseExpression()
		guard currentToken == .closeParen else { fatalError("Parsing error: ')' is required after the conditional.") }
		advance()
		
		guard let thenBranch = parseBlock() as? BlockNode else { fatalError("Parsing error: block '{ }' is required after if condition.") }
		var elseBranch: BlockNode? = nil
		
		if currentToken == .keyword("else") {
			advance()
			guard let block = parseBlock() as? BlockNode else { fatalError("Parsing error: '{ }' block is required after else.") }
			elseBranch = block
		}
		
		return IfNode(condition: condition, thenBranch: thenBranch, elseBranch: elseBranch)
	}
	
	private func parseWhileStatement() -> ASTNode {
		advance()
		
		guard currentToken == .openParen else { fatalError("Parsing error: '(' is required after while.") }
		advance()
		let condition = parseExpression()
		guard currentToken == .closeParen else { fatalError("Parsing error: ')' is required after a conditional statement.") }
		advance()
		
		guard let body = parseBlock() as? BlockNode else { fatalError("Parsing error: block '{ }' is required after while condition.") }
		
		return WhileNode(condition: condition, body: body)
	}
	
	private func parseVariableDeclaration() -> ASTNode {
		var isConst = false
		
		if case .keyword("const") = currentToken {
			isConst = true
			advance()
		}
		
		guard case .keyword(let typeName) = currentToken else {
			fatalError("Parsing error: Variable data type is required.")
		}
		advance()
		
		guard case .identifier(let varName) = currentToken else {
			fatalError("Parsing error: Variable name is required.")
		}
		advance()
		
		guard currentToken == .assign else {
			fatalError("Parsing error: '=' sign is required when declaring a variable.")
		}
		advance()
		
		let valueNode = parseExpression()
		
		return VariableDeclarationNode(isConst: isConst, valueType: typeName, name: varName, value: valueNode)
	}
	
	private func parseExpression(precedence: Int = 0) -> ASTNode {
		var leftNode: ASTNode
		
		if currentToken == .logicalNot || currentToken == .minus {
			let opToken = currentToken
			advance()
			let rightNode = parseExpression(precedence: 7)
			leftNode = UnaryOpNode(operatorToken: opToken, right: rightNode)
		} else {
			leftNode = parsePrimary()
		}
		
		while precedence < getPrecedence(for: currentToken) {
			let opToken = currentToken
			advance()
			let nextPrecedence = getPrecedence(for: opToken)
			let rightNode = parseExpression(precedence: nextPrecedence)
			leftNode = BinaryOpNode(left: leftNode, operatorToken: opToken, right: rightNode)
		}
		
		return leftNode
	}
	
	private func parsePrimary() -> ASTNode {
		switch currentToken {
		case .openBracket: return parseMethodCall()
		case .identifier(let name): advance(); return IdentifierNode(name: name)
		case .intNumber(let val): advance(); return IntNode(value: val)
		case .floatNumber(let val): advance(); return FloatNode(value: val)
		case .stringLiteral(let val): advance(); return StringNode(value: val)
		case .boolean(let val): advance(); return BoolNode(value: val)
		case .atSign:
			advance(); guard currentToken == .openBracket else { fatalError("Parsing error: Array must start with @[.") }; advance()
			var elements: [ASTNode] = []
			if currentToken != .closeBracket {
				elements.append(parseExpression())
				while currentToken == .comma {
					advance()
					elements.append(parseExpression())
				}
			}
			guard currentToken == .closeBracket else { fatalError("Parsing error: Array closed to ] is not allowed.") }
			advance()
			return ArrayNode(elements: elements)
		default: fatalError("Parsing error: Unexpected token found during syntax analysis - \(currentToken)")
		}
	}
	
	private func parseMethodCall() -> ASTNode {
		advance()
		
		guard case .identifier(let receiverName) = currentToken else {
			error("The object name is required when calling the method.")
		}
		let receiver = IdentifierNode(name: receiverName)
		advance()
		
		guard case .identifier(let methodPart) = currentToken else {
			error("The method name is required.")
		}
		var methodName = methodPart
		advance()
		
		var arguments: [ASTNode] = []
		if currentToken == .colon {
			methodName += ":"
			advance()
			arguments.append(parseExpression())
		}
		
		if currentToken == .closeBracket {
			advance()
		} else {
			error("']' is missing at the end of the method call.")
		}
		
		return MethodCallNode(receiver: receiver, methodName: methodName, arguments: arguments)
	}
	
	private func parseAsyncStatement() -> ASTNode {
		advance()
		
		guard let body = parseBlock() as? BlockNode else {
			fatalError("Parsing error: async requires the block '{ }' to be executed after.")
		}
		
		return AsyncNode(body: body)
	}
}
