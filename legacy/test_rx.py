def sim():
    sdi = []
    # Frame 0 Left channel
    sdi.append(0) # delay bit
    val = 0x26660000
    for i in range(31, -1, -1):
        sdi.append((val >> i) & 1)
    # Frame 0 Right channel
    sdi.append(0) # delay bit
    for i in range(31, -1, -1):
        sdi.append(0)
    
    sr = 0
    # Left channel has 33 bits, then ws toggles.
    # ws_dly goes high 2 posedge sck later.
    # So sr shifts 33 + 2 = 35 times before sample <= sr!
    for i in range(35):
        sr = ((sr << 1) | sdi[i]) & 0xFFFFFFFF
    
    print(f"sr after 35 shifts: {hex(sr)}")
    
    # What if it shifted 34 times?
    sr = 0
    for i in range(34):
        sr = ((sr << 1) | sdi[i]) & 0xFFFFFFFF
    print(f"sr after 34 shifts: {hex(sr)}")

    # What if it shifted 36 times?
    sr = 0
    for i in range(36):
        sr = ((sr << 1) | sdi[i]) & 0xFFFFFFFF
    print(f"sr after 36 shifts: {hex(sr)}")

sim()
