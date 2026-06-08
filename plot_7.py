import numpy as np
import matplotlib
matplotlib.use('Agg')  # Non-interactive backend to save figure without window
import matplotlib.pyplot as plt
import subprocess
import os

def generate_audio_signal(num_samples=2048):
    # Time vector (16 kHz sampling rate)
    fs = 16000
    t = np.arange(num_samples) / fs
    
    # Superposition of sines (e.g. 1000 Hz and 2500 Hz)
    f1, f2 = 1000, 2500
    signal = 0.5 * np.sin(2 * np.pi * f1 * t) + 0.3 * np.cos(2 * np.pi * f2 * t)
    
    # Scale to 16-bit signed integer range (leaving headroom)
    # FFT input expects 16-bit real (upper 16-bits) and 16-bit imaginary (lower 16-bits = 0)
    signal_scaled = np.clip(signal * 32767, -32768, 32767).astype(np.int16)
    
    # For verification, we repeat the first 512 samples 4 times so the input matches the repeated C firmware frames
    first_frame = signal_scaled[:512]
    repeated_signal = np.tile(first_frame, 4)
    
    # Format as 32-bit words (Real in upper 16 bits, Imag=0 in lower 16 bits)
    words = []
    for val in repeated_signal:
        unsigned_val = val & 0xFFFF
        word = (unsigned_val << 16) & 0xFFFFFFFF
        words.append(f"{word:08X}")
        
    with open("audio_in.txt", "w") as f:
        f.write("\n".join(words) + "\n")
        
    # Generate C header file with 512 elements of int8_t (512 bytes)
    h_lines = [
        "#ifndef AUDIO_IN_H",
        "#define AUDIO_IN_H",
        "#include <stdint.h>",
        "const int8_t audio_in_data[512] = {"
    ]
    for val in first_frame:
        val_8 = int(np.clip(val / 256.0, -128, 127))
        h_lines.append(f"    {val_8},")
    h_lines.extend([
        "};",
        "#endif"
    ])
    with open("firmware/audio_in.h", "w") as f:
        f.write("\n".join(h_lines) + "\n")
        
    print(f"Generated {num_samples} audio samples in audio_in.txt and firmware/audio_in.h")
    return repeated_signal.astype(np.float64)

