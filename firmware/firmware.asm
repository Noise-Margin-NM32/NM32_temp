
firmware.elf:     file format elf32-littleriscv


Disassembly of section .boot:

00000000 <_start>:
   0:	30008117          	auipc	sp,0x30008
   4:	00010113          	mv	sp,sp
   8:	07c000ef          	jal	ra,84 <hardware_spi_bootloader>
   c:	30002517          	auipc	a0,0x30002
  10:	d6050513          	addi	a0,a0,-672 # 30001d6c <input_buffer>
  14:	30007597          	auipc	a1,0x30007
  18:	97058593          	addi	a1,a1,-1680 # 30006984 <input_write_ptr>
  1c:	00b55863          	bge	a0,a1,2c <end_init_bss>

00000020 <loop_init_bss>:
  20:	00052023          	sw	zero,0(a0)
  24:	00450513          	addi	a0,a0,4
  28:	feb54ce3          	blt	a0,a1,20 <loop_init_bss>

0000002c <end_init_bss>:
  2c:	30001517          	auipc	a0,0x30001
  30:	9d050513          	addi	a0,a0,-1584 # 300009fc <main>
  34:	000500e7          	jalr	a0

00000038 <trap>:
  38:	0000006f          	j	38 <trap>

0000003c <read_spi_flash_word>:
  3c:	00202737          	lui	a4,0x202
  40:	200207b7          	lui	a5,0x20020
  44:	80870713          	addi	a4,a4,-2040 # 201808 <hardware_spi_bootloader+0x201784>
  48:	00e7a823          	sw	a4,16(a5) # 20020010 <hardware_spi_bootloader+0x2001ff8c>
  4c:	0007aa23          	sw	zero,20(a5)
  50:	03000737          	lui	a4,0x3000
  54:	00e7a423          	sw	a4,8(a5)
  58:	00851513          	slli	a0,a0,0x8
  5c:	10100713          	li	a4,257
  60:	00a7a623          	sw	a0,12(a5)
  64:	00e7a023          	sw	a4,0(a5)
  68:	20020737          	lui	a4,0x20020
  6c:	00072783          	lw	a5,0(a4) # 20020000 <hardware_spi_bootloader+0x2001ff7c>
  70:	0107d793          	srli	a5,a5,0x10
  74:	01f7f793          	andi	a5,a5,31
  78:	fe078ae3          	beqz	a5,6c <read_spi_flash_word+0x30>
  7c:	02072503          	lw	a0,32(a4)
  80:	00008067          	ret

00000084 <hardware_spi_bootloader>:
  84:	fe010113          	addi	sp,sp,-32 # 30007fe0 <input_write_ptr+0x165c>
  88:	00812c23          	sw	s0,24(sp)
  8c:	00912a23          	sw	s1,20(sp)
  90:	01212823          	sw	s2,16(sp)
  94:	01312623          	sw	s3,12(sp)
  98:	01412423          	sw	s4,8(sp)
  9c:	00112e23          	sw	ra,28(sp)
  a0:	200207b7          	lui	a5,0x20020
  a4:	00400713          	li	a4,4
  a8:	30000437          	lui	s0,0x30000
  ac:	30002937          	lui	s2,0x30002
  b0:	000109b7          	lui	s3,0x10
  b4:	00e7a223          	sw	a4,4(a5) # 20020004 <hardware_spi_bootloader+0x2001ff80>
  b8:	00000493          	li	s1,0
  bc:	00040413          	mv	s0,s0
  c0:	d2c90913          	addi	s2,s2,-724 # 30001d2c <_text_ram_end>
  c4:	f0098993          	addi	s3,s3,-256 # ff00 <hardware_spi_bootloader+0xfe7c>
  c8:	00ff0a37          	lui	s4,0xff0
  cc:	05246663          	bltu	s0,s2,118 <hardware_spi_bootloader+0x94>
  d0:	000024b7          	lui	s1,0x2
  d4:	30002437          	lui	s0,0x30002
  d8:	30002937          	lui	s2,0x30002
  dc:	000109b7          	lui	s3,0x10
  e0:	d6848493          	addi	s1,s1,-664 # 1d68 <hardware_spi_bootloader+0x1ce4>
  e4:	d6840413          	addi	s0,s0,-664 # 30001d68 <first_frame>
  e8:	d6890913          	addi	s2,s2,-664 # 30001d68 <first_frame>
  ec:	f0098993          	addi	s3,s3,-256 # ff00 <hardware_spi_bootloader+0xfe7c>
  f0:	00ff0a37          	lui	s4,0xff0
  f4:	07246063          	bltu	s0,s2,154 <hardware_spi_bootloader+0xd0>
  f8:	01c12083          	lw	ra,28(sp)
  fc:	01812403          	lw	s0,24(sp)
 100:	01412483          	lw	s1,20(sp)
 104:	01012903          	lw	s2,16(sp)
 108:	00c12983          	lw	s3,12(sp)
 10c:	00812a03          	lw	s4,8(sp)
 110:	02010113          	addi	sp,sp,32
 114:	00008067          	ret
 118:	00048513          	mv	a0,s1
 11c:	f21ff0ef          	jal	ra,3c <read_spi_flash_word>
 120:	01851713          	slli	a4,a0,0x18
 124:	01855793          	srli	a5,a0,0x18
 128:	00e7e7b3          	or	a5,a5,a4
 12c:	00855713          	srli	a4,a0,0x8
 130:	01377733          	and	a4,a4,s3
 134:	00851513          	slli	a0,a0,0x8
 138:	00e7e7b3          	or	a5,a5,a4
 13c:	01457533          	and	a0,a0,s4
 140:	00a7e533          	or	a0,a5,a0
 144:	00a42023          	sw	a0,0(s0)
 148:	00448493          	addi	s1,s1,4
 14c:	00440413          	addi	s0,s0,4
 150:	f7dff06f          	j	cc <hardware_spi_bootloader+0x48>
 154:	00048513          	mv	a0,s1
 158:	ee5ff0ef          	jal	ra,3c <read_spi_flash_word>
 15c:	01851713          	slli	a4,a0,0x18
 160:	01855793          	srli	a5,a0,0x18
 164:	00e7e7b3          	or	a5,a5,a4
 168:	00855713          	srli	a4,a0,0x8
 16c:	01377733          	and	a4,a4,s3
 170:	00851513          	slli	a0,a0,0x8
 174:	00e7e7b3          	or	a5,a5,a4
 178:	01457533          	and	a0,a0,s4
 17c:	00a7e533          	or	a0,a5,a0
 180:	00a42023          	sw	a0,0(s0)
 184:	00448493          	addi	s1,s1,4
 188:	00440413          	addi	s0,s0,4
 18c:	f69ff06f          	j	f4 <hardware_spi_bootloader+0x70>

Disassembly of section .text:

30000000 <isqrt_bin>:
30000000:	400007b7          	lui	a5,0x40000
30000004:	00f56c63          	bltu	a0,a5,3000001c <isqrt_bin+0x1c>
30000008:	00000713          	li	a4,0
3000000c:	00079c63          	bnez	a5,30000024 <isqrt_bin+0x24>
30000010:	01071513          	slli	a0,a4,0x10
30000014:	01055513          	srli	a0,a0,0x10
30000018:	00008067          	ret
3000001c:	0027d793          	srli	a5,a5,0x2
30000020:	fe5ff06f          	j	30000004 <isqrt_bin+0x4>
30000024:	00e786b3          	add	a3,a5,a4
30000028:	00175713          	srli	a4,a4,0x1
3000002c:	00d56663          	bltu	a0,a3,30000038 <isqrt_bin+0x38>
30000030:	40d50533          	sub	a0,a0,a3
30000034:	00f70733          	add	a4,a4,a5
30000038:	0027d793          	srli	a5,a5,0x2
3000003c:	fd1ff06f          	j	3000000c <isqrt_bin+0xc>

30000040 <wait_and_unpack_dma.constprop.0>:
30000040:	20030737          	lui	a4,0x20030
30000044:	01072783          	lw	a5,16(a4) # 20030010 <hardware_spi_bootloader+0x2002ff8c>
30000048:	0027f793          	andi	a5,a5,2
3000004c:	fe078ce3          	beqz	a5,30000044 <wait_and_unpack_dma.constprop.0+0x4>
30000050:	00100793          	li	a5,1
30000054:	00f72823          	sw	a5,16(a4)
30000058:	20050737          	lui	a4,0x20050
3000005c:	01072783          	lw	a5,16(a4) # 20050010 <hardware_spi_bootloader+0x2004ff8c>
30000060:	0027f793          	andi	a5,a5,2
30000064:	fe078ce3          	beqz	a5,3000005c <wait_and_unpack_dma.constprop.0+0x1c>
30000068:	00100793          	li	a5,1
3000006c:	00f72823          	sw	a5,16(a4)
30000070:	30007737          	lui	a4,0x30007
30000074:	300056b7          	lui	a3,0x30005
30000078:	98472783          	lw	a5,-1660(a4) # 30006984 <input_write_ptr>
3000007c:	18468693          	addi	a3,a3,388 # 30005184 <dma_rx_buf>
30000080:	00b51513          	slli	a0,a0,0xb
30000084:	30002837          	lui	a6,0x30002
30000088:	00d50533          	add	a0,a0,a3
3000008c:	d6c80813          	addi	a6,a6,-660 # 30001d6c <input_buffer>
30000090:	00000693          	li	a3,0
30000094:	20000313          	li	t1,512
30000098:	10000893          	li	a7,256
3000009c:	00052583          	lw	a1,0(a0)
300000a0:	00179613          	slli	a2,a5,0x1
300000a4:	00c80633          	add	a2,a6,a2
300000a8:	00159593          	slli	a1,a1,0x1
300000ac:	00178793          	addi	a5,a5,1 # 40000001 <_stack_top+0xfff8001>
300000b0:	00b61023          	sh	a1,0(a2)
300000b4:	00168693          	addi	a3,a3,1
300000b8:	0267e7b3          	rem	a5,a5,t1
300000bc:	00850513          	addi	a0,a0,8
300000c0:	fd169ee3          	bne	a3,a7,3000009c <wait_and_unpack_dma.constprop.0+0x5c>
300000c4:	98f72223          	sw	a5,-1660(a4)
300000c8:	00008067          	ret

300000cc <pack_and_start_dma.constprop.0>:
300000cc:	300047b7          	lui	a5,0x30004
300000d0:	00b59593          	slli	a1,a1,0xb
300000d4:	18478793          	addi	a5,a5,388 # 30004184 <dma_tx_buf>
300000d8:	00f587b3          	add	a5,a1,a5
300000dc:	20050693          	addi	a3,a0,512
300000e0:	00078713          	mv	a4,a5
300000e4:	00055603          	lhu	a2,0(a0)
300000e8:	00072223          	sw	zero,4(a4)
300000ec:	00250513          	addi	a0,a0,2
300000f0:	00c72023          	sw	a2,0(a4)
300000f4:	00870713          	addi	a4,a4,8
300000f8:	fed516e3          	bne	a0,a3,300000e4 <pack_and_start_dma.constprop.0+0x18>
300000fc:	20050737          	lui	a4,0x20050
30000100:	00f72023          	sw	a5,0(a4) # 20050000 <hardware_spi_bootloader+0x2004ff7c>
30000104:	200107b7          	lui	a5,0x20010
30000108:	00f72223          	sw	a5,4(a4)
3000010c:	20000693          	li	a3,512
30000110:	00d72423          	sw	a3,8(a4)
30000114:	00300793          	li	a5,3
30000118:	00f72623          	sw	a5,12(a4)
3000011c:	200307b7          	lui	a5,0x20030
30000120:	20000737          	lui	a4,0x20000
30000124:	00e7a023          	sw	a4,0(a5) # 20030000 <hardware_spi_bootloader+0x2002ff7c>
30000128:	30005737          	lui	a4,0x30005
3000012c:	18470713          	addi	a4,a4,388 # 30005184 <dma_rx_buf>
30000130:	00e585b3          	add	a1,a1,a4
30000134:	00b7a223          	sw	a1,4(a5)
30000138:	00d7a423          	sw	a3,8(a5)
3000013c:	00500713          	li	a4,5
30000140:	00e7a623          	sw	a4,12(a5)
30000144:	00008067          	ret

