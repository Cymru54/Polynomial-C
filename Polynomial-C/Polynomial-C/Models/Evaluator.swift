import Foundation

enum PolyValue {
	case int(Int)
	case float(Float)
	case string(String)
	case bool(Bool)
	case array([PolyValue])
	case none
	
	var asFloat: Float {
		if case .float(let f) = self { return f }
		if case .int(let i) = self { return Float(i) }
		return 0.0
	}
	
	var asInt: Int {
		if case .int(let i) = self { return i }
		if case .float(let f) = self { return Int(f) }
		return 0
	}
	
	var asBool: Bool {
		if case .bool(let b) = self { return b }
		return false
	}
	
	var isFloat: Bool { if case .float = self { return true }; return false }
	
	var description: String {
		switch self {
		case .int(let v): return "\(v) (int)"
		case .float(let v): return "\(v) (float)"
		case .string(let v): return "\"\(v)\" (string)"
		case .bool(let v): return "\(v) (bool)"
		case .array(let arr):
			let strElements = arr.map { $0.description }.joined(separator: ", ")
			return "@[ \(strElements) ]"
		case .none: return "none"
		}
	}
}

class Evaluator {
	private let engine: EngineManager
	private var environment = Environment()
	
	init(engine: EngineManager) {
		self.engine = engine
	}
	
	func evaluate(_ node: ASTNode) {
		guard engine.isRunning else { return }
		
		if let program = node as? ProgramNode {
			for statement in program.statements { evaluate(statement) }
		} else if let blockNode = node as? BlockNode {
			for statement in blockNode.statements { evaluate(statement) }
		} else if let ifNode = node as? IfNode {
			let conditionResult = evaluateExpression(ifNode.condition)
			if conditionResult.asBool {
				evaluate(ifNode.thenBranch)
			} else if let elseB = ifNode.elseBranch {
				evaluate(elseB)
			}
		} else if let whileNode = node as? WhileNode {
			var safetyCounter = 0
			let maxIterations = 10000
			
			while evaluateExpression(whileNode.condition).asBool {
				evaluate(whileNode.body)
				safetyCounter += 1
				
				if safetyCounter >= maxIterations {
					print("[AFXLog] SYSTEM OVERLOAD: Infinite loop detected! For hardware protection, forcibly exit while loop.")
					break
				}
			}
		} else if let asyncNode = node as? AsyncNode {
			DispatchQueue.global(qos: .userInitiated).async {
				self.evaluate(asyncNode.body)
			}
		} else if let methodCall = node as? MethodCallNode {
			executeMethod(methodCall)
		} else if let varDecl = node as? VariableDeclarationNode {
			executeVariableDeclaration(varDecl)
		} else if let assignNode = node as? AssignmentNode {
			let evaluatedValue = evaluateExpression(assignNode.value)
			environment.assign(name: assignNode.name, value: evaluatedValue)
		} else if let funcNode = node as? FunctionDeclNode {
			environment.defineFunction(name: funcNode.name, node: funcNode)
		}
	}
	
	private func executeVariableDeclaration(_ node: VariableDeclarationNode) {
		let evaluatedValue = evaluateExpression(node.value)
		environment.define(name: node.name, value: evaluatedValue, isConst: node.isConst)
	}
	
