import SwiftUI

struct ContentView: View {
	@StateObject private var engine = EngineManager()
	@State private var sourceCode: String = """
	[tb303 setFrequency:110.0];
	[tb303 setCutoff:FrequencyHigh];
	[tb303 setResonance:Maximum];
	"""
	@State private var logOutput: String = "Polynomial-C Compiler Ready."
	
	var body: some View {
		VStack(spacing: 0) {
			TextEditor(text: $sourceCode)
				.font(.system(.body, design: .monospaced))
				.padding()
				.background(Color.black.opacity(0.8))
				.foregroundColor(.green)
			
			HStack {
				Button(action: compileAndRun) {
					Text("Compile and Run")
						.font(.headline)
						.padding()
						.frame(maxWidth: .infinity)
						.background(Color.blue)
						.foregroundColor(.white)
				}
				
				Button(action: {
					engine.stopAll()
					logOutput = "[AFXLog] System halted. "
				}) {
					Text("[tb303 release];")
						.font(.headline)
						.padding()
						.frame(maxWidth: .infinity)
						.background(Color.red)
						.foregroundColor(.white)
				}
			}
			
			Text(logOutput)
				.font(.system(.caption, design: .monospaced))
				.frame(maxWidth: .infinity, alignment: .leading)
				.padding()
				.background(Color.gray.opacity(0.2))
		}
		.frame(width: 600, height: 400)
		.onAppear {
			engine.setupEngine()
		}
	}
	
	private func compileAndRun() {
		engine.isRunning = true
		logOutput = "Compiling...\n"
		
		let lexer = Lexer(input: sourceCode)
		let tokens = lexer.tokenize()
		let parser = Parser(tokens: tokens)
		let ast = parser.parse()
		logOutput += "AST successfully built. Execution started in background...\n"
		
		DispatchQueue.global(qos: .userInitiated).async {
			let evaluator = Evaluator(engine: self.engine)
			evaluator.evaluate(ast)
			
			DispatchQueue.main.async {
				self.logOutput += "Execution complete."
				print("End of all sequences.")
			}
		}
	}
}