30000148 <__divdi3>:
30000148:	00050e93          	mv	t4,a0
3000014c:	00000813          	li	a6,0
30000150:	0005dc63          	bgez	a1,30000168 <__divdi3+0x20>
30000154:	00a037b3          	snez	a5,a0
30000158:	40b005b3          	neg	a1,a1
3000015c:	40f585b3          	sub	a1,a1,a5
30000160:	40a00eb3          	neg	t4,a0
30000164:	fff00813          	li	a6,-1
30000168:	0006dc63          	bgez	a3,30000180 <__divdi3+0x38>
3000016c:	00c037b3          	snez	a5,a2
30000170:	40d006b3          	neg	a3,a3
30000174:	fff84813          	not	a6,a6
30000178:	40f686b3          	sub	a3,a3,a5
3000017c:	40c00633          	neg	a2,a2
30000180:	00060893          	mv	a7,a2
30000184:	00068713          	mv	a4,a3
30000188:	000e8e13          	mv	t3,t4
3000018c:	00058513          	mv	a0,a1
30000190:	2a069063          	bnez	a3,30000430 <__divdi3+0x2e8>
30000194:	00002697          	auipc	a3,0x2
30000198:	a9868693          	addi	a3,a3,-1384 # 30001c2c <__clz_tab>
3000019c:	0ec5f663          	bgeu	a1,a2,30000288 <__divdi3+0x140>
300001a0:	000107b7          	lui	a5,0x10
300001a4:	0cf67863          	bgeu	a2,a5,30000274 <__divdi3+0x12c>
300001a8:	0ff00793          	li	a5,255
300001ac:	00c7b7b3          	sltu	a5,a5,a2
300001b0:	00379793          	slli	a5,a5,0x3
300001b4:	00f65733          	srl	a4,a2,a5
300001b8:	00e686b3          	add	a3,a3,a4
300001bc:	0006c683          	lbu	a3,0(a3)
300001c0:	00f687b3          	add	a5,a3,a5
300001c4:	02000693          	li	a3,32
300001c8:	40f68733          	sub	a4,a3,a5
300001cc:	00f68c63          	beq	a3,a5,300001e4 <__divdi3+0x9c>
300001d0:	00e595b3          	sll	a1,a1,a4
300001d4:	00fed7b3          	srl	a5,t4,a5
300001d8:	00e618b3          	sll	a7,a2,a4
300001dc:	00b7e533          	or	a0,a5,a1
300001e0:	00ee9e33          	sll	t3,t4,a4
300001e4:	0108d313          	srli	t1,a7,0x10
300001e8:	026556b3          	divu	a3,a0,t1
300001ec:	01089593          	slli	a1,a7,0x10
300001f0:	0105d593          	srli	a1,a1,0x10
300001f4:	010e5793          	srli	a5,t3,0x10
300001f8:	02657733          	remu	a4,a0,t1
300001fc:	00068613          	mv	a2,a3
30000200:	02d58533          	mul	a0,a1,a3
30000204:	01071713          	slli	a4,a4,0x10
30000208:	00f767b3          	or	a5,a4,a5
3000020c:	00a7fe63          	bgeu	a5,a0,30000228 <__divdi3+0xe0>
30000210:	011787b3          	add	a5,a5,a7
30000214:	fff68613          	addi	a2,a3,-1
30000218:	0117e863          	bltu	a5,a7,30000228 <__divdi3+0xe0>
3000021c:	00a7f663          	bgeu	a5,a0,30000228 <__divdi3+0xe0>
30000220:	ffe68613          	addi	a2,a3,-2
30000224:	011787b3          	add	a5,a5,a7
30000228:	40a787b3          	sub	a5,a5,a0
3000022c:	0267f733          	remu	a4,a5,t1
30000230:	010e1e13          	slli	t3,t3,0x10
30000234:	010e5e13          	srli	t3,t3,0x10
30000238:	0267d7b3          	divu	a5,a5,t1
3000023c:	01071713          	slli	a4,a4,0x10
30000240:	01c76e33          	or	t3,a4,t3
30000244:	02f586b3          	mul	a3,a1,a5
30000248:	00078713          	mv	a4,a5
3000024c:	00de7c63          	bgeu	t3,a3,30000264 <__divdi3+0x11c>
30000250:	01c88e33          	add	t3,a7,t3
30000254:	fff78713          	addi	a4,a5,-1 # ffff <hardware_spi_bootloader+0xff7b>
30000258:	011e6663          	bltu	t3,a7,30000264 <__divdi3+0x11c>
3000025c:	00de7463          	bgeu	t3,a3,30000264 <__divdi3+0x11c>
30000260:	ffe78713          	addi	a4,a5,-2
30000264:	01061513          	slli	a0,a2,0x10
30000268:	00e56533          	or	a0,a0,a4
3000026c:	00000313          	li	t1,0
30000270:	0e40006f          	j	30000354 <__divdi3+0x20c>
30000274:	01000737          	lui	a4,0x1000
30000278:	01000793          	li	a5,16
3000027c:	f2e66ce3          	bltu	a2,a4,300001b4 <__divdi3+0x6c>
30000280:	01800793          	li	a5,24
30000284:	f31ff06f          	j	300001b4 <__divdi3+0x6c>
30000288:	00061663          	bnez	a2,30000294 <__divdi3+0x14c>
3000028c:	00100893          	li	a7,1
30000290:	02e8d8b3          	divu	a7,a7,a4
30000294:	000107b7          	lui	a5,0x10
30000298:	0cf8fc63          	bgeu	a7,a5,30000370 <__divdi3+0x228>
3000029c:	0ff00793          	li	a5,255
300002a0:	0117f463          	bgeu	a5,a7,300002a8 <__divdi3+0x160>
300002a4:	00800713          	li	a4,8
300002a8:	00e8d7b3          	srl	a5,a7,a4
300002ac:	00f686b3          	add	a3,a3,a5
300002b0:	0006c783          	lbu	a5,0(a3)
300002b4:	02000693          	li	a3,32
300002b8:	00e787b3          	add	a5,a5,a4
300002bc:	40f68733          	sub	a4,a3,a5
300002c0:	0cf69263          	bne	a3,a5,30000384 <__divdi3+0x23c>
300002c4:	411585b3          	sub	a1,a1,a7
300002c8:	00100313          	li	t1,1
300002cc:	0108d513          	srli	a0,a7,0x10
300002d0:	01089613          	slli	a2,a7,0x10
300002d4:	01065613          	srli	a2,a2,0x10
300002d8:	010e5713          	srli	a4,t3,0x10
300002dc:	02a5d7b3          	divu	a5,a1,a0
300002e0:	02a5f6b3          	remu	a3,a1,a0
300002e4:	02f605b3          	mul	a1,a2,a5
300002e8:	01069693          	slli	a3,a3,0x10
300002ec:	00e6e733          	or	a4,a3,a4
300002f0:	00078693          	mv	a3,a5
300002f4:	00b77e63          	bgeu	a4,a1,30000310 <__divdi3+0x1c8>
300002f8:	01170733          	add	a4,a4,a7
300002fc:	fff78693          	addi	a3,a5,-1 # ffff <hardware_spi_bootloader+0xff7b>
30000300:	01176863          	bltu	a4,a7,30000310 <__divdi3+0x1c8>
30000304:	00b77663          	bgeu	a4,a1,30000310 <__divdi3+0x1c8>
30000308:	ffe78693          	addi	a3,a5,-2
3000030c:	01170733          	add	a4,a4,a7
30000310:	40b70733          	sub	a4,a4,a1
30000314:	02a777b3          	remu	a5,a4,a0
30000318:	010e1e13          	slli	t3,t3,0x10
3000031c:	010e5e13          	srli	t3,t3,0x10
30000320:	02a75733          	divu	a4,a4,a0
30000324:	01079793          	slli	a5,a5,0x10
30000328:	01c7ee33          	or	t3,a5,t3
3000032c:	02e60633          	mul	a2,a2,a4
30000330:	00070793          	mv	a5,a4
30000334:	00ce7c63          	bgeu	t3,a2,3000034c <__divdi3+0x204>
30000338:	01c88e33          	add	t3,a7,t3
3000033c:	fff70793          	addi	a5,a4,-1 # ffffff <hardware_spi_bootloader+0xffff7b>
30000340:	011e6663          	bltu	t3,a7,3000034c <__divdi3+0x204>
30000344:	00ce7463          	bgeu	t3,a2,3000034c <__divdi3+0x204>
30000348:	ffe70793          	addi	a5,a4,-2
3000034c:	01069513          	slli	a0,a3,0x10
30000350:	00f56533          	or	a0,a0,a5
30000354:	00030593          	mv	a1,t1
30000358:	00080a63          	beqz	a6,3000036c <__divdi3+0x224>
3000035c:	00a037b3          	snez	a5,a0
30000360:	406005b3          	neg	a1,t1
30000364:	40f585b3          	sub	a1,a1,a5
30000368:	40a00533          	neg	a0,a0
3000036c:	00008067          	ret
30000370:	010007b7          	lui	a5,0x1000
30000374:	01000713          	li	a4,16
30000378:	f2f8e8e3          	bltu	a7,a5,300002a8 <__divdi3+0x160>
3000037c:	01800713          	li	a4,24
30000380:	f29ff06f          	j	300002a8 <__divdi3+0x160>
30000384:	00e898b3          	sll	a7,a7,a4
30000388:	00f5d533          	srl	a0,a1,a5
3000038c:	00ee9e33          	sll	t3,t4,a4
30000390:	00e595b3          	sll	a1,a1,a4
30000394:	00fed7b3          	srl	a5,t4,a5
30000398:	0108de93          	srli	t4,a7,0x10
3000039c:	00b7e633          	or	a2,a5,a1
300003a0:	03d557b3          	divu	a5,a0,t4
300003a4:	01089593          	slli	a1,a7,0x10
300003a8:	0105d593          	srli	a1,a1,0x10
300003ac:	03d57733          	remu	a4,a0,t4
300003b0:	01065513          	srli	a0,a2,0x10
300003b4:	00078313          	mv	t1,a5
300003b8:	02f586b3          	mul	a3,a1,a5
300003bc:	01071713          	slli	a4,a4,0x10
300003c0:	00a76733          	or	a4,a4,a0
300003c4:	00d77e63          	bgeu	a4,a3,300003e0 <__divdi3+0x298>
300003c8:	01170733          	add	a4,a4,a7
300003cc:	fff78313          	addi	t1,a5,-1 # ffffff <hardware_spi_bootloader+0xffff7b>
300003d0:	01176863          	bltu	a4,a7,300003e0 <__divdi3+0x298>
300003d4:	00d77663          	bgeu	a4,a3,300003e0 <__divdi3+0x298>
300003d8:	ffe78313          	addi	t1,a5,-2
300003dc:	01170733          	add	a4,a4,a7
300003e0:	40d706b3          	sub	a3,a4,a3
300003e4:	03d6f733          	remu	a4,a3,t4
300003e8:	01061613          	slli	a2,a2,0x10
300003ec:	01065613          	srli	a2,a2,0x10
300003f0:	03d6d6b3          	divu	a3,a3,t4
300003f4:	01071713          	slli	a4,a4,0x10
300003f8:	02d587b3          	mul	a5,a1,a3
300003fc:	00c765b3          	or	a1,a4,a2
30000400:	00068713          	mv	a4,a3
30000404:	00f5fe63          	bgeu	a1,a5,30000420 <__divdi3+0x2d8>
30000408:	011585b3          	add	a1,a1,a7
3000040c:	fff68713          	addi	a4,a3,-1
30000410:	0115e863          	bltu	a1,a7,30000420 <__divdi3+0x2d8>
30000414:	00f5f663          	bgeu	a1,a5,30000420 <__divdi3+0x2d8>
30000418:	ffe68713          	addi	a4,a3,-2
3000041c:	011585b3          	add	a1,a1,a7
30000420:	01031313          	slli	t1,t1,0x10
30000424:	40f585b3          	sub	a1,a1,a5
30000428:	00e36333          	or	t1,t1,a4
3000042c:	ea1ff06f          	j	300002cc <__divdi3+0x184>
30000430:	18d5e663          	bltu	a1,a3,300005bc <__divdi3+0x474>
30000434:	000107b7          	lui	a5,0x10
30000438:	04f6f463          	bgeu	a3,a5,30000480 <__divdi3+0x338>
3000043c:	0ff00713          	li	a4,255
30000440:	00d737b3          	sltu	a5,a4,a3
30000444:	00379793          	slli	a5,a5,0x3
30000448:	00f6d533          	srl	a0,a3,a5
3000044c:	00001717          	auipc	a4,0x1
30000450:	7e070713          	addi	a4,a4,2016 # 30001c2c <__clz_tab>
30000454:	00a70733          	add	a4,a4,a0
30000458:	00074703          	lbu	a4,0(a4)
3000045c:	00f70733          	add	a4,a4,a5
30000460:	02000793          	li	a5,32
30000464:	40e78333          	sub	t1,a5,a4
30000468:	02e79663          	bne	a5,a4,30000494 <__divdi3+0x34c>
3000046c:	00100513          	li	a0,1
30000470:	eeb6e2e3          	bltu	a3,a1,30000354 <__divdi3+0x20c>
30000474:	00ceb533          	sltu	a0,t4,a2
30000478:	00154513          	xori	a0,a0,1
3000047c:	ed9ff06f          	j	30000354 <__divdi3+0x20c>
30000480:	01000737          	lui	a4,0x1000
30000484:	01000793          	li	a5,16
30000488:	fce6e0e3          	bltu	a3,a4,30000448 <__divdi3+0x300>
3000048c:	01800793          	li	a5,24
30000490:	fb9ff06f          	j	30000448 <__divdi3+0x300>
30000494:	00e657b3          	srl	a5,a2,a4
30000498:	006696b3          	sll	a3,a3,t1
3000049c:	00d7e6b3          	or	a3,a5,a3
300004a0:	00e5d533          	srl	a0,a1,a4
300004a4:	006597b3          	sll	a5,a1,t1
300004a8:	00eed733          	srl	a4,t4,a4
300004ac:	0106df13          	srli	t5,a3,0x10
300004b0:	00f765b3          	or	a1,a4,a5
300004b4:	03e57733          	remu	a4,a0,t5
300004b8:	01069893          	slli	a7,a3,0x10
300004bc:	0108d893          	srli	a7,a7,0x10
300004c0:	0105d793          	srli	a5,a1,0x10
300004c4:	00661633          	sll	a2,a2,t1
300004c8:	03e55533          	divu	a0,a0,t5
300004cc:	01071713          	slli	a4,a4,0x10
300004d0:	00f767b3          	or	a5,a4,a5
300004d4:	02a88fb3          	mul	t6,a7,a0
300004d8:	00050e13          	mv	t3,a0
300004dc:	01f7fe63          	bgeu	a5,t6,300004f8 <__divdi3+0x3b0>
300004e0:	00d787b3          	add	a5,a5,a3
300004e4:	fff50e13          	addi	t3,a0,-1
300004e8:	00d7e863          	bltu	a5,a3,300004f8 <__divdi3+0x3b0>
300004ec:	01f7f663          	bgeu	a5,t6,300004f8 <__divdi3+0x3b0>
300004f0:	ffe50e13          	addi	t3,a0,-2
300004f4:	00d787b3          	add	a5,a5,a3
300004f8:	41f787b3          	sub	a5,a5,t6
300004fc:	03e7f733          	remu	a4,a5,t5
30000500:	01059593          	slli	a1,a1,0x10
30000504:	0105d593          	srli	a1,a1,0x10
30000508:	03e7d7b3          	divu	a5,a5,t5
3000050c:	01071713          	slli	a4,a4,0x10
30000510:	00b76733          	or	a4,a4,a1
30000514:	02f888b3          	mul	a7,a7,a5
30000518:	00078593          	mv	a1,a5
3000051c:	01177e63          	bgeu	a4,a7,30000538 <__divdi3+0x3f0>
30000520:	00d70733          	add	a4,a4,a3
30000524:	fff78593          	addi	a1,a5,-1 # ffff <hardware_spi_bootloader+0xff7b>
30000528:	00d76863          	bltu	a4,a3,30000538 <__divdi3+0x3f0>
3000052c:	01177663          	bgeu	a4,a7,30000538 <__divdi3+0x3f0>
30000530:	ffe78593          	addi	a1,a5,-2
30000534:	00d70733          	add	a4,a4,a3
30000538:	010e1513          	slli	a0,t3,0x10
3000053c:	00010f37          	lui	t5,0x10
30000540:	00b56533          	or	a0,a0,a1
30000544:	ffff0693          	addi	a3,t5,-1 # ffff <hardware_spi_bootloader+0xff7b>
30000548:	01055593          	srli	a1,a0,0x10
3000054c:	41170733          	sub	a4,a4,a7
30000550:	00d578b3          	and	a7,a0,a3
30000554:	00d676b3          	and	a3,a2,a3
30000558:	01065613          	srli	a2,a2,0x10
3000055c:	02d88e33          	mul	t3,a7,a3
30000560:	02d586b3          	mul	a3,a1,a3
30000564:	010e5793          	srli	a5,t3,0x10
30000568:	02c888b3          	mul	a7,a7,a2
3000056c:	00d888b3          	add	a7,a7,a3
30000570:	011787b3          	add	a5,a5,a7
30000574:	02c585b3          	mul	a1,a1,a2
30000578:	00d7f463          	bgeu	a5,a3,30000580 <__divdi3+0x438>
3000057c:	01e585b3          	add	a1,a1,t5
30000580:	0107d693          	srli	a3,a5,0x10
30000584:	00b685b3          	add	a1,a3,a1
30000588:	02b76663          	bltu	a4,a1,300005b4 <__divdi3+0x46c>
3000058c:	ceb710e3          	bne	a4,a1,3000026c <__divdi3+0x124>
30000590:	00010737          	lui	a4,0x10
30000594:	fff70713          	addi	a4,a4,-1 # ffff <hardware_spi_bootloader+0xff7b>
30000598:	00e7f7b3          	and	a5,a5,a4
3000059c:	01079793          	slli	a5,a5,0x10
300005a0:	00ee7e33          	and	t3,t3,a4
300005a4:	006e9eb3          	sll	t4,t4,t1
300005a8:	01c787b3          	add	a5,a5,t3
300005ac:	00000313          	li	t1,0
300005b0:	dafef2e3          	bgeu	t4,a5,30000354 <__divdi3+0x20c>
300005b4:	fff50513          	addi	a0,a0,-1
300005b8:	cb5ff06f          	j	3000026c <__divdi3+0x124>
300005bc:	00000313          	li	t1,0
300005c0:	00000513          	li	a0,0
300005c4:	d91ff06f          	j	30000354 <__divdi3+0x20c>

