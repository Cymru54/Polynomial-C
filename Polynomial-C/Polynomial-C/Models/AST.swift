import Foundation

protocol ASTNode {}

struct IntNode: ASTNode { let value: Int }
struct FloatNode: ASTNode { let value: Float }
struct StringNode: ASTNode { let value: String }
struct BoolNode: ASTNode { let value: Bool }
struct NumberNode: ASTNode { let value: Float }
struct IdentifierNode: ASTNode { let name: String }
struct ProgramNode: ASTNode { let statements: [ASTNode] }
struct BlockNode: ASTNode { let statements: [ASTNode] }
struct ArrayNode: ASTNode { let elements: [ASTNode] }

struct MethodCallNode: ASTNode {
	let receiver: IdentifierNode
	let methodName: String
	let arguments: [ASTNode]
}

struct VariableDeclarationNode: ASTNode {
	let isConst: Bool
	let valueType: String
	let name: String
	let value: ASTNode
}

struct AssignmentNode: ASTNode {
	let name: String
	let value: ASTNode
}

struct BinaryOpNode: ASTNode {
	let left: ASTNode
	let operatorToken: Token
	let right: ASTNode
}

struct UnaryOpNode: ASTNode {
	let operatorToken: Token
	let right: ASTNode
}

struct IfNode: ASTNode {
	let condition: ASTNode
	let thenBranch: BlockNode
	let elseBranch: BlockNode?
}

struct WhileNode: ASTNode {
	let condition: ASTNode
	let body: BlockNode
}

struct FunctionDeclNode: ASTNode {
	let name: String
	let body: BlockNode
}

struct AsyncNode: ASTNode {
	let body: BlockNode
}
