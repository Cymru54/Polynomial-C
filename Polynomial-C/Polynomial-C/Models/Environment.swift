import Foundation

class Environment {
	private var store: [String: PolyValue] = [:]
	private var constants: Set<String> = []
	private var functions: [String: FunctionDeclNode] = [:]
	private let lock = NSLock()
	
	init() {
		define(name: "FrequencyHigh", value: .float(1.0), isConst: true)
		define(name: "FrequencyLow", value: .float(0.1), isConst: true)
		define(name: "Maximum", value: .float(1.0), isConst: true)
		define(name: "Minimum", value: .float(0.0), isConst: true)
		define(name: "Braindance", value: .float(0.6), isConst: true)
		define(name: "Acid", value: .float(0.85), isConst: true)
	}
	
	func define(name: String, value: PolyValue, isConst: Bool) {
		lock.lock(); defer { lock.unlock() }
		
		if store.keys.contains(name) { return }
		store[name] = value
		if isConst { constants.insert(name) }
	}
	
	func assign(name: String, value: PolyValue) {
		lock.lock(); defer { lock.unlock() }
		
		if constants.contains(name) { return }
		if store.keys.contains(name) {
			store[name] = value
		}
	}
	
	func get(name: String) -> PolyValue? {
		lock.lock(); defer { lock.unlock() }
		return store[name]
	}

	func defineFunction(name: String, node: FunctionDeclNode) {
		lock.lock(); defer { lock.unlock() }
		functions[name] = node
	}
	
	func getFunction(name: String) -> FunctionDeclNode? {
		lock.lock(); defer { lock.unlock() }
		return functions[name]
	}
}