def run_simulation():
    print("Building firmware...")
    subprocess.run("make -C firmware clean && make -C firmware", shell=True, check=True)
    
    # Remove old simulation dumps to prevent reading stale outputs
    for f in ["fft_out.txt", "ifft_out.txt"]:
        if os.path.exists(f):
            os.remove(f)
            
    # Clear Vivado's simulation caches
    sim_behav_dir = "NM32_top_temp/NM32_top_temp.sim/sim_1/behav/xsim"
    if os.path.exists(sim_behav_dir):
        import shutil
        for item in ["xsim.dir", "tb_behav.wdb", "webtalk.log", "webtalk.pb"]:
            item_path = os.path.join(sim_behav_dir, item)
            if os.path.exists(item_path):
                try:
                    if os.path.isdir(item_path):
                        shutil.rmtree(item_path)
                    else:
                        os.remove(item_path)
                except Exception as e:
                    print(f"Warning: could not delete cache {item_path}: {e}")
                    
    print("Launching Vivado simulation in batch mode...")
    cmd = 'bash -c "source /2025.2/Vivado/settings64.sh && vivado -mode batch -source run_sim.tcl"'
    result = subprocess.run(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if "SUCCESS" in result.stdout or result.returncode == 0:
        print("Simulation completed successfully!")
    else:
        print("Warning: Success signature not detected in stdout. Checking output logs...")

def parse_soc_output(filename):
    if not os.path.exists(filename):
        raise FileNotFoundError(f"{filename} not found. Simulation might have failed.")
        
    with open(filename, "r") as f:
        lines = f.read().splitlines()
        
    samples = []
    for line in lines:
        if not line.strip():
            continue
        val = int(line, 16)
        # Decode signed 16-bit Real and Imaginary parts
        real_u = (val >> 16) & 0xFFFF
        imag_u = val & 0xFFFF
        
        real = real_u - 65536 if real_u >= 32768 else real_u
        imag = imag_u - 65536 if imag_u >= 32768 else imag_u
        samples.append(complex(real, imag))
        
    return np.array(samples)

def bit_reverse(val, bits=9):
    rev = 0
    for _ in range(bits):
        rev = (rev << 1) | (val & 1)
        val >>= 1
    return rev

def main():
    # 1. Generate Input Audio Signal
    orig_signal_q15 = generate_audio_signal()
    
    # 2. Run simulation
    run_simulation()
    
    # 3. Read back hardware outputs
    soc_fft_raw = parse_soc_output("fft_out.txt")
    soc_ifft_raw = parse_soc_output("ifft_out.txt")
    
    num_frames = len(soc_fft_raw) // 512
    print(f"Read {len(soc_fft_raw)} FFT and {len(soc_ifft_raw)} IFFT samples ({num_frames} frames) from SoC output")
    
    # 4. Raw outputs from FFT and IFFT are already in natural order
    soc_fft_natural = soc_fft_raw
    soc_reconstructed_scaled = soc_ifft_raw.real * 512.0
    
    # 5. Compute Golden NumPy reference curves
    py_fft_mag_all = []
    py_ifft_all = []
    for frame in range(num_frames):
        py_frame_input = orig_signal_q15[frame*512 : (frame+1)*512]
        
        # NumPy FFT
        py_frame_fft = np.fft.fft(py_frame_input, n=512)
        py_fft_mag_all.extend(np.abs(py_frame_fft) / 512.0)
        
        # NumPy IFFT directly from Python FFT
        py_frame_ifft = np.fft.ifft(py_frame_fft)
        py_ifft_all.extend(py_frame_ifft.real)
        
    py_fft_mag_all = np.array(py_fft_mag_all)
    py_ifft_all = np.array(py_ifft_all)
    
    # Compute Errors
    soc_fft_mag = np.abs(soc_fft_natural)
    fft_error = np.abs(py_fft_mag_all - soc_fft_mag)
    ifft_error = np.abs(orig_signal_q15 - soc_reconstructed_scaled)
    
    max_fft_err = np.max(fft_error)
    max_ifft_err = np.max(ifft_error)
    print(f"Max FFT Magnitude Error: {max_fft_err:.2f}")
    print(f"Max Reconstruction (IFFT) Error: {max_ifft_err:.2f}")
    
    # 6. Plot the 7 subplots
    fig, axs = plt.subplots(7, 1, figsize=(10, 20))
    
    # Plot 1: Original Signal
    axs[0].plot(orig_signal_q15, color='blue', label='Input Audio Signal (Q15)')
    axs[0].set_title('1. Original Signal (Time Domain)')
    axs[0].set_xlabel('Sample Index')
    axs[0].set_ylabel('Amplitude (Q15)')
    axs[0].grid(True)
    axs[0].legend()
    
    # Plot 2: FFT from Python
    axs[1].plot(py_fft_mag_all, color='green', label='NumPy FFT Magnitude')
    axs[1].set_title('2. FFT Spectrum (NumPy Golden Reference)')
    axs[1].set_xlabel('Bin Index')
    axs[1].set_ylabel('Magnitude')
    axs[1].grid(True)
    axs[1].legend()
    
    # Plot 3: FFT from SoC
    axs[2].plot(soc_fft_mag, color='darkgreen', label='SoC HW FFT Magnitude')
    axs[2].set_title('3. FFT Spectrum (SoC Hardware FFT)')
    axs[2].set_xlabel('Bin Index')
    axs[2].set_ylabel('Magnitude')
    axs[2].grid(True)
    axs[2].legend()
    
    # Plot 4: FFT Error
    axs[3].plot(fft_error, color='orange', label='FFT Absolute Error')
    axs[3].set_title(f'4. FFT Magnitude Error (Max Error = {max_fft_err:.2f})')
    axs[3].set_xlabel('Bin Index')
    axs[3].set_ylabel('Delta Magnitude')
    axs[3].grid(True)
    axs[3].legend()
    
    # Plot 5: IFFT from Python
    axs[4].plot(py_ifft_all, color='purple', label='NumPy IFFT Output')
    axs[4].set_title('5. Reconstructed Signal (NumPy Golden IFFT)')
    axs[4].set_xlabel('Sample Index')
    axs[4].set_ylabel('Amplitude (Q15)')
    axs[4].grid(True)
    axs[4].legend()
    
    # Plot 6: IFFT from SoC
    axs[5].plot(soc_reconstructed_scaled, color='indigo', label='SoC HW IFFT Output (x512)')
    axs[5].set_title('6. Reconstructed Signal (SoC Hardware IFFT)')
    axs[5].set_xlabel('Sample Index')
    axs[5].set_ylabel('Amplitude (Q15)')
    axs[5].grid(True)
    axs[5].legend()
    
    # Plot 7: IFFT/Reconstruction Error
    axs[6].plot(ifft_error, color='red', label='Absolute Reconstruction Error')
    axs[6].set_title(f'7. Round-trip Reconstruction Error (Max Error = {max_ifft_err:.2f})')
    axs[6].set_xlabel('Sample Index')
    axs[6].set_ylabel('Delta Amplitude')
    axs[6].grid(True)
    axs[6].legend()
    
    plt.tight_layout()
    output_img = "fft_verification.png"
    plt.savefig(output_img, dpi=300)
    print(f"Verification plots successfully saved to: {os.path.abspath(output_img)}")

if __name__ == "__main__":
    main()