300005c8 <__udivdi3>:
300005c8:	00050893          	mv	a7,a0
300005cc:	00058793          	mv	a5,a1
300005d0:	00060813          	mv	a6,a2
300005d4:	00068513          	mv	a0,a3
300005d8:	00088313          	mv	t1,a7
300005dc:	28069463          	bnez	a3,30000864 <__udivdi3+0x29c>
300005e0:	00001697          	auipc	a3,0x1
300005e4:	64c68693          	addi	a3,a3,1612 # 30001c2c <__clz_tab>
300005e8:	0ec5f663          	bgeu	a1,a2,300006d4 <__udivdi3+0x10c>
300005ec:	00010737          	lui	a4,0x10
300005f0:	0ce67863          	bgeu	a2,a4,300006c0 <__udivdi3+0xf8>
300005f4:	0ff00713          	li	a4,255
300005f8:	00c73733          	sltu	a4,a4,a2
300005fc:	00371713          	slli	a4,a4,0x3
30000600:	00e65533          	srl	a0,a2,a4
30000604:	00a686b3          	add	a3,a3,a0
30000608:	0006c683          	lbu	a3,0(a3)
3000060c:	02000513          	li	a0,32
30000610:	00e68733          	add	a4,a3,a4
30000614:	40e506b3          	sub	a3,a0,a4
30000618:	00e50c63          	beq	a0,a4,30000630 <__udivdi3+0x68>
3000061c:	00d795b3          	sll	a1,a5,a3
30000620:	00e8d733          	srl	a4,a7,a4
30000624:	00d61833          	sll	a6,a2,a3
30000628:	00b765b3          	or	a1,a4,a1
3000062c:	00d89333          	sll	t1,a7,a3
30000630:	01085893          	srli	a7,a6,0x10
30000634:	0315d6b3          	divu	a3,a1,a7
30000638:	01081613          	slli	a2,a6,0x10
3000063c:	01065613          	srli	a2,a2,0x10
30000640:	01035793          	srli	a5,t1,0x10
30000644:	0315f733          	remu	a4,a1,a7
30000648:	00068513          	mv	a0,a3
3000064c:	02d605b3          	mul	a1,a2,a3
30000650:	01071713          	slli	a4,a4,0x10
30000654:	00f767b3          	or	a5,a4,a5
30000658:	00b7fe63          	bgeu	a5,a1,30000674 <__udivdi3+0xac>
3000065c:	010787b3          	add	a5,a5,a6
30000660:	fff68513          	addi	a0,a3,-1
30000664:	0107e863          	bltu	a5,a6,30000674 <__udivdi3+0xac>
30000668:	00b7f663          	bgeu	a5,a1,30000674 <__udivdi3+0xac>
3000066c:	ffe68513          	addi	a0,a3,-2
30000670:	010787b3          	add	a5,a5,a6
30000674:	40b787b3          	sub	a5,a5,a1
30000678:	0317f733          	remu	a4,a5,a7
3000067c:	01031313          	slli	t1,t1,0x10
30000680:	01035313          	srli	t1,t1,0x10
30000684:	0317d7b3          	divu	a5,a5,a7
30000688:	01071713          	slli	a4,a4,0x10
3000068c:	00676333          	or	t1,a4,t1
30000690:	02f606b3          	mul	a3,a2,a5
30000694:	00078613          	mv	a2,a5
30000698:	00d37c63          	bgeu	t1,a3,300006b0 <__udivdi3+0xe8>
3000069c:	00680333          	add	t1,a6,t1
300006a0:	fff78613          	addi	a2,a5,-1
300006a4:	01036663          	bltu	t1,a6,300006b0 <__udivdi3+0xe8>
300006a8:	00d37463          	bgeu	t1,a3,300006b0 <__udivdi3+0xe8>
300006ac:	ffe78613          	addi	a2,a5,-2
300006b0:	01051513          	slli	a0,a0,0x10
300006b4:	00c56533          	or	a0,a0,a2
300006b8:	00000593          	li	a1,0
300006bc:	0e40006f          	j	300007a0 <__udivdi3+0x1d8>
300006c0:	01000537          	lui	a0,0x1000
300006c4:	01000713          	li	a4,16
300006c8:	f2a66ce3          	bltu	a2,a0,30000600 <__udivdi3+0x38>
300006cc:	01800713          	li	a4,24
300006d0:	f31ff06f          	j	30000600 <__udivdi3+0x38>
300006d4:	00061663          	bnez	a2,300006e0 <__udivdi3+0x118>
300006d8:	00100713          	li	a4,1
300006dc:	02c75833          	divu	a6,a4,a2
300006e0:	00010737          	lui	a4,0x10
300006e4:	0ce87063          	bgeu	a6,a4,300007a4 <__udivdi3+0x1dc>
300006e8:	0ff00713          	li	a4,255
300006ec:	01077463          	bgeu	a4,a6,300006f4 <__udivdi3+0x12c>
300006f0:	00800513          	li	a0,8
300006f4:	00a85733          	srl	a4,a6,a0
300006f8:	00e686b3          	add	a3,a3,a4
300006fc:	0006c703          	lbu	a4,0(a3)
30000700:	02000613          	li	a2,32
30000704:	00a70733          	add	a4,a4,a0
30000708:	40e606b3          	sub	a3,a2,a4
3000070c:	0ae61663          	bne	a2,a4,300007b8 <__udivdi3+0x1f0>
30000710:	410787b3          	sub	a5,a5,a6
30000714:	00100593          	li	a1,1
30000718:	01085893          	srli	a7,a6,0x10
3000071c:	01081613          	slli	a2,a6,0x10
30000720:	01065613          	srli	a2,a2,0x10
30000724:	01035713          	srli	a4,t1,0x10
30000728:	0317f6b3          	remu	a3,a5,a7
3000072c:	0317d7b3          	divu	a5,a5,a7
30000730:	01069693          	slli	a3,a3,0x10
30000734:	00e6e733          	or	a4,a3,a4
30000738:	02f60e33          	mul	t3,a2,a5
3000073c:	00078513          	mv	a0,a5
30000740:	01c77e63          	bgeu	a4,t3,3000075c <__udivdi3+0x194>
30000744:	01070733          	add	a4,a4,a6
30000748:	fff78513          	addi	a0,a5,-1
3000074c:	01076863          	bltu	a4,a6,3000075c <__udivdi3+0x194>
30000750:	01c77663          	bgeu	a4,t3,3000075c <__udivdi3+0x194>
30000754:	ffe78513          	addi	a0,a5,-2
30000758:	01070733          	add	a4,a4,a6
3000075c:	41c70733          	sub	a4,a4,t3
30000760:	031777b3          	remu	a5,a4,a7
30000764:	01031313          	slli	t1,t1,0x10
30000768:	01035313          	srli	t1,t1,0x10
3000076c:	03175733          	divu	a4,a4,a7
30000770:	01079793          	slli	a5,a5,0x10
30000774:	0067e333          	or	t1,a5,t1
30000778:	02e606b3          	mul	a3,a2,a4
3000077c:	00070613          	mv	a2,a4
30000780:	00d37c63          	bgeu	t1,a3,30000798 <__udivdi3+0x1d0>
30000784:	00680333          	add	t1,a6,t1
30000788:	fff70613          	addi	a2,a4,-1 # ffff <hardware_spi_bootloader+0xff7b>
3000078c:	01036663          	bltu	t1,a6,30000798 <__udivdi3+0x1d0>
30000790:	00d37463          	bgeu	t1,a3,30000798 <__udivdi3+0x1d0>
30000794:	ffe70613          	addi	a2,a4,-2
30000798:	01051513          	slli	a0,a0,0x10
3000079c:	00c56533          	or	a0,a0,a2
300007a0:	00008067          	ret
300007a4:	01000737          	lui	a4,0x1000
300007a8:	01000513          	li	a0,16
300007ac:	f4e864e3          	bltu	a6,a4,300006f4 <__udivdi3+0x12c>
300007b0:	01800513          	li	a0,24
300007b4:	f41ff06f          	j	300006f4 <__udivdi3+0x12c>
300007b8:	00d81833          	sll	a6,a6,a3
300007bc:	00e7d533          	srl	a0,a5,a4
300007c0:	00d89333          	sll	t1,a7,a3
300007c4:	00d797b3          	sll	a5,a5,a3
300007c8:	00e8d733          	srl	a4,a7,a4
300007cc:	01085893          	srli	a7,a6,0x10
300007d0:	00f76633          	or	a2,a4,a5
300007d4:	03157733          	remu	a4,a0,a7
300007d8:	01081793          	slli	a5,a6,0x10
300007dc:	0107d793          	srli	a5,a5,0x10
300007e0:	01065593          	srli	a1,a2,0x10
300007e4:	03155533          	divu	a0,a0,a7
300007e8:	01071713          	slli	a4,a4,0x10
300007ec:	00b76733          	or	a4,a4,a1
300007f0:	02a786b3          	mul	a3,a5,a0
300007f4:	00050593          	mv	a1,a0
300007f8:	00d77e63          	bgeu	a4,a3,30000814 <__udivdi3+0x24c>
300007fc:	01070733          	add	a4,a4,a6
30000800:	fff50593          	addi	a1,a0,-1 # ffffff <hardware_spi_bootloader+0xffff7b>
30000804:	01076863          	bltu	a4,a6,30000814 <__udivdi3+0x24c>
30000808:	00d77663          	bgeu	a4,a3,30000814 <__udivdi3+0x24c>
3000080c:	ffe50593          	addi	a1,a0,-2
30000810:	01070733          	add	a4,a4,a6
30000814:	40d706b3          	sub	a3,a4,a3
30000818:	0316f733          	remu	a4,a3,a7
3000081c:	01061613          	slli	a2,a2,0x10
30000820:	01065613          	srli	a2,a2,0x10
30000824:	0316d6b3          	divu	a3,a3,a7
30000828:	01071713          	slli	a4,a4,0x10
3000082c:	02d78533          	mul	a0,a5,a3
30000830:	00c767b3          	or	a5,a4,a2
30000834:	00068713          	mv	a4,a3
30000838:	00a7fe63          	bgeu	a5,a0,30000854 <__udivdi3+0x28c>
3000083c:	010787b3          	add	a5,a5,a6
30000840:	fff68713          	addi	a4,a3,-1
30000844:	0107e863          	bltu	a5,a6,30000854 <__udivdi3+0x28c>
30000848:	00a7f663          	bgeu	a5,a0,30000854 <__udivdi3+0x28c>
3000084c:	ffe68713          	addi	a4,a3,-2
30000850:	010787b3          	add	a5,a5,a6
30000854:	01059593          	slli	a1,a1,0x10
30000858:	40a787b3          	sub	a5,a5,a0
3000085c:	00e5e5b3          	or	a1,a1,a4
30000860:	eb9ff06f          	j	30000718 <__udivdi3+0x150>
30000864:	18d5e663          	bltu	a1,a3,300009f0 <__udivdi3+0x428>
30000868:	00010737          	lui	a4,0x10
3000086c:	04e6f463          	bgeu	a3,a4,300008b4 <__udivdi3+0x2ec>
30000870:	0ff00713          	li	a4,255
30000874:	00d735b3          	sltu	a1,a4,a3
30000878:	00359593          	slli	a1,a1,0x3
3000087c:	00b6d533          	srl	a0,a3,a1
30000880:	00001717          	auipc	a4,0x1
30000884:	3ac70713          	addi	a4,a4,940 # 30001c2c <__clz_tab>
30000888:	00a70733          	add	a4,a4,a0
3000088c:	00074703          	lbu	a4,0(a4)
30000890:	02000513          	li	a0,32
30000894:	00b70733          	add	a4,a4,a1
30000898:	40e505b3          	sub	a1,a0,a4
3000089c:	02e51663          	bne	a0,a4,300008c8 <__udivdi3+0x300>
300008a0:	00100513          	li	a0,1
300008a4:	eef6eee3          	bltu	a3,a5,300007a0 <__udivdi3+0x1d8>
300008a8:	00c8b533          	sltu	a0,a7,a2
300008ac:	00154513          	xori	a0,a0,1
300008b0:	ef1ff06f          	j	300007a0 <__udivdi3+0x1d8>
300008b4:	01000737          	lui	a4,0x1000
300008b8:	01000593          	li	a1,16
300008bc:	fce6e0e3          	bltu	a3,a4,3000087c <__udivdi3+0x2b4>
300008c0:	01800593          	li	a1,24
300008c4:	fb9ff06f          	j	3000087c <__udivdi3+0x2b4>
300008c8:	00e65833          	srl	a6,a2,a4
300008cc:	00b696b3          	sll	a3,a3,a1
300008d0:	00d86833          	or	a6,a6,a3
300008d4:	00e7d333          	srl	t1,a5,a4
300008d8:	01085e93          	srli	t4,a6,0x10
300008dc:	03d376b3          	remu	a3,t1,t4
300008e0:	00b797b3          	sll	a5,a5,a1
300008e4:	00e8d733          	srl	a4,a7,a4
300008e8:	00b61e33          	sll	t3,a2,a1
300008ec:	00f76633          	or	a2,a4,a5
300008f0:	01081793          	slli	a5,a6,0x10
300008f4:	0107d793          	srli	a5,a5,0x10
300008f8:	01065713          	srli	a4,a2,0x10
300008fc:	03d35333          	divu	t1,t1,t4
30000900:	01069693          	slli	a3,a3,0x10
30000904:	00e6e733          	or	a4,a3,a4
30000908:	02678f33          	mul	t5,a5,t1
3000090c:	00030513          	mv	a0,t1
30000910:	01e77e63          	bgeu	a4,t5,3000092c <__udivdi3+0x364>
30000914:	01070733          	add	a4,a4,a6
30000918:	fff30513          	addi	a0,t1,-1
3000091c:	01076863          	bltu	a4,a6,3000092c <__udivdi3+0x364>
30000920:	01e77663          	bgeu	a4,t5,3000092c <__udivdi3+0x364>
30000924:	ffe30513          	addi	a0,t1,-2
30000928:	01070733          	add	a4,a4,a6
3000092c:	41e70733          	sub	a4,a4,t5
30000930:	03d776b3          	remu	a3,a4,t4
30000934:	03d75733          	divu	a4,a4,t4
30000938:	01069693          	slli	a3,a3,0x10
3000093c:	02e78333          	mul	t1,a5,a4
30000940:	01061793          	slli	a5,a2,0x10
30000944:	0107d793          	srli	a5,a5,0x10
30000948:	00f6e7b3          	or	a5,a3,a5
3000094c:	00070613          	mv	a2,a4
30000950:	0067fe63          	bgeu	a5,t1,3000096c <__udivdi3+0x3a4>
30000954:	010787b3          	add	a5,a5,a6
30000958:	fff70613          	addi	a2,a4,-1 # ffffff <hardware_spi_bootloader+0xffff7b>
3000095c:	0107e863          	bltu	a5,a6,3000096c <__udivdi3+0x3a4>
30000960:	0067f663          	bgeu	a5,t1,3000096c <__udivdi3+0x3a4>
30000964:	ffe70613          	addi	a2,a4,-2
30000968:	010787b3          	add	a5,a5,a6
3000096c:	01051513          	slli	a0,a0,0x10
30000970:	00010eb7          	lui	t4,0x10
30000974:	00c56533          	or	a0,a0,a2
30000978:	fffe8693          	addi	a3,t4,-1 # ffff <hardware_spi_bootloader+0xff7b>
3000097c:	010e5613          	srli	a2,t3,0x10
30000980:	01055813          	srli	a6,a0,0x10
30000984:	406787b3          	sub	a5,a5,t1
30000988:	00d57333          	and	t1,a0,a3
3000098c:	00de76b3          	and	a3,t3,a3
30000990:	02d30e33          	mul	t3,t1,a3
30000994:	02d806b3          	mul	a3,a6,a3
30000998:	010e5713          	srli	a4,t3,0x10
3000099c:	02c30333          	mul	t1,t1,a2
300009a0:	00d30333          	add	t1,t1,a3
300009a4:	00670733          	add	a4,a4,t1
300009a8:	02c80833          	mul	a6,a6,a2
300009ac:	00d77463          	bgeu	a4,a3,300009b4 <__udivdi3+0x3ec>
300009b0:	01d80833          	add	a6,a6,t4
300009b4:	01075693          	srli	a3,a4,0x10
300009b8:	01068833          	add	a6,a3,a6
300009bc:	0307e663          	bltu	a5,a6,300009e8 <__udivdi3+0x420>
300009c0:	cf079ce3          	bne	a5,a6,300006b8 <__udivdi3+0xf0>
300009c4:	000107b7          	lui	a5,0x10
300009c8:	fff78793          	addi	a5,a5,-1 # ffff <hardware_spi_bootloader+0xff7b>
300009cc:	00f77733          	and	a4,a4,a5
300009d0:	01071713          	slli	a4,a4,0x10
300009d4:	00fe7e33          	and	t3,t3,a5
300009d8:	00b898b3          	sll	a7,a7,a1
300009dc:	01c70733          	add	a4,a4,t3
300009e0:	00000593          	li	a1,0
300009e4:	dae8fee3          	bgeu	a7,a4,300007a0 <__udivdi3+0x1d8>
300009e8:	fff50513          	addi	a0,a0,-1
300009ec:	ccdff06f          	j	300006b8 <__udivdi3+0xf0>
300009f0:	00000593          	li	a1,0
300009f4:	00000513          	li	a0,0
300009f8:	da9ff06f          	j	300007a0 <__udivdi3+0x1d8>

