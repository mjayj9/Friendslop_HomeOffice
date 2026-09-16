class PCMInput extends AudioWorkletProcessor{
 constructor(){super();this.samples=new Float32Array(2048);this.at=0}
 process(inputs){const channel=inputs[0]?.[0];if(channel)for(const sample of channel){this.samples[this.at++]=sample;if(this.at===2048){const data=this.samples;this.port.postMessage({samples:data,sampleRate},[data.buffer]);this.samples=new Float32Array(2048);this.at=0}}return true}
}
registerProcessor('moyeo-pcm',PCMInput);
