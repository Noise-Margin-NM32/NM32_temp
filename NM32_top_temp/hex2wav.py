import sys
import wave

def hex_to_wav(hex_file, wav_file, sample_rate=16000):
    samples = []
    with open(hex_file, 'r') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            # Each line is a 32-bit hex string, but it represents two 16-bit left/right samples
            # Or is it a single 16-bit sample padded to 32 bits?
            # Based on typical I2S tx, let's assume it's just the filtered output written as 32-bit hex
            val = int(line, 16)
            
            # The firmware writes to I2S_TX_DATA. In main.c:
            # I2S_TX_DATA = (out_sample << 16) | (out_sample & 0xFFFF);
            # So the lower 16 bits are the actual sample.
            sample = val & 0xFFFF
            
            # Convert unsigned 16-bit hex to signed 16-bit int
            if sample > 32767:
                sample -= 65536
            samples.append(sample)

    with wave.open(wav_file, 'w') as wav:
        wav.setnchannels(1) # Mono
        wav.setsampwidth(2) # 2 bytes per sample (16-bit)
        wav.setframerate(sample_rate)
        
        for sample in samples:
            # pack as little-endian 16-bit
            data = sample.to_bytes(2, byteorder='little', signed=True)
            wav.writeframes(data)
            
    print(f'Converted {len(samples)} samples to {wav_file}')

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print('Usage: python3 hex2wav.py <input.txt> <output.wav> [sample_rate]')
        sys.exit(1)
        
    in_file = sys.argv[1]
    out_file = sys.argv[2]
    sr = int(sys.argv[3]) if len(sys.argv) > 3 else 16000
    
    hex_to_wav(in_file, out_file, sr)