	private func executeMethod(_ node: MethodCallNode) {
		let receiverName = node.receiver.name
		
		switch receiverName {
		case "self":
			if node.methodName == "wait:" {
				if let firstArg = node.arguments.first {
					let waitTime = evaluateExpression(firstArg).asFloat
					Thread.sleep(forTimeInterval: TimeInterval(waitTime))
				}
			} else {
				let cleanMethodName = node.methodName.replacingOccurrences(of: ":", with: "")
				if let funcNode = environment.getFunction(name: cleanMethodName) {
					evaluate(funcNode.body)
				} else {
					print("[AFXLog] Error: It is an undeclared function - \(cleanMethodName)")
				}
			}
			
		case "sampler":
			var argValue: PolyValue = .none
			if let firstArg = node.arguments.first {
				argValue = evaluateExpression(firstArg)
			}
			
			switch node.methodName {
			case "play:":
				if case .string(let sampleName) = argValue {
					engine.playSample(name: sampleName)
				} else {
					print("play: Method requires a string file name.")
				}
			case "setRate:":
				if case .float(let r) = argValue {
					engine.setSamplerRate(r)
				} else if case .int(let i) = argValue {
					engine.setSamplerRate(Float(i))
				} else {
					print("[AFXLog] setRate: Method requires a number (int, float).")
				}
			default:
				print("[AFXLog] Unknown Selector: -[sampler \(node.methodName)]")
			}
			
		case "tb303":
			var argumentFloat: Float = 0.0
			if let firstArg = node.arguments.first {
				let polyValue = evaluateExpression(firstArg)
				if case .float(let f) = polyValue {
					argumentFloat = f
				} else if case .int(let i) = polyValue {
					argumentFloat = Float(i)
				} else {
					if node.methodName != "release" && node.methodName != "play" {
						return
					}
				}
			}
			
			switch node.methodName {
			case "setFrequency:": engine.setFrequency(argumentFloat)
			case "setCutoff:": engine.setCutoff(argumentFloat)
			case "setResonance:": engine.setResonance(argumentFloat)
			case "release": engine.stopAll()
			case "play": engine.play303()
			default: break
			}
			
		default:
			print("Unknown Receiver: \(receiverName) object could not be found.")
		}
	}
	
	private func evaluateExpression(_ node: ASTNode) -> PolyValue {
		if let intNode = node as? IntNode {
			return .int(intNode.value)
		} else if let floatNode = node as? FloatNode {
			return .float(floatNode.value)
		} else if let stringNode = node as? StringNode {
			return .string(stringNode.value)
		} else if let boolNode = node as? BoolNode {
			return .bool(boolNode.value)
		} else if let idNode = node as? IdentifierNode {
			if let value = environment.get(name: idNode.name) {
				return value
			} else {
				print("[AFXLog] Reference error: undefined identifier '\(idNode.name)'")
				return .none
			}
		} else if let binaryNode = node as? BinaryOpNode {
			let leftVal = evaluateExpression(binaryNode.left)
			let rightVal = evaluateExpression(binaryNode.right)
			return executeBinaryOperation(left: leftVal, op: binaryNode.operatorToken, right: rightVal)
		} else if let unaryNode = node as? UnaryOpNode {
			let rightVal = evaluateExpression(unaryNode.right)
			return executeUnaryOperation(op: unaryNode.operatorToken, right: rightVal)
		} else if let arrayNode = node as? ArrayNode {
			let evaluatedElements = arrayNode.elements.map { evaluateExpression($0) }
			return .array(evaluatedElements)
		}
		return .none
	}
	
	private func executeBinaryOperation(left: PolyValue, op: Token, right: PolyValue) -> PolyValue {
		let isFloatMath = (left.isFloat || right.isFloat)
		let lf = left.asFloat, rf = right.asFloat
		let li = left.asInt, ri = right.asInt
		
		switch op {
		case .plus: return isFloatMath ? .float(lf + rf) : .int(li + ri)
		case .minus: return isFloatMath ? .float(lf - rf) : .int(li - ri)
		case .star: return isFloatMath ? .float(lf * rf) : .int(li * ri)
		case .slash: return isFloatMath ? .float(lf / (rf == 0 ? 1 : rf)) : .int(li / (ri == 0 ? 1 : ri))
		case .modulo: return .int(li % (ri == 0 ? 1 : ri))
		case .equalEqual: return isFloatMath ? .bool(lf == rf) : .bool(li == ri)
		case .notEqual: return isFloatMath ? .bool(lf != rf) : .bool(li != ri)
		case .lessThan: return isFloatMath ? .bool(lf < rf) : .bool(li < ri)
		case .greaterThan: return isFloatMath ? .bool(lf > rf) : .bool(li > ri)
		case .lessEqual: return isFloatMath ? .bool(lf <= rf) : .bool(li <= ri)
		case .greaterEqual: return isFloatMath ? .bool(lf >= rf) : .bool(li >= ri)
		case .logicalAnd: return .bool(left.asBool && right.asBool)
		case .logicalOr: return .bool(left.asBool || right.asBool)
		default: return .none
		}
	}
	
	private func executeUnaryOperation(op: Token, right: PolyValue) -> PolyValue {
		if op == .minus {
			return right.isFloat ? .float(-right.asFloat) : .int(-right.asInt)
		} else if op == .logicalNot {
			return .bool(!right.asBool)
		}
		return right
	}
}
