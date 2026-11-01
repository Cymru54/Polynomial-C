#ifndef Synthesizer303_hpp
#define Synthesizer303_hpp

#include <atomic>

class Synthesizer303 {
public:
	Synthesizer303();
	~Synthesizer303();
	Synthesizer303(const Synthesizer303& other);
	
	void setSampleRate(float sr);
	void setFrequency(float freq);
	void setCutoff(float normCutoff);
	void setResonance(float normRes);
	void triggerNote(bool isOn);
	void renderAudio(float* outputBuffer, int frameCount);
	
private:
	float sampleRate;
	float phase;
	float filterState;
	
	std::atomic<float> frequency;
	std::atomic<float> cutoff;
	std::atomic<float> resonance;
	std::atomic<bool> isPlaying;
};

#ifdef __cplusplus
extern "C" {
#endif

void* Synth_create();
void Synth_destroy(void* synth);

void Synth_setSampleRate(void* synth, float sr);
void Synth_setFrequency(void* synth, float freq);
void Synth_setCutoff(void* synth, float cutoff);
void Synth_setResonance(void* synth, float res);
void Synth_triggerNote(void* synth, bool isOn);
void Synth_renderAudio(void* synth, float* buffer, int frames);

#ifdef __cplusplus
}
#endif

#endif /* Synthesizer303_hpp */
