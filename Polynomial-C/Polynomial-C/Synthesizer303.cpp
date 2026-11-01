#include "Synthesizer303.hpp"
#include <cmath>

Synthesizer303::Synthesizer303():sampleRate(44100.0f), phase(0.0f), filterState(0.0f), frequency(440.0f), cutoff(1.0f), resonance(0.0f), isPlaying(true) {}
Synthesizer303::~Synthesizer303() {}
Synthesizer303::Synthesizer303(const Synthesizer303& other) {
	sampleRate = other.sampleRate;
	phase = other.phase;
	filterState = other.filterState;
	
	frequency.store(other.frequency.load());
	cutoff.store(other.cutoff.load());
	resonance.store(other.resonance.load());
	isPlaying.store(other.isPlaying.load());
}

void Synthesizer303::setSampleRate(float sr) {
	if (sr > 0.0f) sampleRate = sr;
}

void Synthesizer303::setFrequency(float freq) {
	frequency.store(freq);
}

void Synthesizer303::setCutoff(float normCutoff) {
	frequency.store(normCutoff);
}

void Synthesizer303::setResonance(float normRes) {
	resonance.store(normRes);
}

void Synthesizer303::triggerNote(bool isOn) {
	isPlaying.store(isOn);
}

void Synthesizer303::renderAudio(float* outputBuffer, int frameCount) {
	float currentFreq = frequency.load();
	float targetCutoff = cutoff.load();
	bool playing = isPlaying.load();
	float phaseIncrement = currentFreq / sampleRate;
	
	for (int i = 0; i < frameCount; ++i) {
		if (!playing) {
			outputBuffer[i] = 0.0f;
			continue;
		}
		
		float rawSaw = 2.0f * phase - 1.0f;
		phase += phaseIncrement;
		
		if (phase >= 1.0f) {
			phase -= 1.0f;
		}
		
		float lpCoeff = targetCutoff * 0.2f;
		filterState = filterState + lpCoeff * (rawSaw - filterState);
		outputBuffer[i] = filterState * 0.5f;
	}
}

extern "C" {
	void* Synth_create() {
		return new Synthesizer303();
	}
	void Synth_destroy(void* synth) {
		delete static_cast<Synthesizer303*>(synth);
	}
	void Synth_setSampleRate(void* synth, float sr) {
		static_cast<Synthesizer303*>(synth)->setSampleRate(sr);
	}
	void Synth_setFrequency(void* synth, float freq) {
		static_cast<Synthesizer303*>(synth)->setFrequency(freq);
	}
	void Synth_setCutoff(void* synth, float cutoff) {
		static_cast<Synthesizer303*>(synth)->setCutoff(cutoff);
	}
	void Synth_setResonance(void* synth, float res) {
		static_cast<Synthesizer303*>(synth)->setResonance(res);
	}
	void Synth_triggerNote(void* synth, bool isOn) {
		static_cast<Synthesizer303*>(synth)->triggerNote(isOn);
	}
	void Synth_renderAudio(void* synth, float* buffer, int frames) {
		static_cast<Synthesizer303*>(synth)->renderAudio(buffer, frames);
	}
}