300009fc <main>:
300009fc:	f7010113          	addi	sp,sp,-144
30000a00:	fffff337          	lui	t1,0xfffff
30000a04:	08812423          	sw	s0,136(sp)
30000a08:	08912223          	sw	s1,132(sp)
30000a0c:	09212023          	sw	s2,128(sp)
30000a10:	07312e23          	sw	s3,124(sp)
30000a14:	07412c23          	sw	s4,120(sp)
30000a18:	07512a23          	sw	s5,116(sp)
30000a1c:	07612823          	sw	s6,112(sp)
30000a20:	07712623          	sw	s7,108(sp)
30000a24:	07812423          	sw	s8,104(sp)
30000a28:	07912223          	sw	s9,100(sp)
30000a2c:	05b12e23          	sw	s11,92(sp)
30000a30:	08112623          	sw	ra,140(sp)
30000a34:	07a12023          	sw	s10,96(sp)
30000a38:	00001737          	lui	a4,0x1
30000a3c:	00610133          	add	sp,sp,t1
30000a40:	01070713          	addi	a4,a4,16 # 1010 <hardware_spi_bootloader+0xf8c>
30000a44:	04010693          	addi	a3,sp,64
30000a48:	00d70733          	add	a4,a4,a3
30000a4c:	fffff7b7          	lui	a5,0xfffff
30000a50:	00f707b3          	add	a5,a4,a5
30000a54:	00f12623          	sw	a5,12(sp)
30000a58:	00c12703          	lw	a4,12(sp)
30000a5c:	500007b7          	lui	a5,0x50000
30000a60:	30002937          	lui	s2,0x30002
30000a64:	fef72c23          	sw	a5,-8(a4)
30000a68:	500017b7          	lui	a5,0x50001
30000a6c:	80078793          	addi	a5,a5,-2048 # 50000800 <_stack_top+0x1fff8800>
30000a70:	fef72e23          	sw	a5,-4(a4)
30000a74:	300027b7          	lui	a5,0x30002
30000a78:	d6c78713          	addi	a4,a5,-660 # 30001d6c <input_buffer>
30000a7c:	40070713          	addi	a4,a4,1024
30000a80:	d6c78793          	addi	a5,a5,-660
30000a84:	000329b7          	lui	s3,0x32
30000a88:	fff9bb37          	lui	s6,0xfff9b
30000a8c:	1d70a437          	lui	s0,0x1d70a
30000a90:	228f64b7          	lui	s1,0x228f6
30000a94:	00065ab7          	lui	s5,0x65
30000a98:	0c910a37          	lui	s4,0xc910
30000a9c:	00e12623          	sw	a4,12(sp)
30000aa0:	00070c93          	mv	s9,a4
30000aa4:	00000d93          	li	s11,0
30000aa8:	00000c13          	li	s8,0
30000aac:	02f12023          	sw	a5,32(sp)
30000ab0:	16c90913          	addi	s2,s2,364 # 3000216c <hamming_q15>
30000ab4:	43f98993          	addi	s3,s3,1087 # 3243f <hardware_spi_bootloader+0x323bb>
30000ab8:	782b0b13          	addi	s6,s6,1922 # fff9b782 <_data_flash_start+0x7ff99a1a>
30000abc:	31a40413          	addi	s0,s0,794 # 1d70a31a <hardware_spi_bootloader+0x1d70a296>
30000ac0:	ccc48493          	addi	s1,s1,-820 # 228f5ccc <hardware_spi_bootloader+0x228f5c48>
30000ac4:	00008bb7          	lui	s7,0x8
30000ac8:	87ea8a93          	addi	s5,s5,-1922 # 6487e <hardware_spi_bootloader+0x647fa>
30000acc:	c00a0a13          	addi	s4,s4,-1024 # c90fc00 <hardware_spi_bootloader+0xc90fb7c>
30000ad0:	1ff00613          	li	a2,511
30000ad4:	00000693          	li	a3,0
30000ad8:	000d8513          	mv	a0,s11
30000adc:	000c0593          	mv	a1,s8
30000ae0:	e68ff0ef          	jal	ra,30000148 <__divdi3>
30000ae4:	00a9d463          	bge	s3,a0,30000aec <main+0xf0>
30000ae8:	01650533          	add	a0,a0,s6
30000aec:	02a50d33          	mul	s10,a0,a0
30000af0:	01800613          	li	a2,24
30000af4:	02a51533          	mulh	a0,a0,a0
30000af8:	002d5793          	srli	a5,s10,0x2
30000afc:	003d5d13          	srli	s10,s10,0x3
30000b00:	01e51693          	slli	a3,a0,0x1e
30000b04:	00f6e7b3          	or	a5,a3,a5
30000b08:	40255313          	srai	t1,a0,0x2
30000b0c:	02f308b3          	mul	a7,t1,a5
30000b10:	01d51513          	slli	a0,a0,0x1d
30000b14:	00f12c23          	sw	a5,24(sp)
30000b18:	01a56d33          	or	s10,a0,s10
30000b1c:	00612e23          	sw	t1,28(sp)
30000b20:	02f7b6b3          	mulhu	a3,a5,a5
30000b24:	00189893          	slli	a7,a7,0x1
30000b28:	02f78e33          	mul	t3,a5,a5
30000b2c:	00d888b3          	add	a7,a7,a3
30000b30:	00289693          	slli	a3,a7,0x2
30000b34:	41e8d893          	srai	a7,a7,0x1e
30000b38:	400007b7          	lui	a5,0x40000
30000b3c:	00088593          	mv	a1,a7
30000b40:	41a78d33          	sub	s10,a5,s10
30000b44:	01112823          	sw	a7,16(sp)
30000b48:	01ee5e13          	srli	t3,t3,0x1e
30000b4c:	01c6ee33          	or	t3,a3,t3
30000b50:	000e0513          	mv	a0,t3
30000b54:	00000693          	li	a3,0
30000b58:	01c12a23          	sw	t3,20(sp)
30000b5c:	decff0ef          	jal	ra,30000148 <__divdi3>
30000b60:	01412e03          	lw	t3,20(sp)
30000b64:	01812783          	lw	a5,24(sp)
30000b68:	01c12303          	lw	t1,28(sp)
30000b6c:	01012883          	lw	a7,16(sp)
30000b70:	03c785b3          	mul	a1,a5,t3
30000b74:	00ad0d33          	add	s10,s10,a0
30000b78:	00000693          	li	a3,0
30000b7c:	2d000613          	li	a2,720
30000b80:	03c30333          	mul	t1,t1,t3
30000b84:	01e5d593          	srli	a1,a1,0x1e
30000b88:	02f888b3          	mul	a7,a7,a5
30000b8c:	03c7b7b3          	mulhu	a5,a5,t3
30000b90:	011308b3          	add	a7,t1,a7
30000b94:	00f887b3          	add	a5,a7,a5
30000b98:	00279513          	slli	a0,a5,0x2
30000b9c:	00b56533          	or	a0,a0,a1
30000ba0:	41e7d593          	srai	a1,a5,0x1e
30000ba4:	da4ff0ef          	jal	ra,30000148 <__divdi3>
30000ba8:	40ad0533          	sub	a0,s10,a0
30000bac:	028506b3          	mul	a3,a0,s0
30000bb0:	02851533          	mulh	a0,a0,s0
30000bb4:	01e6d693          	srli	a3,a3,0x1e
30000bb8:	00251793          	slli	a5,a0,0x2
30000bbc:	00d7e6b3          	or	a3,a5,a3
30000bc0:	40d486b3          	sub	a3,s1,a3
30000bc4:	41e55793          	srai	a5,a0,0x1e
30000bc8:	40f007b3          	neg	a5,a5
30000bcc:	00d4b533          	sltu	a0,s1,a3
30000bd0:	40a787b3          	sub	a5,a5,a0
30000bd4:	01179793          	slli	a5,a5,0x11
30000bd8:	00f6d693          	srli	a3,a3,0xf
30000bdc:	00d7e7b3          	or	a5,a5,a3
30000be0:	0177c663          	blt	a5,s7,30000bec <main+0x1f0>
30000be4:	000087b7          	lui	a5,0x8
30000be8:	fff78793          	addi	a5,a5,-1 # 7fff <hardware_spi_bootloader+0x7f7b>
30000bec:	00fc9023          	sh	a5,0(s9)
30000bf0:	015d87b3          	add	a5,s11,s5
30000bf4:	01b7b6b3          	sltu	a3,a5,s11
30000bf8:	01868c33          	add	s8,a3,s8
30000bfc:	00078d93          	mv	s11,a5
30000c00:	002c8c93          	addi	s9,s9,2
30000c04:	ed4796e3          	bne	a5,s4,30000ad0 <main+0xd4>
30000c08:	ec0c14e3          	bnez	s8,30000ad0 <main+0xd4>
30000c0c:	30003437          	lui	s0,0x30003
30000c10:	d6c40793          	addi	a5,s0,-660 # 30002d6c <real_q15+0x1fc>
30000c14:	80078793          	addi	a5,a5,-2048
30000c18:	00f12e23          	sw	a5,28(sp)
30000c1c:	00c12783          	lw	a5,12(sp)
30000c20:	01c12603          	lw	a2,28(sp)
30000c24:	d6c40413          	addi	s0,s0,-660
30000c28:	20078593          	addi	a1,a5,512
30000c2c:	00078693          	mv	a3,a5
30000c30:	40000537          	lui	a0,0x40000
30000c34:	00069783          	lh	a5,0(a3)
30000c38:	20069703          	lh	a4,512(a3)
30000c3c:	02f787b3          	mul	a5,a5,a5
30000c40:	02e70733          	mul	a4,a4,a4
30000c44:	40f7d793          	srai	a5,a5,0xf
30000c48:	40f75713          	srai	a4,a4,0xf
30000c4c:	00e787b3          	add	a5,a5,a4
30000c50:	00000713          	li	a4,0
30000c54:	00f05463          	blez	a5,30000c5c <main+0x260>
30000c58:	02f54733          	div	a4,a0,a5
30000c5c:	00e62023          	sw	a4,0(a2)
30000c60:	00268693          	addi	a3,a3,2
30000c64:	00460613          	addi	a2,a2,4
30000c68:	fcd596e3          	bne	a1,a3,30000c34 <main+0x238>
30000c6c:	30001737          	lui	a4,0x30001
30000c70:	400017b7          	lui	a5,0x40001
30000c74:	62870513          	addi	a0,a4,1576 # 30001628 <fft_twiddles>
30000c78:	00010837          	lui	a6,0x10
30000c7c:	62870713          	addi	a4,a4,1576
30000c80:	02e12423          	sw	a4,40(sp)
30000c84:	80078693          	addi	a3,a5,-2048 # 40000800 <_stack_top+0xfff8800>
30000c88:	20000737          	lui	a4,0x20000
30000c8c:	fff80813          	addi	a6,a6,-1 # ffff <hardware_spi_bootloader+0xff7b>
30000c90:	ffff0337          	lui	t1,0xffff0
30000c94:	c0078593          	addi	a1,a5,-1024
30000c98:	00052603          	lw	a2,0(a0) # 40000000 <_stack_top+0xfff8000>
30000c9c:	00e688b3          	add	a7,a3,a4
30000ca0:	00468693          	addi	a3,a3,4
30000ca4:	01061793          	slli	a5,a2,0x10
30000ca8:	4107d793          	srai	a5,a5,0x10
30000cac:	40f007b3          	neg	a5,a5
30000cb0:	fec6ae23          	sw	a2,-4(a3)
30000cb4:	0107f7b3          	and	a5,a5,a6
30000cb8:	00667633          	and	a2,a2,t1
30000cbc:	00c7e7b3          	or	a5,a5,a2
30000cc0:	00f8a023          	sw	a5,0(a7)
30000cc4:	00450513          	addi	a0,a0,4
30000cc8:	fcb698e3          	bne	a3,a1,30000c98 <main+0x29c>
30000ccc:	200107b7          	lui	a5,0x20010
30000cd0:	00100693          	li	a3,1
30000cd4:	f0d7a823          	sw	a3,-240(a5) # 2000ff10 <hardware_spi_bootloader+0x2000fe8c>
30000cd8:	20020637          	lui	a2,0x20020
30000cdc:	f0d62823          	sw	a3,-240(a2) # 2001ff10 <hardware_spi_bootloader+0x2001fe8c>
30000ce0:	00200693          	li	a3,2
30000ce4:	00d72223          	sw	a3,4(a4) # 20000004 <hardware_spi_bootloader+0x1fffff80>
30000ce8:	00d7a223          	sw	a3,4(a5)
30000cec:	20b00613          	li	a2,523
30000cf0:	00c72a23          	sw	a2,20(a4)
30000cf4:	00c7aa23          	sw	a2,20(a5)
30000cf8:	00d72823          	sw	a3,16(a4)
30000cfc:	00d7a823          	sw	a3,16(a5)
30000d00:	0007a023          	sw	zero,0(a5)
30000d04:	0007a023          	sw	zero,0(a5)
30000d08:	0007a023          	sw	zero,0(a5)
30000d0c:	0007a023          	sw	zero,0(a5)
30000d10:	0007a023          	sw	zero,0(a5)
30000d14:	0007a023          	sw	zero,0(a5)
30000d18:	0007a023          	sw	zero,0(a5)
30000d1c:	0007a023          	sw	zero,0(a5)
30000d20:	00300693          	li	a3,3
30000d24:	00d72823          	sw	a3,16(a4)
30000d28:	02012703          	lw	a4,32(sp)
30000d2c:	00d7a823          	sw	a3,16(a5)
30000d30:	300067b7          	lui	a5,0x30006
30000d34:	18478793          	addi	a5,a5,388 # 30006184 <ola_buffer>
30000d38:	00071023          	sh	zero,0(a4)
30000d3c:	0007a023          	sw	zero,0(a5)
30000d40:	00270713          	addi	a4,a4,2
30000d44:	00478793          	addi	a5,a5,4
30000d48:	fee918e3          	bne	s2,a4,30000d38 <main+0x33c>
30000d4c:	300037b7          	lui	a5,0x30003
30000d50:	e0240713          	addi	a4,s0,-510
30000d54:	96c78793          	addi	a5,a5,-1684 # 3000296c <prev_mask_q15>
30000d58:	00079023          	sh	zero,0(a5)
30000d5c:	00278793          	addi	a5,a5,2
30000d60:	fef71ce3          	bne	a4,a5,30000d58 <main+0x35c>
30000d64:	00001737          	lui	a4,0x1
30000d68:	01070713          	addi	a4,a4,16 # 1010 <hardware_spi_bootloader+0xf8c>
30000d6c:	04010693          	addi	a3,sp,64
30000d70:	00d70733          	add	a4,a4,a3
30000d74:	fffff7b7          	lui	a5,0xfffff
30000d78:	00f707b3          	add	a5,a4,a5
30000d7c:	40078713          	addi	a4,a5,1024 # fffff400 <_data_flash_start+0x7fffd698>
30000d80:	00079023          	sh	zero,0(a5)
30000d84:	00278793          	addi	a5,a5,2
30000d88:	fef71ce3          	bne	a4,a5,30000d80 <main+0x384>
30000d8c:	00001737          	lui	a4,0x1
30000d90:	04010693          	addi	a3,sp,64
30000d94:	01070713          	addi	a4,a4,16 # 1010 <hardware_spi_bootloader+0xf8c>
30000d98:	00d70733          	add	a4,a4,a3
30000d9c:	fffff7b7          	lui	a5,0xfffff
30000da0:	00f707b3          	add	a5,a4,a5
30000da4:	00078513          	mv	a0,a5
30000da8:	00000593          	li	a1,0
30000dac:	00f12823          	sw	a5,16(sp)
30000db0:	b1cff0ef          	jal	ra,300000cc <pack_and_start_dma.constprop.0>
30000db4:	00000513          	li	a0,0
30000db8:	a88ff0ef          	jal	ra,30000040 <wait_and_unpack_dma.constprop.0>
30000dbc:	01012503          	lw	a0,16(sp)
30000dc0:	00100593          	li	a1,1
30000dc4:	30004937          	lui	s2,0x30004
30000dc8:	b04ff0ef          	jal	ra,300000cc <pack_and_start_dma.constprop.0>
30000dcc:	00100513          	li	a0,1
30000dd0:	a70ff0ef          	jal	ra,30000040 <wait_and_unpack_dma.constprop.0>
30000dd4:	300037b7          	lui	a5,0x30003
30000dd8:	b7078793          	addi	a5,a5,-1168 # 30002b70 <real_q15>
30000ddc:	00f12c23          	sw	a5,24(sp)
30000de0:	300027b7          	lui	a5,0x30002
30000de4:	16c78793          	addi	a5,a5,364 # 3000216c <hamming_q15>
30000de8:	00000a13          	li	s4,0
30000dec:	d6c90913          	addi	s2,s2,-660 # 30003d6c <sir_sq+0x1f0>
30000df0:	02f12c23          	sw	a5,56(sp)
30000df4:	000016b7          	lui	a3,0x1
30000df8:	04010613          	addi	a2,sp,64
30000dfc:	01068693          	addi	a3,a3,16 # 1010 <hardware_spi_bootloader+0xf8c>
30000e00:	00c686b3          	add	a3,a3,a2
30000e04:	001a7493          	andi	s1,s4,1
30000e08:	fffff737          	lui	a4,0xfffff
30000e0c:	00e68733          	add	a4,a3,a4
30000e10:	00249793          	slli	a5,s1,0x2
30000e14:	00f707b3          	add	a5,a4,a5
30000e18:	ff87a983          	lw	s3,-8(a5)
30000e1c:	00e12823          	sw	a4,16(sp)
30000e20:	500017b7          	lui	a5,0x50001
30000e24:	0097a023          	sw	s1,0(a5) # 50001000 <_stack_top+0x1fff9000>
30000e28:	300077b7          	lui	a5,0x30007
30000e2c:	9847a803          	lw	a6,-1660(a5) # 30006984 <input_write_ptr>
30000e30:	00c12603          	lw	a2,12(sp)
30000e34:	000105b7          	lui	a1,0x10
30000e38:	00000693          	li	a3,0
30000e3c:	20000513          	li	a0,512
30000e40:	fff58593          	addi	a1,a1,-1 # ffff <hardware_spi_bootloader+0xff7b>
30000e44:	00d807b3          	add	a5,a6,a3
30000e48:	02a7e7b3          	rem	a5,a5,a0
30000e4c:	02012703          	lw	a4,32(sp)
30000e50:	00068313          	mv	t1,a3
30000e54:	00900893          	li	a7,9
30000e58:	00179793          	slli	a5,a5,0x1
30000e5c:	00f707b3          	add	a5,a4,a5
30000e60:	00079703          	lh	a4,0(a5)
30000e64:	00061783          	lh	a5,0(a2)
30000e68:	02f70733          	mul	a4,a4,a5
30000e6c:	00000793          	li	a5,0
30000e70:	41475713          	srai	a4,a4,0x14
30000e74:	00137e13          	andi	t3,t1,1
30000e78:	00179793          	slli	a5,a5,0x1
30000e7c:	fff88893          	addi	a7,a7,-1
30000e80:	00fe67b3          	or	a5,t3,a5
30000e84:	00135313          	srli	t1,t1,0x1
30000e88:	fe0896e3          	bnez	a7,30000e74 <main+0x478>
30000e8c:	00279793          	slli	a5,a5,0x2
30000e90:	00f987b3          	add	a5,s3,a5
30000e94:	00b77733          	and	a4,a4,a1
30000e98:	00e7a023          	sw	a4,0(a5)
30000e9c:	00168693          	addi	a3,a3,1
30000ea0:	00260613          	addi	a2,a2,2
30000ea4:	faa690e3          	bne	a3,a0,30000e44 <main+0x448>
30000ea8:	00100793          	li	a5,1
30000eac:	40001737          	lui	a4,0x40001
30000eb0:	c0f72023          	sw	a5,-1024(a4) # 40000c00 <_stack_top+0xfff8c00>
30000eb4:	fffff537          	lui	a0,0xfffff
30000eb8:	740a0463          	beqz	s4,30001600 <main+0xc04>
30000ebc:	00001737          	lui	a4,0x1
30000ec0:	01070713          	addi	a4,a4,16 # 1010 <hardware_spi_bootloader+0xf8c>
30000ec4:	04010693          	addi	a3,sp,64
30000ec8:	40050513          	addi	a0,a0,1024 # fffff400 <_data_flash_start+0x7fffd698>
30000ecc:	00d70733          	add	a4,a4,a3
30000ed0:	409787b3          	sub	a5,a5,s1
30000ed4:	00a70533          	add	a0,a4,a0
30000ed8:	00979793          	slli	a5,a5,0x9
30000edc:	00a78533          	add	a0,a5,a0
30000ee0:	00048593          	mv	a1,s1
30000ee4:	9e8ff0ef          	jal	ra,300000cc <pack_and_start_dma.constprop.0>
30000ee8:	40001737          	lui	a4,0x40001
30000eec:	c0072783          	lw	a5,-1024(a4) # 40000c00 <_stack_top+0xfff8c00>
30000ef0:	0027f793          	andi	a5,a5,2
30000ef4:	fe078ce3          	beqz	a5,30000eec <main+0x4f0>
30000ef8:	30003b37          	lui	s6,0x30003
30000efc:	f70b0793          	addi	a5,s6,-144 # 30002f70 <imag_q15>
30000f00:	00000c13          	li	s8,0
30000f04:	e0440513          	addi	a0,s0,-508
30000f08:	20440593          	addi	a1,s0,516
30000f0c:	40000693          	li	a3,1024
30000f10:	00f12a23          	sw	a5,20(sp)
30000f14:	001c1793          	slli	a5,s8,0x1
30000f18:	013787b3          	add	a5,a5,s3
30000f1c:	0007a783          	lw	a5,0(a5)
30000f20:	01850633          	add	a2,a0,s8
30000f24:	01312823          	sw	s3,16(sp)
30000f28:	00f61023          	sh	a5,0(a2)
30000f2c:	01858633          	add	a2,a1,s8
30000f30:	0107d793          	srli	a5,a5,0x10
30000f34:	00f61023          	sh	a5,0(a2)
30000f38:	002c0c13          	addi	s8,s8,2
30000f3c:	fcdc1ce3          	bne	s8,a3,30000f14 <main+0x518>
30000f40:	60440b93          	addi	s7,s0,1540
30000f44:	30003ab7          	lui	s5,0x30003
30000f48:	00000693          	li	a3,0
30000f4c:	000b8593          	mv	a1,s7
30000f50:	370a8a93          	addi	s5,s5,880 # 30003370 <mag_sq>
30000f54:	20200513          	li	a0,514
30000f58:	01812783          	lw	a5,24(sp)
30000f5c:	01412703          	lw	a4,20(sp)
30000f60:	00458593          	addi	a1,a1,4
30000f64:	00d787b3          	add	a5,a5,a3
30000f68:	00d70633          	add	a2,a4,a3
30000f6c:	00079783          	lh	a5,0(a5)
30000f70:	00061603          	lh	a2,0(a2)
30000f74:	00268693          	addi	a3,a3,2
30000f78:	02f787b3          	mul	a5,a5,a5
30000f7c:	02c60633          	mul	a2,a2,a2
30000f80:	00c787b3          	add	a5,a5,a2
30000f84:	fef5ae23          	sw	a5,-4(a1)
30000f88:	fca698e3          	bne	a3,a0,30000f58 <main+0x55c>
30000f8c:	30003cb7          	lui	s9,0x30003
30000f90:	a0890d93          	addi	s11,s2,-1528
30000f94:	404b8b13          	addi	s6,s7,1028 # 8404 <hardware_spi_bootloader+0x8380>
30000f98:	000b8d13          	mv	s10,s7
30000f9c:	774c8c93          	addi	s9,s9,1908 # 30003774 <mag_q15_arr>
30000fa0:	000d2503          	lw	a0,0(s10)
30000fa4:	004d0d13          	addi	s10,s10,4
30000fa8:	002d8d93          	addi	s11,s11,2
30000fac:	854ff0ef          	jal	ra,30000000 <isqrt_bin>
30000fb0:	fead9f23          	sh	a0,-2(s11)
30000fb4:	ffab16e3          	bne	s6,s10,30000fa0 <main+0x5a4>
30000fb8:	c0c90613          	addi	a2,s2,-1012
30000fbc:	00060793          	mv	a5,a2
30000fc0:	30004737          	lui	a4,0x30004
30000fc4:	00079023          	sh	zero,0(a5)
30000fc8:	b7a70713          	addi	a4,a4,-1158 # 30003b7a <proj_q15+0x202>
30000fcc:	00278793          	addi	a5,a5,2
30000fd0:	fef718e3          	bne	a4,a5,30000fc0 <main+0x5c4>
30000fd4:	02812783          	lw	a5,40(sp)
30000fd8:	300025b7          	lui	a1,0x30002
30000fdc:	00000813          	li	a6,0
30000fe0:	00000693          	li	a3,0
30000fe4:	00000513          	li	a0,0
30000fe8:	40078e93          	addi	t4,a5,1024
30000fec:	20200e13          	li	t3,514
30000ff0:	a2858593          	addi	a1,a1,-1496 # 30001a28 <trigger_vecs_q15>
30000ff4:	010e88b3          	add	a7,t4,a6
30000ff8:	010c87b3          	add	a5,s9,a6
30000ffc:	00089303          	lh	t1,0(a7)
30001000:	00079783          	lh	a5,0(a5)
30001004:	00280813          	addi	a6,a6,2
30001008:	026788b3          	mul	a7,a5,t1
3000100c:	026797b3          	mulh	a5,a5,t1
30001010:	011688b3          	add	a7,a3,a7
30001014:	00d8b333          	sltu	t1,a7,a3
30001018:	00088693          	mv	a3,a7
3000101c:	00f507b3          	add	a5,a0,a5
30001020:	00f30533          	add	a0,t1,a5
30001024:	fdc818e3          	bne	a6,t3,30000ff4 <main+0x5f8>
30001028:	01151793          	slli	a5,a0,0x11
3000102c:	00f8d693          	srli	a3,a7,0xf
30001030:	00d7e6b3          	or	a3,a5,a3
30001034:	00300793          	li	a5,3
30001038:	02d786b3          	mul	a3,a5,a3
3000103c:	ffff87b7          	lui	a5,0xffff8
30001040:	4016d693          	srai	a3,a3,0x1
30001044:	00f6d463          	bge	a3,a5,3000104c <main+0x650>
30001048:	ffff86b7          	lui	a3,0xffff8
3000104c:	000087b7          	lui	a5,0x8
30001050:	00f6c463          	blt	a3,a5,30001058 <main+0x65c>
30001054:	fff78693          	addi	a3,a5,-1 # 7fff <hardware_spi_bootloader+0x7f7b>
30001058:	000088b7          	lui	a7,0x8
3000105c:	00000513          	li	a0,0
30001060:	00060813          	mv	a6,a2
30001064:	ffff8e37          	lui	t3,0xffff8
30001068:	fff88e93          	addi	t4,a7,-1 # 7fff <hardware_spi_bootloader+0x7f7b>
3000106c:	20200313          	li	t1,514
30001070:	00a587b3          	add	a5,a1,a0
30001074:	00079783          	lh	a5,0(a5)
30001078:	00081f03          	lh	t5,0(a6)
3000107c:	02d787b3          	mul	a5,a5,a3
30001080:	40f7d793          	srai	a5,a5,0xf
30001084:	01e787b3          	add	a5,a5,t5
30001088:	01c7d463          	bge	a5,t3,30001090 <main+0x694>
3000108c:	ffff87b7          	lui	a5,0xffff8
30001090:	0117c463          	blt	a5,a7,30001098 <main+0x69c>
30001094:	000e8793          	mv	a5,t4
30001098:	00f81023          	sh	a5,0(a6)
3000109c:	00250513          	addi	a0,a0,2
300010a0:	00280813          	addi	a6,a6,2
300010a4:	fc6516e3          	bne	a0,t1,30001070 <main+0x674>
300010a8:	e1090c93          	addi	s9,s2,-496
300010ac:	30004eb7          	lui	t4,0x30004
300010b0:	000c8693          	mv	a3,s9
300010b4:	b7ce8e93          	addi	t4,t4,-1156 # 30003b7c <sir_sq>
300010b8:	00061783          	lh	a5,0(a2)
300010bc:	00260613          	addi	a2,a2,2
300010c0:	00468693          	addi	a3,a3,4 # ffff8004 <_data_flash_start+0x7fff629c>
300010c4:	02f787b3          	mul	a5,a5,a5
300010c8:	fef6ae23          	sw	a5,-4(a3)
300010cc:	300047b7          	lui	a5,0x30004
300010d0:	b7a78793          	addi	a5,a5,-1158 # 30003b7a <proj_q15+0x202>
300010d4:	fec792e3          	bne	a5,a2,300010b8 <main+0x6bc>
300010d8:	00000313          	li	t1,0
300010dc:	00000513          	li	a0,0
300010e0:	00000e13          	li	t3,0
300010e4:	00000813          	li	a6,0
300010e8:	00000793          	li	a5,0
300010ec:	40400f13          	li	t5,1028
300010f0:	006a86b3          	add	a3,s5,t1
300010f4:	006e85b3          	add	a1,t4,t1
300010f8:	0006a603          	lw	a2,0(a3)
300010fc:	0005a883          	lw	a7,0(a1)
30001100:	00430313          	addi	t1,t1,4 # ffff0004 <_data_flash_start+0x7ffee29c>
30001104:	41f65693          	srai	a3,a2,0x1f
30001108:	41f8d593          	srai	a1,a7,0x1f
3000110c:	00c80633          	add	a2,a6,a2
30001110:	011508b3          	add	a7,a0,a7
30001114:	01063833          	sltu	a6,a2,a6
30001118:	00d786b3          	add	a3,a5,a3
3000111c:	00a8b533          	sltu	a0,a7,a0
30001120:	00be05b3          	add	a1,t3,a1
30001124:	00d806b3          	add	a3,a6,a3
30001128:	00b505b3          	add	a1,a0,a1
3000112c:	00060813          	mv	a6,a2
30001130:	00068793          	mv	a5,a3
30001134:	00088513          	mv	a0,a7
30001138:	00058e13          	mv	t3,a1
3000113c:	fbe31ae3          	bne	t1,t5,300010f0 <main+0x6f4>
30001140:	00001eb7          	lui	t4,0x1
30001144:	ccde8e93          	addi	t4,t4,-819 # ccd <hardware_spi_bootloader+0xc49>
30001148:	03d63833          	mulhu	a6,a2,t4
3000114c:	03d687b3          	mul	a5,a3,t4
30001150:	03d60333          	mul	t1,a2,t4
30001154:	010787b3          	add	a5,a5,a6
30001158:	01179e93          	slli	t4,a5,0x11
3000115c:	40f7d793          	srai	a5,a5,0xf
30001160:	00f35813          	srli	a6,t1,0xf
30001164:	010ee833          	or	a6,t4,a6
30001168:	00b7c663          	blt	a5,a1,30001174 <main+0x778>
3000116c:	4af59463          	bne	a1,a5,30001614 <main+0xc18>
30001170:	4b187263          	bgeu	a6,a7,30001614 <main+0xc18>
30001174:	00d04663          	bgtz	a3,30001180 <main+0x784>
30001178:	4a069263          	bnez	a3,3000161c <main+0xc20>
3000117c:	4a060063          	beqz	a2,3000161c <main+0xc20>
30001180:	00010537          	lui	a0,0x10
30001184:	ffe50513          	addi	a0,a0,-2 # fffe <hardware_spi_bootloader+0xff7a>
30001188:	02a585b3          	mul	a1,a1,a0
3000118c:	02a8b7b3          	mulhu	a5,a7,a0
30001190:	02a88533          	mul	a0,a7,a0
30001194:	00f585b3          	add	a1,a1,a5
30001198:	fb1fe0ef          	jal	ra,30000148 <__divdi3>
3000119c:	48b04063          	bgtz	a1,3000161c <main+0xc20>
300011a0:	00059663          	bnez	a1,300011ac <main+0x7b0>
300011a4:	000087b7          	lui	a5,0x8
300011a8:	46f57a63          	bgeu	a0,a5,3000161c <main+0xc20>
300011ac:	01051b13          	slli	s6,a0,0x10
300011b0:	410b5b13          	srai	s6,s6,0x10
300011b4:	300026b7          	lui	a3,0x30002
300011b8:	d686a783          	lw	a5,-664(a3) # 30001d68 <first_frame>
300011bc:	02d12623          	sw	a3,44(sp)
300011c0:	000036b7          	lui	a3,0x3
300011c4:	02f12223          	sw	a5,36(sp)
300011c8:	300037b7          	lui	a5,0x30003
300011cc:	96c78d93          	addi	s11,a5,-1684 # 3000296c <prev_mask_q15>
300011d0:	33368793          	addi	a5,a3,819 # 3333 <hardware_spi_bootloader+0x32af>
300011d4:	000056b7          	lui	a3,0x5
300011d8:	02f12823          	sw	a5,48(sp)
300011dc:	ccd68793          	addi	a5,a3,-819 # 4ccd <hardware_spi_bootloader+0x4c49>
300011e0:	00000d13          	li	s10,0
300011e4:	02f12a23          	sw	a5,52(sp)
300011e8:	21490a93          	addi	s5,s2,532
300011ec:	000ba603          	lw	a2,0(s7)
300011f0:	000ca503          	lw	a0,0(s9)
300011f4:	00000593          	li	a1,0
300011f8:	06c05263          	blez	a2,3000125c <main+0x860>
300011fc:	40a60533          	sub	a0,a2,a0
30001200:	00055463          	bgez	a0,30001208 <main+0x80c>
30001204:	00000513          	li	a0,0
30001208:	41f55593          	srai	a1,a0,0x1f
3000120c:	01155313          	srli	t1,a0,0x11
30001210:	00f59593          	slli	a1,a1,0xf
30001214:	41f65693          	srai	a3,a2,0x1f
30001218:	00f51513          	slli	a0,a0,0xf
3000121c:	00b365b3          	or	a1,t1,a1
30001220:	f29fe0ef          	jal	ra,30000148 <__divdi3>
30001224:	000087b7          	lui	a5,0x8
30001228:	00050693          	mv	a3,a0
3000122c:	00f54463          	blt	a0,a5,30001234 <main+0x838>
30001230:	fff78693          	addi	a3,a5,-1 # 7fff <hardware_spi_bootloader+0x7f7b>
30001234:	00000593          	li	a1,0
30001238:	02a05263          	blez	a0,3000125c <main+0x860>
3000123c:	00f69513          	slli	a0,a3,0xf
30001240:	dc1fe0ef          	jal	ra,30000000 <isqrt_bin>
30001244:	01051793          	slli	a5,a0,0x10
30001248:	0007d663          	bgez	a5,30001254 <main+0x858>
3000124c:	000087b7          	lui	a5,0x8
30001250:	fff78513          	addi	a0,a5,-1 # 7fff <hardware_spi_bootloader+0x7f7b>
30001254:	01051593          	slli	a1,a0,0x10
30001258:	4105d593          	srai	a1,a1,0x10
3000125c:	14800613          	li	a2,328
30001260:	00058693          	mv	a3,a1
30001264:	00c5d463          	bge	a1,a2,3000126c <main+0x870>
30001268:	14800693          	li	a3,328
3000126c:	02412783          	lw	a5,36(sp)
30001270:	01069693          	slli	a3,a3,0x10
30001274:	4106d693          	srai	a3,a3,0x10
30001278:	02079063          	bnez	a5,30001298 <main+0x89c>
3000127c:	03012783          	lw	a5,48(sp)
30001280:	000d9603          	lh	a2,0(s11)
30001284:	02f60633          	mul	a2,a2,a5
30001288:	03412783          	lw	a5,52(sp)
3000128c:	02f686b3          	mul	a3,a3,a5
30001290:	00d606b3          	add	a3,a2,a3
30001294:	40f6d693          	srai	a3,a3,0xf
30001298:	01069693          	slli	a3,a3,0x10
3000129c:	4106d693          	srai	a3,a3,0x10
300012a0:	01aa8633          	add	a2,s5,s10
300012a4:	00dd9023          	sh	a3,0(s11)
300012a8:	00d61023          	sh	a3,0(a2)
300012ac:	002d0d13          	addi	s10,s10,2
300012b0:	20200693          	li	a3,514
300012b4:	004b8b93          	addi	s7,s7,4
300012b8:	004c8c93          	addi	s9,s9,4
300012bc:	002d8d93          	addi	s11,s11,2
300012c0:	f2dd16e3          	bne	s10,a3,300011ec <main+0x7f0>
300012c4:	00008cb7          	lui	s9,0x8
300012c8:	02c12783          	lw	a5,44(sp)
300012cc:	01812603          	lw	a2,24(sp)
300012d0:	01412683          	lw	a3,20(sp)
300012d4:	fffc8c93          	addi	s9,s9,-1 # 7fff <hardware_spi_bootloader+0x7f7b>
300012d8:	416c8833          	sub	a6,s9,s6
300012dc:	01081813          	slli	a6,a6,0x10
300012e0:	d607a423          	sw	zero,-664(a5)
300012e4:	41085813          	srai	a6,a6,0x10
300012e8:	00068d13          	mv	s10,a3
300012ec:	00060d93          	mv	s11,a2
300012f0:	fff00593          	li	a1,-1
300012f4:	00008eb7          	lui	t4,0x8
300012f8:	0fe00e13          	li	t3,254
300012fc:	1fe00313          	li	t1,510
30001300:	000a9b83          	lh	s7,0(s5)
30001304:	00000513          	li	a0,0
30001308:	07705263          	blez	s7,3000136c <main+0x970>
3000130c:	037b88b3          	mul	a7,s7,s7
30001310:	00fb9513          	slli	a0,s7,0xf
30001314:	02c12e23          	sw	a2,60(sp)
30001318:	02d12a23          	sw	a3,52(sp)
3000131c:	02b12823          	sw	a1,48(sp)
30001320:	03012623          	sw	a6,44(sp)
30001324:	40f8d893          	srai	a7,a7,0xf
30001328:	03112223          	sw	a7,36(sp)
3000132c:	cd5fe0ef          	jal	ra,30000000 <isqrt_bin>
30001330:	01051793          	slli	a5,a0,0x10
30001334:	02412883          	lw	a7,36(sp)
30001338:	02c12803          	lw	a6,44(sp)
3000133c:	03012583          	lw	a1,48(sp)
30001340:	03412683          	lw	a3,52(sp)
30001344:	03c12603          	lw	a2,60(sp)
30001348:	0fe00e13          	li	t3,254
3000134c:	1fe00313          	li	t1,510
30001350:	00008eb7          	lui	t4,0x8
30001354:	0007d463          	bgez	a5,3000135c <main+0x960>
30001358:	000c8513          	mv	a0,s9
3000135c:	03150533          	mul	a0,a0,a7
30001360:	40f55513          	srai	a0,a0,0xf
30001364:	01051513          	slli	a0,a0,0x10
30001368:	41055513          	srai	a0,a0,0x10
3000136c:	03780bb3          	mul	s7,a6,s7
30001370:	03650533          	mul	a0,a0,s6
30001374:	00ab8533          	add	a0,s7,a0
30001378:	40f55893          	srai	a7,a0,0xf
3000137c:	00055463          	bgez	a0,30001384 <main+0x988>
30001380:	00000893          	li	a7,0
30001384:	00088f13          	mv	t5,a7
30001388:	01d8c463          	blt	a7,t4,30001390 <main+0x994>
3000138c:	000c8f13          	mv	t5,s9
30001390:	000d9883          	lh	a7,0(s11)
30001394:	000d1503          	lh	a0,0(s10)
30001398:	03e888b3          	mul	a7,a7,t5
3000139c:	03e50533          	mul	a0,a0,t5
300013a0:	40f8d893          	srai	a7,a7,0xf
300013a4:	01089893          	slli	a7,a7,0x10
300013a8:	4108d893          	srai	a7,a7,0x10
300013ac:	011d9023          	sh	a7,0(s11)
300013b0:	40f55513          	srai	a0,a0,0xf
300013b4:	00ad1023          	sh	a0,0(s10)
300013b8:	02be6063          	bltu	t3,a1,300013d8 <main+0x9dc>
300013bc:	01812783          	lw	a5,24(sp)
300013c0:	40a00533          	neg	a0,a0
300013c4:	01878f33          	add	t5,a5,s8
300013c8:	01412783          	lw	a5,20(sp)
300013cc:	011f1023          	sh	a7,0(t5)
300013d0:	018788b3          	add	a7,a5,s8
300013d4:	00a89023          	sh	a0,0(a7)
300013d8:	ffec0c13          	addi	s8,s8,-2
300013dc:	002a8a93          	addi	s5,s5,2
300013e0:	002d8d93          	addi	s11,s11,2
300013e4:	002d0d13          	addi	s10,s10,2
300013e8:	00158593          	addi	a1,a1,1
300013ec:	f06c1ae3          	bne	s8,t1,30001300 <main+0x904>
300013f0:	00000513          	li	a0,0
300013f4:	20000813          	li	a6,512
300013f8:	00050593          	mv	a1,a0
300013fc:	00000793          	li	a5,0
30001400:	00900713          	li	a4,9
30001404:	0015f893          	andi	a7,a1,1
30001408:	00179793          	slli	a5,a5,0x1
3000140c:	fff70713          	addi	a4,a4,-1
30001410:	00f8e7b3          	or	a5,a7,a5
30001414:	0015d593          	srli	a1,a1,0x1
30001418:	fe0716e3          	bnez	a4,30001404 <main+0xa08>
3000141c:	0006d583          	lhu	a1,0(a3)
30001420:	00065883          	lhu	a7,0(a2)
30001424:	00279793          	slli	a5,a5,0x2
30001428:	01059593          	slli	a1,a1,0x10
3000142c:	0115e5b3          	or	a1,a1,a7
30001430:	00f987b3          	add	a5,s3,a5
30001434:	00b7a023          	sw	a1,0(a5)
30001438:	00150513          	addi	a0,a0,1
3000143c:	00260613          	addi	a2,a2,2
30001440:	00268693          	addi	a3,a3,2
30001444:	fb051ae3          	bne	a0,a6,300013f8 <main+0x9fc>
30001448:	00100693          	li	a3,1
3000144c:	600017b7          	lui	a5,0x60001
30001450:	c0d7a023          	sw	a3,-1024(a5) # 60000c00 <_stack_top+0x2fff8c00>
30001454:	600016b7          	lui	a3,0x60001
30001458:	c006a783          	lw	a5,-1024(a3) # 60000c00 <_stack_top+0x2fff8c00>
3000145c:	0027f793          	andi	a5,a5,2
30001460:	fe078ce3          	beqz	a5,30001458 <main+0xa5c>
30001464:	000017b7          	lui	a5,0x1
30001468:	04010693          	addi	a3,sp,64
3000146c:	81078793          	addi	a5,a5,-2032 # 810 <hardware_spi_bootloader+0x78c>
30001470:	00d787b3          	add	a5,a5,a3
30001474:	00a49593          	slli	a1,s1,0xa
30001478:	000016b7          	lui	a3,0x1
3000147c:	00b785b3          	add	a1,a5,a1
30001480:	80068693          	addi	a3,a3,-2048 # 800 <hardware_spi_bootloader+0x77c>
30001484:	00058793          	mv	a5,a1
30001488:	00d989b3          	add	s3,s3,a3
3000148c:	01012683          	lw	a3,16(sp)
30001490:	00278793          	addi	a5,a5,2
30001494:	0006a683          	lw	a3,0(a3)
30001498:	fed79f23          	sh	a3,-2(a5)
3000149c:	01012683          	lw	a3,16(sp)
300014a0:	00468693          	addi	a3,a3,4
300014a4:	00d12823          	sw	a3,16(sp)
300014a8:	fed992e3          	bne	s3,a3,3000148c <main+0xa90>
300014ac:	000017b7          	lui	a5,0x1
300014b0:	04010613          	addi	a2,sp,64
300014b4:	fffff6b7          	lui	a3,0xfffff
300014b8:	01078793          	addi	a5,a5,16 # 1010 <hardware_spi_bootloader+0xf8c>
300014bc:	00c787b3          	add	a5,a5,a2
300014c0:	40068693          	addi	a3,a3,1024 # fffff400 <_data_flash_start+0x7fffd698>
300014c4:	00d786b3          	add	a3,a5,a3
300014c8:	00949793          	slli	a5,s1,0x9
300014cc:	00f686b3          	add	a3,a3,a5
300014d0:	300067b7          	lui	a5,0x30006
300014d4:	18478613          	addi	a2,a5,388 # 30006184 <ola_buffer>
300014d8:	40000813          	li	a6,1024
300014dc:	03812503          	lw	a0,56(sp)
300014e0:	00e587b3          	add	a5,a1,a4
300014e4:	00079783          	lh	a5,0(a5)
300014e8:	00e50533          	add	a0,a0,a4
300014ec:	00051503          	lh	a0,0(a0)
300014f0:	00270713          	addi	a4,a4,2
300014f4:	00460613          	addi	a2,a2,4
300014f8:	02a787b3          	mul	a5,a5,a0
300014fc:	ffc62503          	lw	a0,-4(a2)
30001500:	40f7d793          	srai	a5,a5,0xf
30001504:	00f507b3          	add	a5,a0,a5
30001508:	fef62e23          	sw	a5,-4(a2)
3000150c:	fd0718e3          	bne	a4,a6,300014dc <main+0xae0>
30001510:	01c12603          	lw	a2,28(sp)
30001514:	300067b7          	lui	a5,0x30006
30001518:	00008837          	lui	a6,0x8
3000151c:	20068893          	addi	a7,a3,512
30001520:	18478593          	addi	a1,a5,388 # 30006184 <ola_buffer>
30001524:	ffff8337          	lui	t1,0xffff8
30001528:	fff80e13          	addi	t3,a6,-1 # 7fff <hardware_spi_bootloader+0x7f7b>
3000152c:	0005a703          	lw	a4,0(a1)
30001530:	00062783          	lw	a5,0(a2)
30001534:	02f70533          	mul	a0,a4,a5
30001538:	02f717b3          	mulh	a5,a4,a5
3000153c:	00f55713          	srli	a4,a0,0xf
30001540:	01179793          	slli	a5,a5,0x11
30001544:	00e7e7b3          	or	a5,a5,a4
30001548:	0067d463          	bge	a5,t1,30001550 <main+0xb54>
3000154c:	ffff87b7          	lui	a5,0xffff8
30001550:	0107c463          	blt	a5,a6,30001558 <main+0xb5c>
30001554:	000e0793          	mv	a5,t3
30001558:	00f69023          	sh	a5,0(a3)
3000155c:	00268693          	addi	a3,a3,2
30001560:	00458593          	addi	a1,a1,4
30001564:	00460613          	addi	a2,a2,4
30001568:	fcd892e3          	bne	a7,a3,3000152c <main+0xb30>
3000156c:	300067b7          	lui	a5,0x30006
30001570:	18478713          	addi	a4,a5,388 # 30006184 <ola_buffer>
30001574:	40070713          	addi	a4,a4,1024
30001578:	18478793          	addi	a5,a5,388
3000157c:	4007a683          	lw	a3,1024(a5)
30001580:	00478793          	addi	a5,a5,4
30001584:	fed7ae23          	sw	a3,-4(a5)
30001588:	fee79ae3          	bne	a5,a4,3000157c <main+0xb80>
3000158c:	300067b7          	lui	a5,0x30006
30001590:	18478793          	addi	a5,a5,388 # 30006184 <ola_buffer>
30001594:	4007a023          	sw	zero,1024(a5)
30001598:	00478793          	addi	a5,a5,4
3000159c:	fee79ce3          	bne	a5,a4,30001594 <main+0xb98>
300015a0:	00048513          	mv	a0,s1
300015a4:	a9dfe0ef          	jal	ra,30000040 <wait_and_unpack_dma.constprop.0>
300015a8:	222207b7          	lui	a5,0x22220
300015ac:	00fa67b3          	or	a5,s4,a5
300015b0:	300074b7          	lui	s1,0x30007
300015b4:	00f4a023          	sw	a5,0(s1) # 30007000 <input_write_ptr+0x67c>
300015b8:	001a0a13          	addi	s4,s4,1
300015bc:	00800793          	li	a5,8
300015c0:	82fa1ae3          	bne	s4,a5,30000df4 <main+0x3f8>
300015c4:	000017b7          	lui	a5,0x1
300015c8:	04010713          	addi	a4,sp,64
300015cc:	01078793          	addi	a5,a5,16 # 1010 <hardware_spi_bootloader+0xf8c>
300015d0:	00e787b3          	add	a5,a5,a4
300015d4:	fffff537          	lui	a0,0xfffff
300015d8:	00a78533          	add	a0,a5,a0
300015dc:	00000593          	li	a1,0
300015e0:	60050513          	addi	a0,a0,1536 # fffff600 <_data_flash_start+0x7fffd898>
300015e4:	ae9fe0ef          	jal	ra,300000cc <pack_and_start_dma.constprop.0>
300015e8:	00000513          	li	a0,0
300015ec:	a55fe0ef          	jal	ra,30000040 <wait_and_unpack_dma.constprop.0>
300015f0:	555557b7          	lui	a5,0x55555
300015f4:	55578793          	addi	a5,a5,1365 # 55555555 <_stack_top+0x2554d555>
300015f8:	00f4a023          	sw	a5,0(s1)
300015fc:	0000006f          	j	300015fc <main+0xc00>
30001600:	000017b7          	lui	a5,0x1
30001604:	01078793          	addi	a5,a5,16 # 1010 <hardware_spi_bootloader+0xf8c>
30001608:	04010713          	addi	a4,sp,64
3000160c:	00e787b3          	add	a5,a5,a4
30001610:	8cdff06f          	j	30000edc <main+0x4e0>
30001614:	00000b13          	li	s6,0
30001618:	b9dff06f          	j	300011b4 <main+0x7b8>
3000161c:	000087b7          	lui	a5,0x8
30001620:	fff78b13          	addi	s6,a5,-1 # 7fff <hardware_spi_bootloader+0x7f7b>
30001624:	b91ff06f          	j	300011b4 <main+0x7b8>

