import Combine
import AVFoundation

final class SynthWrapper: @unchecked Sendable {
	let pointer: UnsafeMutableRawPointer
    
    init() {
		pointer = Synth_create()!
    }
    
	deinit {
        Synth_destroy(pointer)
    }
}

class EngineManager: ObservableObject {
	private let engine = AVAudioEngine()
	private let synth = SynthWrapper()
	private var sourceNode: AVAudioSourceNode?
	private let samplerNode = AVAudioPlayerNode()
	private let speedControl = AVAudioUnitVarispeed()
	private var currentSampleRate: Float = 1.0
	var isRunning: Bool = false
	
	init() {
		setupAudioEngine()
	}
	
	func setupEngine() {
		Synth_triggerNote(synth.pointer, false)
		try? engine.start()
	}
	
	private func setupAudioEngine() {
		let mainMixer = engine.mainMixerNode
		let format = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2)!
		let renderSynth = self.synth
		
		Synth_setSampleRate(synth.pointer, Float(format.sampleRate))
		
		sourceNode = AVAudioSourceNode { (_, _, frameCount, audioBufferList) -> OSStatus in
			let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
			
			if buffers.count > 0, let mData = buffers[0].mData {
				let leftChannel = mData.assumingMemoryBound(to: Float.self)
				Synth_renderAudio(renderSynth.pointer, leftChannel, Int32(frameCount))
				
				if buffers.count > 1, let rightData = buffers[1].mData {
					let rightChannel = rightData.assumingMemoryBound(to: Float.self)
					
					for i in 0..<Int(frameCount) {
						rightChannel[i] = leftChannel[i]
					}
				}
			}
			return noErr
		}
		
		guard let sourceNode = sourceNode else { return }
		engine.attach(sourceNode)
		engine.attach(samplerNode)
		engine.attach(speedControl)
		engine.connect(sourceNode, to: mainMixer, format: format)
		engine.connect(samplerNode, to: speedControl, format: nil)
		engine.connect(speedControl, to: engine.mainMixerNode, format: nil)
	}
	
	func start() {
		try? engine.start()
		Synth_triggerNote(synth.pointer, true)
	}
	
	func play303() {
		Synth_triggerNote(synth.pointer, true)
	}
	
	func stop() {
		Synth_triggerNote(synth.pointer, false)
	}
	
	func stopAll() {
		isRunning = false
		Synth_triggerNote(synth.pointer, false)
		samplerNode.stop()
	}
	
	func setFrequency(_ freq: Float) {
		Synth_setFrequency(synth.pointer, freq)
	}
	
	func setCutoff(_ normCutoff: Float) {
		let clamped = max(0.0, min(1.0, normCutoff))
		Synth_setCutoff(synth.pointer, clamped)
	}
	
	func setResonance(_ normRes: Float) {
		let clamped = max(0.0, min(1.0, normRes))
		Synth_setResonance(synth.pointer, clamped)
	}
	
	func setSamplerRate(_ rate: Float) {
		self.currentSampleRate = rate
		self.speedControl.rate = rate
		print("[AFXLog] Sampler rate set to \(rate)")
	}
	
	func playSample(name: String) {
		guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else {
			print("[AFXLog] Audio file could not be found: \(name).wav")
			return
		}
		guard let file = try? AVAudioFile(forReading: url) else { return }
		
		samplerNode.stop()
		samplerNode.scheduleFile(file, at: nil, completionHandler: nil)
		samplerNode.play()
	}
}
