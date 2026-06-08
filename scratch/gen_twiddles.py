import re

def main():
    rom_path = "/home/r_sarang/NM32_SoC/FFT_Accelerator/twiddle_rom_512.v"
    with open(rom_path, "r") as f:
        content = f.read()
    
    # Match cases: 8'dXX: begin wr = 16'hXXXX; wi = 16'hXXXX; end
    pattern = re.compile(r"8'd(\d+):\s*begin\s*wr\s*=\s*16'h([0-9A-Fa-f]+);\s*wi\s*=\s*16'h([0-9A-Fa-f]+);")
    matches = pattern.findall(content)
    
    twiddles = [None] * 256
    for idx_str, wr_hex, wi_hex in matches:
        idx = int(idx_str)
        # Parse hex as unsigned 16-bit
        wr = int(wr_hex, 16)
        wi = int(wi_hex, 16)
        # Combine into a 32-bit word: Real in upper 16, Imag in lower 16
        word = (wr << 16) | (wi & 0xFFFF)
        twiddles[idx] = f"0x{word:08X}"
        
    print("const uint32_t fft_twiddles[256] = {")
    for i in range(0, 256, 8):
        print("    " + ", ".join(twiddles[i:i+8]) + ",")
    print("};")

if __name__ == "__main__":
    main()