30001628 <fft_twiddles>:
30001628:	7fff0000 7ffdfe6e 7ff5fcdc 7fe9fb4a     ....n.......J...
30001638:	7fd8f9b8 7fc1f827 7fa6f696 7f86f505     ....'...........
30001648:	7f61f374 7f37f1e4 7f09f055 7ed5eec6     t.a...7.U......~
30001658:	7e9ced38 7e5febab 7e1dea1e 7dd5e892     8..~.._~...~...}
30001668:	7d89e707 7d39e57e 7ce3e3f5 7c88e26d     ...}~.9}...|m..|
30001678:	7c29e0e6 7bc5df61 7b5cdddd 7aeedc5a     ..)|a..{..\{Z..z
30001688:	7a7cdad8 7a05d958 7989d7da 7909d65d     ..|zX..z...y]..y
30001698:	7884d4e1 77fad367 776bd1ef 76d8d079     ...xg..w..kwy..v
300016a8:	7641cf05 75a5cd92 7504cc21 745fcab3     ..Av...u!..u.._t
300016b8:	73b5c946 7307c7dc 7254c674 719dc50e     F..s...st.Tr...q
300016c8:	70e2c3aa 7022c248 6f5ec0e9 6e96bf8d     ...pH."p..^o...n
300016d8:	6dc9be32 6cf8bcdb 6c23bb86 6b4aba33     2..m...l..#l3.Jk
300016e8:	6a6db8e4 698bb797 68a6b64c 67bcb505     ..mj...iL..h...g
300016f8:	66cfb3c1 65ddb27f 64e8b141 63eeb005     ...f...eA..d...c
30001708:	62f1aecd 61f0ad98 60ebac65 5fe3ab37     ...b...ae..`7.._
30001718:	5ed7aa0b 5dc7a8e3 5cb3a7be 5b9ca69c     ...^...]...\...[
30001728:	5a82a57e 5964a464 5842a34d 571da239     ~..Zd.dYM.BX9..W
30001738:	55f5a129 54c9a01d 539b9f15 52689e10     )..U...T...S..hR
30001748:	51339d0f 4ffb9c12 4ebf9b18 4d819a23     ..3Q...O...N#..M
30001758:	4c3f9931 4afb9844 49b4975a 48699675     1.?LD..JZ..Iu.iH
30001768:	471c9593 45cd94b6 447a93dd 43259308     ...G...E..zD..%C
30001778:	41ce9237 4073916a 3f1790a2 3db88fde     7..Aj.s@...?...=
30001788:	3c568f1e 3af28e63 398c8dac 38248cf9     ..V<c..:...9..$8
30001798:	36ba8c4b 354d8ba1 33df8afc 326e8a5b     K..6..M5...3[.n2
300017a8:	30fb89bf 2f878928 2e118895 2c998806     ...0(../.......,
300017b8:	2b1f877c 29a386f7 28268677 26a885fb     |..+...)w.&(...&
300017c8:	25288584 23a68512 222384a4 209f843b     ..(%...#..#";.. 
300017d8:	1f1a83d7 1d938378 1c0b831d 1a8282c7     ....x...........
300017e8:	18f98277 176e822b 15e281e3 145581a1     w...+.n.......U.
300017f8:	12c88164 113a812b 0fab80f7 0e1c80c9     d...+.:.........
30001808:	0c8c809f 0afb807a 096a805a 07d9803f     ....z...Z.j.?...
30001818:	06488028 04b68017 0324800b 01928003     (.H.......$.....
30001828:	00008001 fe6e8003 fcdc800b fb4a8017     ......n.......J.
30001838:	f9b88028 f827803f f696805a f505807a     (...?.'.Z...z...
30001848:	f374809f f1e480c9 f05580f7 eec6812b     ..t.......U.+...
30001858:	ed388164 ebab81a1 ea1e81e3 e892822b     d.8.........+...
30001868:	e7078277 e57e82c7 e3f5831d e26d8378     w.....~.....x.m.
30001878:	e0e683d7 df61843b dddd84a4 dc5a8512     ....;.a.......Z.
30001888:	dad88584 d95885fb d7da8677 d65d86f7     ......X.w.....].
30001898:	d4e1877c d3678806 d1ef8895 d0798928     |.....g.....(.y.
300018a8:	cf0589bf cd928a5b cc218afc cab38ba1     ....[.....!.....
300018b8:	c9468c4b c7dc8cf9 c6748dac c50e8e63     K.F.......t.c...
300018c8:	c3aa8f1e c2488fde c0e990a2 bf8d916a     ......H.....j...
300018d8:	be329237 bcdb9308 bb8693dd ba3394b6     7.2...........3.
300018e8:	b8e49593 b7979675 b64c975a b5059844     ....u...Z.L.D...
300018f8:	b3c19931 b27f9a23 b1419b18 b0059c12     1...#.....A.....
30001908:	aecd9d0f ad989e10 ac659f15 ab37a01d     ..........e...7.
30001918:	aa0ba129 a8e3a239 a7bea34d a69ca464     )...9...M...d...
30001928:	a57ea57e a464a69c a34da7be a239a8e3     ~.~...d...M...9.
30001938:	a129aa0b a01dab37 9f15ac65 9e10ad98     ..).7...e.......
30001948:	9d0faecd 9c12b005 9b18b141 9a23b27f     ........A.....#.
30001958:	9931b3c1 9844b505 975ab64c 9675b797     ..1...D.L.Z...u.
30001968:	9593b8e4 94b6ba33 93ddbb86 9308bcdb     ....3...........
30001978:	9237be32 916abf8d 90a2c0e9 8fdec248     2.7...j.....H...
30001988:	8f1ec3aa 8e63c50e 8dacc674 8cf9c7dc     ......c.t.......
30001998:	8c4bc946 8ba1cab3 8afccc21 8a5bcd92     F.K.....!.....[.
300019a8:	89bfcf05 8928d079 8895d1ef 8806d367     ....y.(.....g...
300019b8:	877cd4e1 86f7d65d 8677d7da 85fbd958     ..|.].....w.X...
300019c8:	8584dad8 8512dc5a 84a4dddd 843bdf61     ....Z.......a.;.
300019d8:	83d7e0e6 8378e26d 831de3f5 82c7e57e     ....m.x.....~...
300019e8:	8277e707 822be892 81e3ea1e 81a1ebab     ..w...+.........
300019f8:	8164ed38 812beec6 80f7f055 80c9f1e4     8.d...+.U.......
30001a08:	809ff374 807af505 805af696 803ff827     t.....z...Z.'.?.
30001a18:	8028f9b8 8017fb4a 800bfcdc 8003fe6e     ..(.J.......n...

30001a28 <trigger_vecs_q15>:
	...

30001c2c <__clz_tab>:
30001c2c:	02020100 03030303 04040404 04040404     ................
30001c3c:	05050505 05050505 05050505 05050505     ................
30001c4c:	06060606 06060606 06060606 06060606     ................
30001c5c:	06060606 06060606 06060606 06060606     ................
30001c6c:	07070707 07070707 07070707 07070707     ................
30001c7c:	07070707 07070707 07070707 07070707     ................
30001c8c:	07070707 07070707 07070707 07070707     ................
30001c9c:	07070707 07070707 07070707 07070707     ................
30001cac:	08080808 08080808 08080808 08080808     ................
30001cbc:	08080808 08080808 08080808 08080808     ................
30001ccc:	08080808 08080808 08080808 08080808     ................
30001cdc:	08080808 08080808 08080808 08080808     ................
30001cec:	08080808 08080808 08080808 08080808     ................
30001cfc:	08080808 08080808 08080808 08080808     ................
30001d0c:	08080808 08080808 08080808 08080808     ................
30001d1c:	08080808 08080808 08080808 08080808     ................
