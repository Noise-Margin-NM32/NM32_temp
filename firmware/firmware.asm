
firmware.elf:     file format elf32-littleriscv


Disassembly of section .boot:

00000000 <_start>:
   0:	30008117          	auipc	sp,0x30008
   4:	00010113          	mv	sp,sp
   8:	07c000ef          	jal	ra,84 <hardware_spi_bootloader>
   c:	30002517          	auipc	a0,0x30002
  10:	cc450513          	addi	a0,a0,-828 # 30001cd0 <input_buffer>
  14:	30005597          	auipc	a1,0x30005
  18:	8d458593          	addi	a1,a1,-1836 # 300048e8 <input_write_ptr>
  1c:	00b55863          	bge	a0,a1,2c <end_init_bss>

00000020 <loop_init_bss>:
  20:	00052023          	sw	zero,0(a0)
  24:	00450513          	addi	a0,a0,4
  28:	feb54ce3          	blt	a0,a1,20 <loop_init_bss>

0000002c <end_init_bss>:
  2c:	30001517          	auipc	a0,0x30001
  30:	96850513          	addi	a0,a0,-1688 # 30000994 <main>
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
  84:	fe010113          	addi	sp,sp,-32 # 30007fe0 <input_write_ptr+0x36f8>
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
  c0:	c9090913          	addi	s2,s2,-880 # 30001c90 <_text_ram_end>
  c4:	f0098993          	addi	s3,s3,-256 # ff00 <hardware_spi_bootloader+0xfe7c>
  c8:	00ff0a37          	lui	s4,0xff0
  cc:	05246663          	bltu	s0,s2,118 <hardware_spi_bootloader+0x94>
  d0:	000024b7          	lui	s1,0x2
  d4:	30002437          	lui	s0,0x30002
  d8:	30002937          	lui	s2,0x30002
  dc:	000109b7          	lui	s3,0x10
  e0:	ccc48493          	addi	s1,s1,-820 # 1ccc <hardware_spi_bootloader+0x1c48>
  e4:	ccc40413          	addi	s0,s0,-820 # 30001ccc <first_frame>
  e8:	ccc90913          	addi	s2,s2,-820 # 30001ccc <first_frame>
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

30000040 <io_hop>:
30000040:	30005737          	lui	a4,0x30005
30000044:	8e872783          	lw	a5,-1816(a4) # 300048e8 <input_write_ptr>
30000048:	30002337          	lui	t1,0x30002
3000004c:	00000613          	li	a2,0
30000050:	00070693          	mv	a3,a4
30000054:	20020eb7          	lui	t4,0x20020
30000058:	00e00f13          	li	t5,14
3000005c:	20010837          	lui	a6,0x20010
30000060:	20000e37          	lui	t3,0x20000
30000064:	cd030313          	addi	t1,t1,-816 # 30001cd0 <input_buffer>
30000068:	20000f93          	li	t6,512
3000006c:	00161713          	slli	a4,a2,0x1
30000070:	00e50733          	add	a4,a0,a4
30000074:	00071703          	lh	a4,0(a4)
30000078:	e00ea883          	lw	a7,-512(t4) # 2001fe00 <hardware_spi_bootloader+0x2001fd7c>
3000007c:	ff1f6ee3          	bltu	t5,a7,30000078 <io_hop+0x38>
30000080:	01071713          	slli	a4,a4,0x10
30000084:	01075713          	srli	a4,a4,0x10
30000088:	00e82023          	sw	a4,0(a6) # 20010000 <hardware_spi_bootloader+0x2000ff7c>
3000008c:	e00ea703          	lw	a4,-512(t4)
30000090:	feef6ee3          	bltu	t5,a4,3000008c <io_hop+0x4c>
30000094:	00082023          	sw	zero,0(a6)
30000098:	e0082703          	lw	a4,-512(a6)
3000009c:	fe070ee3          	beqz	a4,30000098 <io_hop+0x58>
300000a0:	000e2703          	lw	a4,0(t3) # 20000000 <hardware_spi_bootloader+0x1fffff7c>
300000a4:	00171713          	slli	a4,a4,0x1
300000a8:	01071713          	slli	a4,a4,0x10
300000ac:	41075713          	srai	a4,a4,0x10
300000b0:	e0082883          	lw	a7,-512(a6)
300000b4:	fe088ee3          	beqz	a7,300000b0 <io_hop+0x70>
300000b8:	000e2883          	lw	a7,0(t3)
300000bc:	00160613          	addi	a2,a2,1
300000c0:	00179893          	slli	a7,a5,0x1
300000c4:	011308b3          	add	a7,t1,a7
300000c8:	00178793          	addi	a5,a5,1 # 40000001 <_stack_top+0xfff8001>
300000cc:	00e89023          	sh	a4,0(a7)
300000d0:	03f7e7b3          	rem	a5,a5,t6
300000d4:	f8c59ce3          	bne	a1,a2,3000006c <io_hop+0x2c>
300000d8:	8ef6a423          	sw	a5,-1816(a3)
300000dc:	00008067          	ret

300000e0 <__divdi3>:
300000e0:	00050e93          	mv	t4,a0
300000e4:	00000813          	li	a6,0
300000e8:	0005dc63          	bgez	a1,30000100 <__divdi3+0x20>
300000ec:	00a037b3          	snez	a5,a0
300000f0:	40b005b3          	neg	a1,a1
300000f4:	40f585b3          	sub	a1,a1,a5
300000f8:	40a00eb3          	neg	t4,a0
300000fc:	fff00813          	li	a6,-1
30000100:	0006dc63          	bgez	a3,30000118 <__divdi3+0x38>
30000104:	00c037b3          	snez	a5,a2
30000108:	40d006b3          	neg	a3,a3
3000010c:	fff84813          	not	a6,a6
30000110:	40f686b3          	sub	a3,a3,a5
30000114:	40c00633          	neg	a2,a2
30000118:	00060893          	mv	a7,a2
3000011c:	00068713          	mv	a4,a3
30000120:	000e8e13          	mv	t3,t4
30000124:	00058513          	mv	a0,a1
30000128:	2a069063          	bnez	a3,300003c8 <__divdi3+0x2e8>
3000012c:	00002697          	auipc	a3,0x2
30000130:	a6468693          	addi	a3,a3,-1436 # 30001b90 <__clz_tab>
30000134:	0ec5f663          	bgeu	a1,a2,30000220 <__divdi3+0x140>
30000138:	000107b7          	lui	a5,0x10
3000013c:	0cf67863          	bgeu	a2,a5,3000020c <__divdi3+0x12c>
30000140:	0ff00793          	li	a5,255
30000144:	00c7b7b3          	sltu	a5,a5,a2
30000148:	00379793          	slli	a5,a5,0x3
3000014c:	00f65733          	srl	a4,a2,a5
30000150:	00e686b3          	add	a3,a3,a4
30000154:	0006c683          	lbu	a3,0(a3)
30000158:	00f687b3          	add	a5,a3,a5
3000015c:	02000693          	li	a3,32
30000160:	40f68733          	sub	a4,a3,a5
30000164:	00f68c63          	beq	a3,a5,3000017c <__divdi3+0x9c>
30000168:	00e595b3          	sll	a1,a1,a4
3000016c:	00fed7b3          	srl	a5,t4,a5
30000170:	00e618b3          	sll	a7,a2,a4
30000174:	00b7e533          	or	a0,a5,a1
30000178:	00ee9e33          	sll	t3,t4,a4
3000017c:	0108d313          	srli	t1,a7,0x10
30000180:	026556b3          	divu	a3,a0,t1
30000184:	01089593          	slli	a1,a7,0x10
30000188:	0105d593          	srli	a1,a1,0x10
3000018c:	010e5793          	srli	a5,t3,0x10
30000190:	02657733          	remu	a4,a0,t1
30000194:	00068613          	mv	a2,a3
30000198:	02d58533          	mul	a0,a1,a3
3000019c:	01071713          	slli	a4,a4,0x10
300001a0:	00f767b3          	or	a5,a4,a5
300001a4:	00a7fe63          	bgeu	a5,a0,300001c0 <__divdi3+0xe0>
300001a8:	011787b3          	add	a5,a5,a7
300001ac:	fff68613          	addi	a2,a3,-1
300001b0:	0117e863          	bltu	a5,a7,300001c0 <__divdi3+0xe0>
300001b4:	00a7f663          	bgeu	a5,a0,300001c0 <__divdi3+0xe0>
300001b8:	ffe68613          	addi	a2,a3,-2
300001bc:	011787b3          	add	a5,a5,a7
300001c0:	40a787b3          	sub	a5,a5,a0
300001c4:	0267f733          	remu	a4,a5,t1
300001c8:	010e1e13          	slli	t3,t3,0x10
300001cc:	010e5e13          	srli	t3,t3,0x10
300001d0:	0267d7b3          	divu	a5,a5,t1
300001d4:	01071713          	slli	a4,a4,0x10
300001d8:	01c76e33          	or	t3,a4,t3
300001dc:	02f586b3          	mul	a3,a1,a5
300001e0:	00078713          	mv	a4,a5
300001e4:	00de7c63          	bgeu	t3,a3,300001fc <__divdi3+0x11c>
300001e8:	01c88e33          	add	t3,a7,t3
300001ec:	fff78713          	addi	a4,a5,-1 # ffff <hardware_spi_bootloader+0xff7b>
300001f0:	011e6663          	bltu	t3,a7,300001fc <__divdi3+0x11c>
300001f4:	00de7463          	bgeu	t3,a3,300001fc <__divdi3+0x11c>
300001f8:	ffe78713          	addi	a4,a5,-2
300001fc:	01061513          	slli	a0,a2,0x10
30000200:	00e56533          	or	a0,a0,a4
30000204:	00000313          	li	t1,0
30000208:	0e40006f          	j	300002ec <__divdi3+0x20c>
3000020c:	01000737          	lui	a4,0x1000
30000210:	01000793          	li	a5,16
30000214:	f2e66ce3          	bltu	a2,a4,3000014c <__divdi3+0x6c>
30000218:	01800793          	li	a5,24
3000021c:	f31ff06f          	j	3000014c <__divdi3+0x6c>
30000220:	00061663          	bnez	a2,3000022c <__divdi3+0x14c>
30000224:	00100893          	li	a7,1
30000228:	02e8d8b3          	divu	a7,a7,a4
3000022c:	000107b7          	lui	a5,0x10
30000230:	0cf8fc63          	bgeu	a7,a5,30000308 <__divdi3+0x228>
30000234:	0ff00793          	li	a5,255
30000238:	0117f463          	bgeu	a5,a7,30000240 <__divdi3+0x160>
3000023c:	00800713          	li	a4,8
30000240:	00e8d7b3          	srl	a5,a7,a4
30000244:	00f686b3          	add	a3,a3,a5
30000248:	0006c783          	lbu	a5,0(a3)
3000024c:	02000693          	li	a3,32
30000250:	00e787b3          	add	a5,a5,a4
30000254:	40f68733          	sub	a4,a3,a5
30000258:	0cf69263          	bne	a3,a5,3000031c <__divdi3+0x23c>
3000025c:	411585b3          	sub	a1,a1,a7
30000260:	00100313          	li	t1,1
30000264:	0108d513          	srli	a0,a7,0x10
30000268:	01089613          	slli	a2,a7,0x10
3000026c:	01065613          	srli	a2,a2,0x10
30000270:	010e5713          	srli	a4,t3,0x10
30000274:	02a5d7b3          	divu	a5,a1,a0
30000278:	02a5f6b3          	remu	a3,a1,a0
3000027c:	02f605b3          	mul	a1,a2,a5
30000280:	01069693          	slli	a3,a3,0x10
30000284:	00e6e733          	or	a4,a3,a4
30000288:	00078693          	mv	a3,a5
3000028c:	00b77e63          	bgeu	a4,a1,300002a8 <__divdi3+0x1c8>
30000290:	01170733          	add	a4,a4,a7
30000294:	fff78693          	addi	a3,a5,-1 # ffff <hardware_spi_bootloader+0xff7b>
30000298:	01176863          	bltu	a4,a7,300002a8 <__divdi3+0x1c8>
3000029c:	00b77663          	bgeu	a4,a1,300002a8 <__divdi3+0x1c8>
300002a0:	ffe78693          	addi	a3,a5,-2
300002a4:	01170733          	add	a4,a4,a7
300002a8:	40b70733          	sub	a4,a4,a1
300002ac:	02a777b3          	remu	a5,a4,a0
300002b0:	010e1e13          	slli	t3,t3,0x10
300002b4:	010e5e13          	srli	t3,t3,0x10
300002b8:	02a75733          	divu	a4,a4,a0
300002bc:	01079793          	slli	a5,a5,0x10
300002c0:	01c7ee33          	or	t3,a5,t3
300002c4:	02e60633          	mul	a2,a2,a4
300002c8:	00070793          	mv	a5,a4
300002cc:	00ce7c63          	bgeu	t3,a2,300002e4 <__divdi3+0x204>
300002d0:	01c88e33          	add	t3,a7,t3
300002d4:	fff70793          	addi	a5,a4,-1 # ffffff <hardware_spi_bootloader+0xffff7b>
300002d8:	011e6663          	bltu	t3,a7,300002e4 <__divdi3+0x204>
300002dc:	00ce7463          	bgeu	t3,a2,300002e4 <__divdi3+0x204>
300002e0:	ffe70793          	addi	a5,a4,-2
300002e4:	01069513          	slli	a0,a3,0x10
300002e8:	00f56533          	or	a0,a0,a5
300002ec:	00030593          	mv	a1,t1
300002f0:	00080a63          	beqz	a6,30000304 <__divdi3+0x224>
300002f4:	00a037b3          	snez	a5,a0
300002f8:	406005b3          	neg	a1,t1
300002fc:	40f585b3          	sub	a1,a1,a5
30000300:	40a00533          	neg	a0,a0
30000304:	00008067          	ret
30000308:	010007b7          	lui	a5,0x1000
3000030c:	01000713          	li	a4,16
30000310:	f2f8e8e3          	bltu	a7,a5,30000240 <__divdi3+0x160>
30000314:	01800713          	li	a4,24
30000318:	f29ff06f          	j	30000240 <__divdi3+0x160>
3000031c:	00e898b3          	sll	a7,a7,a4
30000320:	00f5d533          	srl	a0,a1,a5
30000324:	00ee9e33          	sll	t3,t4,a4
30000328:	00e595b3          	sll	a1,a1,a4
3000032c:	00fed7b3          	srl	a5,t4,a5
30000330:	0108de93          	srli	t4,a7,0x10
30000334:	00b7e633          	or	a2,a5,a1
30000338:	03d557b3          	divu	a5,a0,t4
3000033c:	01089593          	slli	a1,a7,0x10
30000340:	0105d593          	srli	a1,a1,0x10
30000344:	03d57733          	remu	a4,a0,t4
30000348:	01065513          	srli	a0,a2,0x10
3000034c:	00078313          	mv	t1,a5
30000350:	02f586b3          	mul	a3,a1,a5
30000354:	01071713          	slli	a4,a4,0x10
30000358:	00a76733          	or	a4,a4,a0
3000035c:	00d77e63          	bgeu	a4,a3,30000378 <__divdi3+0x298>
30000360:	01170733          	add	a4,a4,a7
30000364:	fff78313          	addi	t1,a5,-1 # ffffff <hardware_spi_bootloader+0xffff7b>
30000368:	01176863          	bltu	a4,a7,30000378 <__divdi3+0x298>
3000036c:	00d77663          	bgeu	a4,a3,30000378 <__divdi3+0x298>
30000370:	ffe78313          	addi	t1,a5,-2
30000374:	01170733          	add	a4,a4,a7
30000378:	40d706b3          	sub	a3,a4,a3
3000037c:	03d6f733          	remu	a4,a3,t4
30000380:	01061613          	slli	a2,a2,0x10
30000384:	01065613          	srli	a2,a2,0x10
30000388:	03d6d6b3          	divu	a3,a3,t4
3000038c:	01071713          	slli	a4,a4,0x10
30000390:	02d587b3          	mul	a5,a1,a3
30000394:	00c765b3          	or	a1,a4,a2
30000398:	00068713          	mv	a4,a3
3000039c:	00f5fe63          	bgeu	a1,a5,300003b8 <__divdi3+0x2d8>
300003a0:	011585b3          	add	a1,a1,a7
300003a4:	fff68713          	addi	a4,a3,-1
300003a8:	0115e863          	bltu	a1,a7,300003b8 <__divdi3+0x2d8>
300003ac:	00f5f663          	bgeu	a1,a5,300003b8 <__divdi3+0x2d8>
300003b0:	ffe68713          	addi	a4,a3,-2
300003b4:	011585b3          	add	a1,a1,a7
300003b8:	01031313          	slli	t1,t1,0x10
300003bc:	40f585b3          	sub	a1,a1,a5
300003c0:	00e36333          	or	t1,t1,a4
300003c4:	ea1ff06f          	j	30000264 <__divdi3+0x184>
300003c8:	18d5e663          	bltu	a1,a3,30000554 <__divdi3+0x474>
300003cc:	000107b7          	lui	a5,0x10
300003d0:	04f6f463          	bgeu	a3,a5,30000418 <__divdi3+0x338>
300003d4:	0ff00713          	li	a4,255
300003d8:	00d737b3          	sltu	a5,a4,a3
300003dc:	00379793          	slli	a5,a5,0x3
300003e0:	00f6d533          	srl	a0,a3,a5
300003e4:	00001717          	auipc	a4,0x1
300003e8:	7ac70713          	addi	a4,a4,1964 # 30001b90 <__clz_tab>
300003ec:	00a70733          	add	a4,a4,a0
300003f0:	00074703          	lbu	a4,0(a4)
300003f4:	00f70733          	add	a4,a4,a5
300003f8:	02000793          	li	a5,32
300003fc:	40e78333          	sub	t1,a5,a4
30000400:	02e79663          	bne	a5,a4,3000042c <__divdi3+0x34c>
30000404:	00100513          	li	a0,1
30000408:	eeb6e2e3          	bltu	a3,a1,300002ec <__divdi3+0x20c>
3000040c:	00ceb533          	sltu	a0,t4,a2
30000410:	00154513          	xori	a0,a0,1
30000414:	ed9ff06f          	j	300002ec <__divdi3+0x20c>
30000418:	01000737          	lui	a4,0x1000
3000041c:	01000793          	li	a5,16
30000420:	fce6e0e3          	bltu	a3,a4,300003e0 <__divdi3+0x300>
30000424:	01800793          	li	a5,24
30000428:	fb9ff06f          	j	300003e0 <__divdi3+0x300>
3000042c:	00e657b3          	srl	a5,a2,a4
30000430:	006696b3          	sll	a3,a3,t1
30000434:	00d7e6b3          	or	a3,a5,a3
30000438:	00e5d533          	srl	a0,a1,a4
3000043c:	006597b3          	sll	a5,a1,t1
30000440:	00eed733          	srl	a4,t4,a4
30000444:	0106df13          	srli	t5,a3,0x10
30000448:	00f765b3          	or	a1,a4,a5
3000044c:	03e57733          	remu	a4,a0,t5
30000450:	01069893          	slli	a7,a3,0x10
30000454:	0108d893          	srli	a7,a7,0x10
30000458:	0105d793          	srli	a5,a1,0x10
3000045c:	00661633          	sll	a2,a2,t1
30000460:	03e55533          	divu	a0,a0,t5
30000464:	01071713          	slli	a4,a4,0x10
30000468:	00f767b3          	or	a5,a4,a5
3000046c:	02a88fb3          	mul	t6,a7,a0
30000470:	00050e13          	mv	t3,a0
30000474:	01f7fe63          	bgeu	a5,t6,30000490 <__divdi3+0x3b0>
30000478:	00d787b3          	add	a5,a5,a3
3000047c:	fff50e13          	addi	t3,a0,-1
30000480:	00d7e863          	bltu	a5,a3,30000490 <__divdi3+0x3b0>
30000484:	01f7f663          	bgeu	a5,t6,30000490 <__divdi3+0x3b0>
30000488:	ffe50e13          	addi	t3,a0,-2
3000048c:	00d787b3          	add	a5,a5,a3
30000490:	41f787b3          	sub	a5,a5,t6
30000494:	03e7f733          	remu	a4,a5,t5
30000498:	01059593          	slli	a1,a1,0x10
3000049c:	0105d593          	srli	a1,a1,0x10
300004a0:	03e7d7b3          	divu	a5,a5,t5
300004a4:	01071713          	slli	a4,a4,0x10
300004a8:	00b76733          	or	a4,a4,a1
300004ac:	02f888b3          	mul	a7,a7,a5
300004b0:	00078593          	mv	a1,a5
300004b4:	01177e63          	bgeu	a4,a7,300004d0 <__divdi3+0x3f0>
300004b8:	00d70733          	add	a4,a4,a3
300004bc:	fff78593          	addi	a1,a5,-1 # ffff <hardware_spi_bootloader+0xff7b>
300004c0:	00d76863          	bltu	a4,a3,300004d0 <__divdi3+0x3f0>
300004c4:	01177663          	bgeu	a4,a7,300004d0 <__divdi3+0x3f0>
300004c8:	ffe78593          	addi	a1,a5,-2
300004cc:	00d70733          	add	a4,a4,a3
300004d0:	010e1513          	slli	a0,t3,0x10
300004d4:	00010f37          	lui	t5,0x10
300004d8:	00b56533          	or	a0,a0,a1
300004dc:	ffff0693          	addi	a3,t5,-1 # ffff <hardware_spi_bootloader+0xff7b>
300004e0:	01055593          	srli	a1,a0,0x10
300004e4:	41170733          	sub	a4,a4,a7
300004e8:	00d578b3          	and	a7,a0,a3
300004ec:	00d676b3          	and	a3,a2,a3
300004f0:	01065613          	srli	a2,a2,0x10
300004f4:	02d88e33          	mul	t3,a7,a3
300004f8:	02d586b3          	mul	a3,a1,a3
300004fc:	010e5793          	srli	a5,t3,0x10
30000500:	02c888b3          	mul	a7,a7,a2
30000504:	00d888b3          	add	a7,a7,a3
30000508:	011787b3          	add	a5,a5,a7
3000050c:	02c585b3          	mul	a1,a1,a2
30000510:	00d7f463          	bgeu	a5,a3,30000518 <__divdi3+0x438>
30000514:	01e585b3          	add	a1,a1,t5
30000518:	0107d693          	srli	a3,a5,0x10
3000051c:	00b685b3          	add	a1,a3,a1
30000520:	02b76663          	bltu	a4,a1,3000054c <__divdi3+0x46c>
30000524:	ceb710e3          	bne	a4,a1,30000204 <__divdi3+0x124>
30000528:	00010737          	lui	a4,0x10
3000052c:	fff70713          	addi	a4,a4,-1 # ffff <hardware_spi_bootloader+0xff7b>
30000530:	00e7f7b3          	and	a5,a5,a4
30000534:	01079793          	slli	a5,a5,0x10
30000538:	00ee7e33          	and	t3,t3,a4
3000053c:	006e9eb3          	sll	t4,t4,t1
30000540:	01c787b3          	add	a5,a5,t3
30000544:	00000313          	li	t1,0
30000548:	dafef2e3          	bgeu	t4,a5,300002ec <__divdi3+0x20c>
3000054c:	fff50513          	addi	a0,a0,-1
30000550:	cb5ff06f          	j	30000204 <__divdi3+0x124>
30000554:	00000313          	li	t1,0
30000558:	00000513          	li	a0,0
3000055c:	d91ff06f          	j	300002ec <__divdi3+0x20c>

30000560 <__udivdi3>:
30000560:	00050893          	mv	a7,a0
30000564:	00058793          	mv	a5,a1
30000568:	00060813          	mv	a6,a2
3000056c:	00068513          	mv	a0,a3
30000570:	00088313          	mv	t1,a7
30000574:	28069463          	bnez	a3,300007fc <__udivdi3+0x29c>
30000578:	00001697          	auipc	a3,0x1
3000057c:	61868693          	addi	a3,a3,1560 # 30001b90 <__clz_tab>
30000580:	0ec5f663          	bgeu	a1,a2,3000066c <__udivdi3+0x10c>
30000584:	00010737          	lui	a4,0x10
30000588:	0ce67863          	bgeu	a2,a4,30000658 <__udivdi3+0xf8>
3000058c:	0ff00713          	li	a4,255
30000590:	00c73733          	sltu	a4,a4,a2
30000594:	00371713          	slli	a4,a4,0x3
30000598:	00e65533          	srl	a0,a2,a4
3000059c:	00a686b3          	add	a3,a3,a0
300005a0:	0006c683          	lbu	a3,0(a3)
300005a4:	02000513          	li	a0,32
300005a8:	00e68733          	add	a4,a3,a4
300005ac:	40e506b3          	sub	a3,a0,a4
300005b0:	00e50c63          	beq	a0,a4,300005c8 <__udivdi3+0x68>
300005b4:	00d795b3          	sll	a1,a5,a3
300005b8:	00e8d733          	srl	a4,a7,a4
300005bc:	00d61833          	sll	a6,a2,a3
300005c0:	00b765b3          	or	a1,a4,a1
300005c4:	00d89333          	sll	t1,a7,a3
300005c8:	01085893          	srli	a7,a6,0x10
300005cc:	0315d6b3          	divu	a3,a1,a7
300005d0:	01081613          	slli	a2,a6,0x10
300005d4:	01065613          	srli	a2,a2,0x10
300005d8:	01035793          	srli	a5,t1,0x10
300005dc:	0315f733          	remu	a4,a1,a7
300005e0:	00068513          	mv	a0,a3
300005e4:	02d605b3          	mul	a1,a2,a3
300005e8:	01071713          	slli	a4,a4,0x10
300005ec:	00f767b3          	or	a5,a4,a5
300005f0:	00b7fe63          	bgeu	a5,a1,3000060c <__udivdi3+0xac>
300005f4:	010787b3          	add	a5,a5,a6
300005f8:	fff68513          	addi	a0,a3,-1
300005fc:	0107e863          	bltu	a5,a6,3000060c <__udivdi3+0xac>
30000600:	00b7f663          	bgeu	a5,a1,3000060c <__udivdi3+0xac>
30000604:	ffe68513          	addi	a0,a3,-2
30000608:	010787b3          	add	a5,a5,a6
3000060c:	40b787b3          	sub	a5,a5,a1
30000610:	0317f733          	remu	a4,a5,a7
30000614:	01031313          	slli	t1,t1,0x10
30000618:	01035313          	srli	t1,t1,0x10
3000061c:	0317d7b3          	divu	a5,a5,a7
30000620:	01071713          	slli	a4,a4,0x10
30000624:	00676333          	or	t1,a4,t1
30000628:	02f606b3          	mul	a3,a2,a5
3000062c:	00078613          	mv	a2,a5
30000630:	00d37c63          	bgeu	t1,a3,30000648 <__udivdi3+0xe8>
30000634:	00680333          	add	t1,a6,t1
30000638:	fff78613          	addi	a2,a5,-1
3000063c:	01036663          	bltu	t1,a6,30000648 <__udivdi3+0xe8>
30000640:	00d37463          	bgeu	t1,a3,30000648 <__udivdi3+0xe8>
30000644:	ffe78613          	addi	a2,a5,-2
30000648:	01051513          	slli	a0,a0,0x10
3000064c:	00c56533          	or	a0,a0,a2
30000650:	00000593          	li	a1,0
30000654:	0e40006f          	j	30000738 <__udivdi3+0x1d8>
30000658:	01000537          	lui	a0,0x1000
3000065c:	01000713          	li	a4,16
30000660:	f2a66ce3          	bltu	a2,a0,30000598 <__udivdi3+0x38>
30000664:	01800713          	li	a4,24
30000668:	f31ff06f          	j	30000598 <__udivdi3+0x38>
3000066c:	00061663          	bnez	a2,30000678 <__udivdi3+0x118>
30000670:	00100713          	li	a4,1
30000674:	02c75833          	divu	a6,a4,a2
30000678:	00010737          	lui	a4,0x10
3000067c:	0ce87063          	bgeu	a6,a4,3000073c <__udivdi3+0x1dc>
30000680:	0ff00713          	li	a4,255
30000684:	01077463          	bgeu	a4,a6,3000068c <__udivdi3+0x12c>
30000688:	00800513          	li	a0,8
3000068c:	00a85733          	srl	a4,a6,a0
30000690:	00e686b3          	add	a3,a3,a4
30000694:	0006c703          	lbu	a4,0(a3)
30000698:	02000613          	li	a2,32
3000069c:	00a70733          	add	a4,a4,a0
300006a0:	40e606b3          	sub	a3,a2,a4
300006a4:	0ae61663          	bne	a2,a4,30000750 <__udivdi3+0x1f0>
300006a8:	410787b3          	sub	a5,a5,a6
300006ac:	00100593          	li	a1,1
300006b0:	01085893          	srli	a7,a6,0x10
300006b4:	01081613          	slli	a2,a6,0x10
300006b8:	01065613          	srli	a2,a2,0x10
300006bc:	01035713          	srli	a4,t1,0x10
300006c0:	0317f6b3          	remu	a3,a5,a7
300006c4:	0317d7b3          	divu	a5,a5,a7
300006c8:	01069693          	slli	a3,a3,0x10
300006cc:	00e6e733          	or	a4,a3,a4
300006d0:	02f60e33          	mul	t3,a2,a5
300006d4:	00078513          	mv	a0,a5
300006d8:	01c77e63          	bgeu	a4,t3,300006f4 <__udivdi3+0x194>
300006dc:	01070733          	add	a4,a4,a6
300006e0:	fff78513          	addi	a0,a5,-1
300006e4:	01076863          	bltu	a4,a6,300006f4 <__udivdi3+0x194>
300006e8:	01c77663          	bgeu	a4,t3,300006f4 <__udivdi3+0x194>
300006ec:	ffe78513          	addi	a0,a5,-2
300006f0:	01070733          	add	a4,a4,a6
300006f4:	41c70733          	sub	a4,a4,t3
300006f8:	031777b3          	remu	a5,a4,a7
300006fc:	01031313          	slli	t1,t1,0x10
30000700:	01035313          	srli	t1,t1,0x10
30000704:	03175733          	divu	a4,a4,a7
30000708:	01079793          	slli	a5,a5,0x10
3000070c:	0067e333          	or	t1,a5,t1
30000710:	02e606b3          	mul	a3,a2,a4
30000714:	00070613          	mv	a2,a4
30000718:	00d37c63          	bgeu	t1,a3,30000730 <__udivdi3+0x1d0>
3000071c:	00680333          	add	t1,a6,t1
30000720:	fff70613          	addi	a2,a4,-1 # ffff <hardware_spi_bootloader+0xff7b>
30000724:	01036663          	bltu	t1,a6,30000730 <__udivdi3+0x1d0>
30000728:	00d37463          	bgeu	t1,a3,30000730 <__udivdi3+0x1d0>
3000072c:	ffe70613          	addi	a2,a4,-2
30000730:	01051513          	slli	a0,a0,0x10
30000734:	00c56533          	or	a0,a0,a2
30000738:	00008067          	ret
3000073c:	01000737          	lui	a4,0x1000
30000740:	01000513          	li	a0,16
30000744:	f4e864e3          	bltu	a6,a4,3000068c <__udivdi3+0x12c>
30000748:	01800513          	li	a0,24
3000074c:	f41ff06f          	j	3000068c <__udivdi3+0x12c>
30000750:	00d81833          	sll	a6,a6,a3
30000754:	00e7d533          	srl	a0,a5,a4
30000758:	00d89333          	sll	t1,a7,a3
3000075c:	00d797b3          	sll	a5,a5,a3
30000760:	00e8d733          	srl	a4,a7,a4
30000764:	01085893          	srli	a7,a6,0x10
30000768:	00f76633          	or	a2,a4,a5
3000076c:	03157733          	remu	a4,a0,a7
30000770:	01081793          	slli	a5,a6,0x10
30000774:	0107d793          	srli	a5,a5,0x10
30000778:	01065593          	srli	a1,a2,0x10
3000077c:	03155533          	divu	a0,a0,a7
30000780:	01071713          	slli	a4,a4,0x10
30000784:	00b76733          	or	a4,a4,a1
30000788:	02a786b3          	mul	a3,a5,a0
3000078c:	00050593          	mv	a1,a0
30000790:	00d77e63          	bgeu	a4,a3,300007ac <__udivdi3+0x24c>
30000794:	01070733          	add	a4,a4,a6
30000798:	fff50593          	addi	a1,a0,-1 # ffffff <hardware_spi_bootloader+0xffff7b>
3000079c:	01076863          	bltu	a4,a6,300007ac <__udivdi3+0x24c>
300007a0:	00d77663          	bgeu	a4,a3,300007ac <__udivdi3+0x24c>
300007a4:	ffe50593          	addi	a1,a0,-2
300007a8:	01070733          	add	a4,a4,a6
300007ac:	40d706b3          	sub	a3,a4,a3
300007b0:	0316f733          	remu	a4,a3,a7
300007b4:	01061613          	slli	a2,a2,0x10
300007b8:	01065613          	srli	a2,a2,0x10
300007bc:	0316d6b3          	divu	a3,a3,a7
300007c0:	01071713          	slli	a4,a4,0x10
300007c4:	02d78533          	mul	a0,a5,a3
300007c8:	00c767b3          	or	a5,a4,a2
300007cc:	00068713          	mv	a4,a3
300007d0:	00a7fe63          	bgeu	a5,a0,300007ec <__udivdi3+0x28c>
300007d4:	010787b3          	add	a5,a5,a6
300007d8:	fff68713          	addi	a4,a3,-1
300007dc:	0107e863          	bltu	a5,a6,300007ec <__udivdi3+0x28c>
300007e0:	00a7f663          	bgeu	a5,a0,300007ec <__udivdi3+0x28c>
300007e4:	ffe68713          	addi	a4,a3,-2
300007e8:	010787b3          	add	a5,a5,a6
300007ec:	01059593          	slli	a1,a1,0x10
300007f0:	40a787b3          	sub	a5,a5,a0
300007f4:	00e5e5b3          	or	a1,a1,a4
300007f8:	eb9ff06f          	j	300006b0 <__udivdi3+0x150>
300007fc:	18d5e663          	bltu	a1,a3,30000988 <__udivdi3+0x428>
30000800:	00010737          	lui	a4,0x10
30000804:	04e6f463          	bgeu	a3,a4,3000084c <__udivdi3+0x2ec>
30000808:	0ff00713          	li	a4,255
3000080c:	00d735b3          	sltu	a1,a4,a3
30000810:	00359593          	slli	a1,a1,0x3
30000814:	00b6d533          	srl	a0,a3,a1
30000818:	00001717          	auipc	a4,0x1
3000081c:	37870713          	addi	a4,a4,888 # 30001b90 <__clz_tab>
30000820:	00a70733          	add	a4,a4,a0
30000824:	00074703          	lbu	a4,0(a4)
30000828:	02000513          	li	a0,32
3000082c:	00b70733          	add	a4,a4,a1
30000830:	40e505b3          	sub	a1,a0,a4
30000834:	02e51663          	bne	a0,a4,30000860 <__udivdi3+0x300>
30000838:	00100513          	li	a0,1
3000083c:	eef6eee3          	bltu	a3,a5,30000738 <__udivdi3+0x1d8>
30000840:	00c8b533          	sltu	a0,a7,a2
30000844:	00154513          	xori	a0,a0,1
30000848:	ef1ff06f          	j	30000738 <__udivdi3+0x1d8>
3000084c:	01000737          	lui	a4,0x1000
30000850:	01000593          	li	a1,16
30000854:	fce6e0e3          	bltu	a3,a4,30000814 <__udivdi3+0x2b4>
30000858:	01800593          	li	a1,24
3000085c:	fb9ff06f          	j	30000814 <__udivdi3+0x2b4>
30000860:	00e65833          	srl	a6,a2,a4
30000864:	00b696b3          	sll	a3,a3,a1
30000868:	00d86833          	or	a6,a6,a3
3000086c:	00e7d333          	srl	t1,a5,a4
30000870:	01085e93          	srli	t4,a6,0x10
30000874:	03d376b3          	remu	a3,t1,t4
30000878:	00b797b3          	sll	a5,a5,a1
3000087c:	00e8d733          	srl	a4,a7,a4
30000880:	00b61e33          	sll	t3,a2,a1
30000884:	00f76633          	or	a2,a4,a5
30000888:	01081793          	slli	a5,a6,0x10
3000088c:	0107d793          	srli	a5,a5,0x10
30000890:	01065713          	srli	a4,a2,0x10
30000894:	03d35333          	divu	t1,t1,t4
30000898:	01069693          	slli	a3,a3,0x10
3000089c:	00e6e733          	or	a4,a3,a4
300008a0:	02678f33          	mul	t5,a5,t1
300008a4:	00030513          	mv	a0,t1
300008a8:	01e77e63          	bgeu	a4,t5,300008c4 <__udivdi3+0x364>
300008ac:	01070733          	add	a4,a4,a6
300008b0:	fff30513          	addi	a0,t1,-1
300008b4:	01076863          	bltu	a4,a6,300008c4 <__udivdi3+0x364>
300008b8:	01e77663          	bgeu	a4,t5,300008c4 <__udivdi3+0x364>
300008bc:	ffe30513          	addi	a0,t1,-2
300008c0:	01070733          	add	a4,a4,a6
300008c4:	41e70733          	sub	a4,a4,t5
300008c8:	03d776b3          	remu	a3,a4,t4
300008cc:	03d75733          	divu	a4,a4,t4
300008d0:	01069693          	slli	a3,a3,0x10
300008d4:	02e78333          	mul	t1,a5,a4
300008d8:	01061793          	slli	a5,a2,0x10
300008dc:	0107d793          	srli	a5,a5,0x10
300008e0:	00f6e7b3          	or	a5,a3,a5
300008e4:	00070613          	mv	a2,a4
300008e8:	0067fe63          	bgeu	a5,t1,30000904 <__udivdi3+0x3a4>
300008ec:	010787b3          	add	a5,a5,a6
300008f0:	fff70613          	addi	a2,a4,-1 # ffffff <hardware_spi_bootloader+0xffff7b>
300008f4:	0107e863          	bltu	a5,a6,30000904 <__udivdi3+0x3a4>
300008f8:	0067f663          	bgeu	a5,t1,30000904 <__udivdi3+0x3a4>
300008fc:	ffe70613          	addi	a2,a4,-2
30000900:	010787b3          	add	a5,a5,a6
30000904:	01051513          	slli	a0,a0,0x10
30000908:	00010eb7          	lui	t4,0x10
3000090c:	00c56533          	or	a0,a0,a2
30000910:	fffe8693          	addi	a3,t4,-1 # ffff <hardware_spi_bootloader+0xff7b>
30000914:	010e5613          	srli	a2,t3,0x10
30000918:	01055813          	srli	a6,a0,0x10
3000091c:	406787b3          	sub	a5,a5,t1
30000920:	00d57333          	and	t1,a0,a3
30000924:	00de76b3          	and	a3,t3,a3
30000928:	02d30e33          	mul	t3,t1,a3
3000092c:	02d806b3          	mul	a3,a6,a3
30000930:	010e5713          	srli	a4,t3,0x10
30000934:	02c30333          	mul	t1,t1,a2
30000938:	00d30333          	add	t1,t1,a3
3000093c:	00670733          	add	a4,a4,t1
30000940:	02c80833          	mul	a6,a6,a2
30000944:	00d77463          	bgeu	a4,a3,3000094c <__udivdi3+0x3ec>
30000948:	01d80833          	add	a6,a6,t4
3000094c:	01075693          	srli	a3,a4,0x10
30000950:	01068833          	add	a6,a3,a6
30000954:	0307e663          	bltu	a5,a6,30000980 <__udivdi3+0x420>
30000958:	cf079ce3          	bne	a5,a6,30000650 <__udivdi3+0xf0>
3000095c:	000107b7          	lui	a5,0x10
30000960:	fff78793          	addi	a5,a5,-1 # ffff <hardware_spi_bootloader+0xff7b>
30000964:	00f77733          	and	a4,a4,a5
30000968:	01071713          	slli	a4,a4,0x10
3000096c:	00fe7e33          	and	t3,t3,a5
30000970:	00b898b3          	sll	a7,a7,a1
30000974:	01c70733          	add	a4,a4,t3
30000978:	00000593          	li	a1,0
3000097c:	dae8fee3          	bgeu	a7,a4,30000738 <__udivdi3+0x1d8>
30000980:	fff50513          	addi	a0,a0,-1
30000984:	ccdff06f          	j	30000650 <__udivdi3+0xf0>
30000988:	00000593          	li	a1,0
3000098c:	00000513          	li	a0,0
30000990:	da9ff06f          	j	30000738 <__udivdi3+0x1d8>

30000994 <main>:
30000994:	f7010113          	addi	sp,sp,-144
30000998:	fffff337          	lui	t1,0xfffff
3000099c:	08812423          	sw	s0,136(sp)
300009a0:	08912223          	sw	s1,132(sp)
300009a4:	09212023          	sw	s2,128(sp)
300009a8:	07312e23          	sw	s3,124(sp)
300009ac:	07412c23          	sw	s4,120(sp)
300009b0:	07512a23          	sw	s5,116(sp)
300009b4:	07612823          	sw	s6,112(sp)
300009b8:	07712623          	sw	s7,108(sp)
300009bc:	07812423          	sw	s8,104(sp)
300009c0:	07912223          	sw	s9,100(sp)
300009c4:	05b12e23          	sw	s11,92(sp)
300009c8:	08112623          	sw	ra,140(sp)
300009cc:	07a12023          	sw	s10,96(sp)
300009d0:	00001737          	lui	a4,0x1
300009d4:	00610133          	add	sp,sp,t1
300009d8:	01070713          	addi	a4,a4,16 # 1010 <hardware_spi_bootloader+0xf8c>
300009dc:	04010693          	addi	a3,sp,64
300009e0:	00d70733          	add	a4,a4,a3
300009e4:	fffff7b7          	lui	a5,0xfffff
300009e8:	00f707b3          	add	a5,a4,a5
300009ec:	00f12623          	sw	a5,12(sp)
300009f0:	00c12703          	lw	a4,12(sp)
300009f4:	500007b7          	lui	a5,0x50000
300009f8:	30002937          	lui	s2,0x30002
300009fc:	fef72c23          	sw	a5,-8(a4)
30000a00:	500017b7          	lui	a5,0x50001
30000a04:	80078793          	addi	a5,a5,-2048 # 50000800 <_stack_top+0x1fff8800>
30000a08:	fef72e23          	sw	a5,-4(a4)
30000a0c:	300027b7          	lui	a5,0x30002
30000a10:	cd078713          	addi	a4,a5,-816 # 30001cd0 <input_buffer>
30000a14:	40070713          	addi	a4,a4,1024
30000a18:	cd078793          	addi	a5,a5,-816
30000a1c:	000329b7          	lui	s3,0x32
30000a20:	fff9bb37          	lui	s6,0xfff9b
30000a24:	1d70a437          	lui	s0,0x1d70a
30000a28:	228f64b7          	lui	s1,0x228f6
30000a2c:	00065ab7          	lui	s5,0x65
30000a30:	0c910a37          	lui	s4,0xc910
30000a34:	00e12623          	sw	a4,12(sp)
30000a38:	00070c93          	mv	s9,a4
30000a3c:	00000d93          	li	s11,0
30000a40:	00000c13          	li	s8,0
30000a44:	02f12023          	sw	a5,32(sp)
30000a48:	0d090913          	addi	s2,s2,208 # 300020d0 <hamming_q15>
30000a4c:	43f98993          	addi	s3,s3,1087 # 3243f <hardware_spi_bootloader+0x323bb>
30000a50:	782b0b13          	addi	s6,s6,1922 # fff9b782 <_data_flash_start+0x7ff99ab6>
30000a54:	31a40413          	addi	s0,s0,794 # 1d70a31a <hardware_spi_bootloader+0x1d70a296>
30000a58:	ccc48493          	addi	s1,s1,-820 # 228f5ccc <hardware_spi_bootloader+0x228f5c48>
30000a5c:	00008bb7          	lui	s7,0x8
30000a60:	87ea8a93          	addi	s5,s5,-1922 # 6487e <hardware_spi_bootloader+0x647fa>
30000a64:	c00a0a13          	addi	s4,s4,-1024 # c90fc00 <hardware_spi_bootloader+0xc90fb7c>
30000a68:	1ff00613          	li	a2,511
30000a6c:	00000693          	li	a3,0
30000a70:	000d8513          	mv	a0,s11
30000a74:	000c0593          	mv	a1,s8
30000a78:	e68ff0ef          	jal	ra,300000e0 <__divdi3>
30000a7c:	00a9d463          	bge	s3,a0,30000a84 <main+0xf0>
30000a80:	01650533          	add	a0,a0,s6
30000a84:	02a50d33          	mul	s10,a0,a0
30000a88:	01800613          	li	a2,24
30000a8c:	02a51533          	mulh	a0,a0,a0
30000a90:	002d5793          	srli	a5,s10,0x2
30000a94:	003d5d13          	srli	s10,s10,0x3
30000a98:	01e51693          	slli	a3,a0,0x1e
30000a9c:	00f6e7b3          	or	a5,a3,a5
30000aa0:	40255313          	srai	t1,a0,0x2
30000aa4:	02f308b3          	mul	a7,t1,a5
30000aa8:	01d51513          	slli	a0,a0,0x1d
30000aac:	00f12c23          	sw	a5,24(sp)
30000ab0:	01a56d33          	or	s10,a0,s10
30000ab4:	00612e23          	sw	t1,28(sp)
30000ab8:	02f7b6b3          	mulhu	a3,a5,a5
30000abc:	00189893          	slli	a7,a7,0x1
30000ac0:	02f78e33          	mul	t3,a5,a5
30000ac4:	00d888b3          	add	a7,a7,a3
30000ac8:	00289693          	slli	a3,a7,0x2
30000acc:	41e8d893          	srai	a7,a7,0x1e
30000ad0:	400007b7          	lui	a5,0x40000
30000ad4:	00088593          	mv	a1,a7
30000ad8:	41a78d33          	sub	s10,a5,s10
30000adc:	01112823          	sw	a7,16(sp)
30000ae0:	01ee5e13          	srli	t3,t3,0x1e
30000ae4:	01c6ee33          	or	t3,a3,t3
30000ae8:	000e0513          	mv	a0,t3
30000aec:	00000693          	li	a3,0
30000af0:	01c12a23          	sw	t3,20(sp)
30000af4:	decff0ef          	jal	ra,300000e0 <__divdi3>
30000af8:	01412e03          	lw	t3,20(sp)
30000afc:	01812783          	lw	a5,24(sp)
30000b00:	01c12303          	lw	t1,28(sp)
30000b04:	01012883          	lw	a7,16(sp)
30000b08:	03c785b3          	mul	a1,a5,t3
30000b0c:	00ad0d33          	add	s10,s10,a0
30000b10:	00000693          	li	a3,0
30000b14:	2d000613          	li	a2,720
30000b18:	03c30333          	mul	t1,t1,t3
30000b1c:	01e5d593          	srli	a1,a1,0x1e
30000b20:	02f888b3          	mul	a7,a7,a5
30000b24:	03c7b7b3          	mulhu	a5,a5,t3
30000b28:	011308b3          	add	a7,t1,a7
30000b2c:	00f887b3          	add	a5,a7,a5
30000b30:	00279513          	slli	a0,a5,0x2
30000b34:	00b56533          	or	a0,a0,a1
30000b38:	41e7d593          	srai	a1,a5,0x1e
30000b3c:	da4ff0ef          	jal	ra,300000e0 <__divdi3>
30000b40:	40ad0533          	sub	a0,s10,a0
30000b44:	028506b3          	mul	a3,a0,s0
30000b48:	02851533          	mulh	a0,a0,s0
30000b4c:	01e6d693          	srli	a3,a3,0x1e
30000b50:	00251793          	slli	a5,a0,0x2
30000b54:	00d7e6b3          	or	a3,a5,a3
30000b58:	40d486b3          	sub	a3,s1,a3
30000b5c:	41e55793          	srai	a5,a0,0x1e
30000b60:	40f007b3          	neg	a5,a5
30000b64:	00d4b533          	sltu	a0,s1,a3
30000b68:	40a787b3          	sub	a5,a5,a0
30000b6c:	01179793          	slli	a5,a5,0x11
30000b70:	00f6d693          	srli	a3,a3,0xf
30000b74:	00d7e7b3          	or	a5,a5,a3
30000b78:	0177c663          	blt	a5,s7,30000b84 <main+0x1f0>
30000b7c:	000087b7          	lui	a5,0x8
30000b80:	fff78793          	addi	a5,a5,-1 # 7fff <hardware_spi_bootloader+0x7f7b>
30000b84:	00fc9023          	sh	a5,0(s9)
30000b88:	015d87b3          	add	a5,s11,s5
30000b8c:	01b7b6b3          	sltu	a3,a5,s11
30000b90:	01868c33          	add	s8,a3,s8
30000b94:	00078d93          	mv	s11,a5
30000b98:	002c8c93          	addi	s9,s9,2
30000b9c:	ed4796e3          	bne	a5,s4,30000a68 <main+0xd4>
30000ba0:	ec0c14e3          	bnez	s8,30000a68 <main+0xd4>
30000ba4:	30003437          	lui	s0,0x30003
30000ba8:	cd040793          	addi	a5,s0,-816 # 30002cd0 <real_q15+0x1fc>
30000bac:	80078793          	addi	a5,a5,-2048
30000bb0:	00f12e23          	sw	a5,28(sp)
30000bb4:	00c12783          	lw	a5,12(sp)
30000bb8:	01c12603          	lw	a2,28(sp)
30000bbc:	cd040413          	addi	s0,s0,-816
30000bc0:	20078593          	addi	a1,a5,512
30000bc4:	00078693          	mv	a3,a5
30000bc8:	40000537          	lui	a0,0x40000
30000bcc:	00069783          	lh	a5,0(a3)
30000bd0:	20069703          	lh	a4,512(a3)
30000bd4:	02f787b3          	mul	a5,a5,a5
30000bd8:	02e70733          	mul	a4,a4,a4
30000bdc:	40f7d793          	srai	a5,a5,0xf
30000be0:	40f75713          	srai	a4,a4,0xf
30000be4:	00e787b3          	add	a5,a5,a4
30000be8:	00000713          	li	a4,0
30000bec:	00f05463          	blez	a5,30000bf4 <main+0x260>
30000bf0:	02f54733          	div	a4,a0,a5
30000bf4:	00e62023          	sw	a4,0(a2)
30000bf8:	00268693          	addi	a3,a3,2
30000bfc:	00460613          	addi	a2,a2,4
30000c00:	fcd596e3          	bne	a1,a3,30000bcc <main+0x238>
30000c04:	30001737          	lui	a4,0x30001
30000c08:	400017b7          	lui	a5,0x40001
30000c0c:	58c70513          	addi	a0,a4,1420 # 3000158c <fft_twiddles>
30000c10:	00010837          	lui	a6,0x10
30000c14:	58c70713          	addi	a4,a4,1420
30000c18:	02e12423          	sw	a4,40(sp)
30000c1c:	80078693          	addi	a3,a5,-2048 # 40000800 <_stack_top+0xfff8800>
30000c20:	20000737          	lui	a4,0x20000
30000c24:	fff80813          	addi	a6,a6,-1 # ffff <hardware_spi_bootloader+0xff7b>
30000c28:	ffff0337          	lui	t1,0xffff0
30000c2c:	c0078593          	addi	a1,a5,-1024
30000c30:	00052603          	lw	a2,0(a0) # 40000000 <_stack_top+0xfff8000>
30000c34:	00e688b3          	add	a7,a3,a4
30000c38:	00468693          	addi	a3,a3,4
30000c3c:	01061793          	slli	a5,a2,0x10
30000c40:	4107d793          	srai	a5,a5,0x10
30000c44:	40f007b3          	neg	a5,a5
30000c48:	fec6ae23          	sw	a2,-4(a3)
30000c4c:	0107f7b3          	and	a5,a5,a6
30000c50:	00667633          	and	a2,a2,t1
30000c54:	00c7e7b3          	or	a5,a5,a2
30000c58:	00f8a023          	sw	a5,0(a7)
30000c5c:	00450513          	addi	a0,a0,4
30000c60:	fcb698e3          	bne	a3,a1,30000c30 <main+0x29c>
30000c64:	200107b7          	lui	a5,0x20010
30000c68:	00100693          	li	a3,1
30000c6c:	f0d7a823          	sw	a3,-240(a5) # 2000ff10 <hardware_spi_bootloader+0x2000fe8c>
30000c70:	20020637          	lui	a2,0x20020
30000c74:	f0d62823          	sw	a3,-240(a2) # 2001ff10 <hardware_spi_bootloader+0x2001fe8c>
30000c78:	00200693          	li	a3,2
30000c7c:	00d72223          	sw	a3,4(a4) # 20000004 <hardware_spi_bootloader+0x1fffff80>
30000c80:	00d7a223          	sw	a3,4(a5)
30000c84:	20b00613          	li	a2,523
30000c88:	00c72a23          	sw	a2,20(a4)
30000c8c:	00c7aa23          	sw	a2,20(a5)
30000c90:	00d72823          	sw	a3,16(a4)
30000c94:	00d7a823          	sw	a3,16(a5)
30000c98:	0007a023          	sw	zero,0(a5)
30000c9c:	0007a023          	sw	zero,0(a5)
30000ca0:	0007a023          	sw	zero,0(a5)
30000ca4:	0007a023          	sw	zero,0(a5)
30000ca8:	0007a023          	sw	zero,0(a5)
30000cac:	0007a023          	sw	zero,0(a5)
30000cb0:	0007a023          	sw	zero,0(a5)
30000cb4:	0007a023          	sw	zero,0(a5)
30000cb8:	00300693          	li	a3,3
30000cbc:	00d72823          	sw	a3,16(a4)
30000cc0:	02012703          	lw	a4,32(sp)
30000cc4:	00d7a823          	sw	a3,16(a5)
30000cc8:	300047b7          	lui	a5,0x30004
30000ccc:	0e878793          	addi	a5,a5,232 # 300040e8 <ola_buffer>
30000cd0:	00071023          	sh	zero,0(a4)
30000cd4:	0007a023          	sw	zero,0(a5)
30000cd8:	00270713          	addi	a4,a4,2
30000cdc:	00478793          	addi	a5,a5,4
30000ce0:	fee918e3          	bne	s2,a4,30000cd0 <main+0x33c>
30000ce4:	300037b7          	lui	a5,0x30003
30000ce8:	e0240713          	addi	a4,s0,-510
30000cec:	8d078793          	addi	a5,a5,-1840 # 300028d0 <prev_mask_q15>
30000cf0:	00079023          	sh	zero,0(a5)
30000cf4:	00278793          	addi	a5,a5,2
30000cf8:	fef71ce3          	bne	a4,a5,30000cf0 <main+0x35c>
30000cfc:	00001737          	lui	a4,0x1
30000d00:	01070713          	addi	a4,a4,16 # 1010 <hardware_spi_bootloader+0xf8c>
30000d04:	04010693          	addi	a3,sp,64
30000d08:	00d70733          	add	a4,a4,a3
30000d0c:	fffff7b7          	lui	a5,0xfffff
30000d10:	00f707b3          	add	a5,a4,a5
30000d14:	40078713          	addi	a4,a5,1024 # fffff400 <_data_flash_start+0x7fffd734>
30000d18:	00079023          	sh	zero,0(a5)
30000d1c:	00278793          	addi	a5,a5,2
30000d20:	fef71ce3          	bne	a4,a5,30000d18 <main+0x384>
30000d24:	000017b7          	lui	a5,0x1
30000d28:	04010713          	addi	a4,sp,64
30000d2c:	01078793          	addi	a5,a5,16 # 1010 <hardware_spi_bootloader+0xf8c>
30000d30:	00e787b3          	add	a5,a5,a4
30000d34:	fffff537          	lui	a0,0xfffff
30000d38:	00a78533          	add	a0,a5,a0
30000d3c:	20000593          	li	a1,512
30000d40:	b00ff0ef          	jal	ra,30000040 <io_hop>
30000d44:	300037b7          	lui	a5,0x30003
30000d48:	ad478793          	addi	a5,a5,-1324 # 30002ad4 <real_q15>
30000d4c:	00f12c23          	sw	a5,24(sp)
30000d50:	300027b7          	lui	a5,0x30002
30000d54:	300044b7          	lui	s1,0x30004
30000d58:	0d078793          	addi	a5,a5,208 # 300020d0 <hamming_q15>
30000d5c:	00000a13          	li	s4,0
30000d60:	cd048493          	addi	s1,s1,-816 # 30003cd0 <sir_sq+0x1f0>
30000d64:	02f12c23          	sw	a5,56(sp)
30000d68:	000016b7          	lui	a3,0x1
30000d6c:	04010613          	addi	a2,sp,64
30000d70:	01068693          	addi	a3,a3,16 # 1010 <hardware_spi_bootloader+0xf8c>
30000d74:	00c686b3          	add	a3,a3,a2
30000d78:	001a7913          	andi	s2,s4,1
30000d7c:	fffff737          	lui	a4,0xfffff
30000d80:	00e68733          	add	a4,a3,a4
30000d84:	00291793          	slli	a5,s2,0x2
30000d88:	00f707b3          	add	a5,a4,a5
30000d8c:	ff87a983          	lw	s3,-8(a5)
30000d90:	00e12823          	sw	a4,16(sp)
30000d94:	500017b7          	lui	a5,0x50001
30000d98:	0127a023          	sw	s2,0(a5) # 50001000 <_stack_top+0x1fff9000>
30000d9c:	300057b7          	lui	a5,0x30005
30000da0:	8e87a803          	lw	a6,-1816(a5) # 300048e8 <input_write_ptr>
30000da4:	00c12603          	lw	a2,12(sp)
30000da8:	000105b7          	lui	a1,0x10
30000dac:	00000693          	li	a3,0
30000db0:	20000513          	li	a0,512
30000db4:	fff58593          	addi	a1,a1,-1 # ffff <hardware_spi_bootloader+0xff7b>
30000db8:	00d807b3          	add	a5,a6,a3
30000dbc:	02a7e7b3          	rem	a5,a5,a0
30000dc0:	02012703          	lw	a4,32(sp)
30000dc4:	00068313          	mv	t1,a3
30000dc8:	00900893          	li	a7,9
30000dcc:	00179793          	slli	a5,a5,0x1
30000dd0:	00f707b3          	add	a5,a4,a5
30000dd4:	00079703          	lh	a4,0(a5)
30000dd8:	00061783          	lh	a5,0(a2)
30000ddc:	02f70733          	mul	a4,a4,a5
30000de0:	00000793          	li	a5,0
30000de4:	41475713          	srai	a4,a4,0x14
30000de8:	00137e13          	andi	t3,t1,1
30000dec:	00179793          	slli	a5,a5,0x1
30000df0:	fff88893          	addi	a7,a7,-1
30000df4:	00fe67b3          	or	a5,t3,a5
30000df8:	00135313          	srli	t1,t1,0x1
30000dfc:	fe0896e3          	bnez	a7,30000de8 <main+0x454>
30000e00:	00279793          	slli	a5,a5,0x2
30000e04:	00f987b3          	add	a5,s3,a5
30000e08:	00b77733          	and	a4,a4,a1
30000e0c:	00e7a023          	sw	a4,0(a5)
30000e10:	00168693          	addi	a3,a3,1
30000e14:	00260613          	addi	a2,a2,2
30000e18:	faa690e3          	bne	a3,a0,30000db8 <main+0x424>
30000e1c:	00100793          	li	a5,1
30000e20:	40001737          	lui	a4,0x40001
30000e24:	c0f72023          	sw	a5,-1024(a4) # 40000c00 <_stack_top+0xfff8c00>
30000e28:	fffff537          	lui	a0,0xfffff
30000e2c:	720a0c63          	beqz	s4,30001564 <main+0xbd0>
30000e30:	00001737          	lui	a4,0x1
30000e34:	01070713          	addi	a4,a4,16 # 1010 <hardware_spi_bootloader+0xf8c>
30000e38:	04010693          	addi	a3,sp,64
30000e3c:	40050513          	addi	a0,a0,1024 # fffff400 <_data_flash_start+0x7fffd734>
30000e40:	00d70733          	add	a4,a4,a3
30000e44:	412787b3          	sub	a5,a5,s2
30000e48:	00a70533          	add	a0,a4,a0
30000e4c:	00979793          	slli	a5,a5,0x9
30000e50:	00a78533          	add	a0,a5,a0
30000e54:	10000593          	li	a1,256
30000e58:	9e8ff0ef          	jal	ra,30000040 <io_hop>
30000e5c:	40001737          	lui	a4,0x40001
30000e60:	c0072783          	lw	a5,-1024(a4) # 40000c00 <_stack_top+0xfff8c00>
30000e64:	0027f793          	andi	a5,a5,2
30000e68:	fe078ce3          	beqz	a5,30000e60 <main+0x4cc>
30000e6c:	30003b37          	lui	s6,0x30003
30000e70:	ed4b0793          	addi	a5,s6,-300 # 30002ed4 <imag_q15>
30000e74:	00000c13          	li	s8,0
30000e78:	e0440513          	addi	a0,s0,-508
30000e7c:	20440593          	addi	a1,s0,516
30000e80:	40000693          	li	a3,1024
30000e84:	00f12a23          	sw	a5,20(sp)
30000e88:	001c1793          	slli	a5,s8,0x1
30000e8c:	013787b3          	add	a5,a5,s3
30000e90:	0007a783          	lw	a5,0(a5)
30000e94:	01850633          	add	a2,a0,s8
30000e98:	01312823          	sw	s3,16(sp)
30000e9c:	00f61023          	sh	a5,0(a2)
30000ea0:	01858633          	add	a2,a1,s8
30000ea4:	0107d793          	srli	a5,a5,0x10
30000ea8:	00f61023          	sh	a5,0(a2)
30000eac:	002c0c13          	addi	s8,s8,2
30000eb0:	fcdc1ce3          	bne	s8,a3,30000e88 <main+0x4f4>
30000eb4:	60440b93          	addi	s7,s0,1540
30000eb8:	30003ab7          	lui	s5,0x30003
30000ebc:	00000693          	li	a3,0
30000ec0:	000b8593          	mv	a1,s7
30000ec4:	2d4a8a93          	addi	s5,s5,724 # 300032d4 <mag_sq>
30000ec8:	20200513          	li	a0,514
30000ecc:	01812783          	lw	a5,24(sp)
30000ed0:	01412703          	lw	a4,20(sp)
30000ed4:	00458593          	addi	a1,a1,4
30000ed8:	00d787b3          	add	a5,a5,a3
30000edc:	00d70633          	add	a2,a4,a3
30000ee0:	00079783          	lh	a5,0(a5)
30000ee4:	00061603          	lh	a2,0(a2)
30000ee8:	00268693          	addi	a3,a3,2
30000eec:	02f787b3          	mul	a5,a5,a5
30000ef0:	02c60633          	mul	a2,a2,a2
30000ef4:	00c787b3          	add	a5,a5,a2
30000ef8:	fef5ae23          	sw	a5,-4(a1)
30000efc:	fca698e3          	bne	a3,a0,30000ecc <main+0x538>
30000f00:	30003cb7          	lui	s9,0x30003
30000f04:	a0848d93          	addi	s11,s1,-1528
30000f08:	404b8b13          	addi	s6,s7,1028 # 8404 <hardware_spi_bootloader+0x8380>
30000f0c:	000b8d13          	mv	s10,s7
30000f10:	6d8c8c93          	addi	s9,s9,1752 # 300036d8 <mag_q15_arr>
30000f14:	000d2503          	lw	a0,0(s10)
30000f18:	004d0d13          	addi	s10,s10,4
30000f1c:	002d8d93          	addi	s11,s11,2
30000f20:	8e0ff0ef          	jal	ra,30000000 <isqrt_bin>
30000f24:	fead9f23          	sh	a0,-2(s11)
30000f28:	ffab16e3          	bne	s6,s10,30000f14 <main+0x580>
30000f2c:	c0c48613          	addi	a2,s1,-1012
30000f30:	00060793          	mv	a5,a2
30000f34:	30004737          	lui	a4,0x30004
30000f38:	00079023          	sh	zero,0(a5)
30000f3c:	ade70713          	addi	a4,a4,-1314 # 30003ade <proj_q15+0x202>
30000f40:	00278793          	addi	a5,a5,2
30000f44:	fef718e3          	bne	a4,a5,30000f34 <main+0x5a0>
30000f48:	02812783          	lw	a5,40(sp)
30000f4c:	300025b7          	lui	a1,0x30002
30000f50:	00000813          	li	a6,0
30000f54:	00000693          	li	a3,0
30000f58:	00000513          	li	a0,0
30000f5c:	40078e93          	addi	t4,a5,1024
30000f60:	20200e13          	li	t3,514
30000f64:	98c58593          	addi	a1,a1,-1652 # 3000198c <trigger_vecs_q15>
30000f68:	010e88b3          	add	a7,t4,a6
30000f6c:	010c87b3          	add	a5,s9,a6
30000f70:	00089303          	lh	t1,0(a7)
30000f74:	00079783          	lh	a5,0(a5)
30000f78:	00280813          	addi	a6,a6,2
30000f7c:	026788b3          	mul	a7,a5,t1
30000f80:	026797b3          	mulh	a5,a5,t1
30000f84:	011688b3          	add	a7,a3,a7
30000f88:	00d8b333          	sltu	t1,a7,a3
30000f8c:	00088693          	mv	a3,a7
30000f90:	00f507b3          	add	a5,a0,a5
30000f94:	00f30533          	add	a0,t1,a5
30000f98:	fdc818e3          	bne	a6,t3,30000f68 <main+0x5d4>
30000f9c:	01151793          	slli	a5,a0,0x11
30000fa0:	00f8d693          	srli	a3,a7,0xf
30000fa4:	00d7e6b3          	or	a3,a5,a3
30000fa8:	00300793          	li	a5,3
30000fac:	02d786b3          	mul	a3,a5,a3
30000fb0:	ffff87b7          	lui	a5,0xffff8
30000fb4:	4016d693          	srai	a3,a3,0x1
30000fb8:	00f6d463          	bge	a3,a5,30000fc0 <main+0x62c>
30000fbc:	ffff86b7          	lui	a3,0xffff8
30000fc0:	000087b7          	lui	a5,0x8
30000fc4:	00f6c463          	blt	a3,a5,30000fcc <main+0x638>
30000fc8:	fff78693          	addi	a3,a5,-1 # 7fff <hardware_spi_bootloader+0x7f7b>
30000fcc:	000088b7          	lui	a7,0x8
30000fd0:	00000513          	li	a0,0
30000fd4:	00060813          	mv	a6,a2
30000fd8:	ffff8e37          	lui	t3,0xffff8
30000fdc:	fff88e93          	addi	t4,a7,-1 # 7fff <hardware_spi_bootloader+0x7f7b>
30000fe0:	20200313          	li	t1,514
30000fe4:	00a587b3          	add	a5,a1,a0
30000fe8:	00079783          	lh	a5,0(a5)
30000fec:	00081f03          	lh	t5,0(a6)
30000ff0:	02d787b3          	mul	a5,a5,a3
30000ff4:	40f7d793          	srai	a5,a5,0xf
30000ff8:	01e787b3          	add	a5,a5,t5
30000ffc:	01c7d463          	bge	a5,t3,30001004 <main+0x670>
30001000:	ffff87b7          	lui	a5,0xffff8
30001004:	0117c463          	blt	a5,a7,3000100c <main+0x678>
30001008:	000e8793          	mv	a5,t4
3000100c:	00f81023          	sh	a5,0(a6)
30001010:	00250513          	addi	a0,a0,2
30001014:	00280813          	addi	a6,a6,2
30001018:	fc6516e3          	bne	a0,t1,30000fe4 <main+0x650>
3000101c:	e1048c93          	addi	s9,s1,-496
30001020:	30004eb7          	lui	t4,0x30004
30001024:	000c8693          	mv	a3,s9
30001028:	ae0e8e93          	addi	t4,t4,-1312 # 30003ae0 <sir_sq>
3000102c:	00061783          	lh	a5,0(a2)
30001030:	00260613          	addi	a2,a2,2
30001034:	00468693          	addi	a3,a3,4 # ffff8004 <_data_flash_start+0x7fff6338>
30001038:	02f787b3          	mul	a5,a5,a5
3000103c:	fef6ae23          	sw	a5,-4(a3)
30001040:	300047b7          	lui	a5,0x30004
30001044:	ade78793          	addi	a5,a5,-1314 # 30003ade <proj_q15+0x202>
30001048:	fec792e3          	bne	a5,a2,3000102c <main+0x698>
3000104c:	00000313          	li	t1,0
30001050:	00000513          	li	a0,0
30001054:	00000e13          	li	t3,0
30001058:	00000813          	li	a6,0
3000105c:	00000793          	li	a5,0
30001060:	40400f13          	li	t5,1028
30001064:	006a86b3          	add	a3,s5,t1
30001068:	006e85b3          	add	a1,t4,t1
3000106c:	0006a603          	lw	a2,0(a3)
30001070:	0005a883          	lw	a7,0(a1)
30001074:	00430313          	addi	t1,t1,4 # ffff0004 <_data_flash_start+0x7ffee338>
30001078:	41f65693          	srai	a3,a2,0x1f
3000107c:	41f8d593          	srai	a1,a7,0x1f
30001080:	00c80633          	add	a2,a6,a2
30001084:	011508b3          	add	a7,a0,a7
30001088:	01063833          	sltu	a6,a2,a6
3000108c:	00d786b3          	add	a3,a5,a3
30001090:	00a8b533          	sltu	a0,a7,a0
30001094:	00be05b3          	add	a1,t3,a1
30001098:	00d806b3          	add	a3,a6,a3
3000109c:	00b505b3          	add	a1,a0,a1
300010a0:	00060813          	mv	a6,a2
300010a4:	00068793          	mv	a5,a3
300010a8:	00088513          	mv	a0,a7
300010ac:	00058e13          	mv	t3,a1
300010b0:	fbe31ae3          	bne	t1,t5,30001064 <main+0x6d0>
300010b4:	00001eb7          	lui	t4,0x1
300010b8:	ccde8e93          	addi	t4,t4,-819 # ccd <hardware_spi_bootloader+0xc49>
300010bc:	03d63833          	mulhu	a6,a2,t4
300010c0:	03d687b3          	mul	a5,a3,t4
300010c4:	03d60333          	mul	t1,a2,t4
300010c8:	010787b3          	add	a5,a5,a6
300010cc:	01179e93          	slli	t4,a5,0x11
300010d0:	40f7d793          	srai	a5,a5,0xf
300010d4:	00f35813          	srli	a6,t1,0xf
300010d8:	010ee833          	or	a6,t4,a6
300010dc:	00b7c663          	blt	a5,a1,300010e8 <main+0x754>
300010e0:	48f59c63          	bne	a1,a5,30001578 <main+0xbe4>
300010e4:	49187a63          	bgeu	a6,a7,30001578 <main+0xbe4>
300010e8:	00d04663          	bgtz	a3,300010f4 <main+0x760>
300010ec:	48069a63          	bnez	a3,30001580 <main+0xbec>
300010f0:	48060863          	beqz	a2,30001580 <main+0xbec>
300010f4:	00010537          	lui	a0,0x10
300010f8:	ffe50513          	addi	a0,a0,-2 # fffe <hardware_spi_bootloader+0xff7a>
300010fc:	02a585b3          	mul	a1,a1,a0
30001100:	02a8b7b3          	mulhu	a5,a7,a0
30001104:	02a88533          	mul	a0,a7,a0
30001108:	00f585b3          	add	a1,a1,a5
3000110c:	fd5fe0ef          	jal	ra,300000e0 <__divdi3>
30001110:	46b04863          	bgtz	a1,30001580 <main+0xbec>
30001114:	00059663          	bnez	a1,30001120 <main+0x78c>
30001118:	000087b7          	lui	a5,0x8
3000111c:	46f57263          	bgeu	a0,a5,30001580 <main+0xbec>
30001120:	01051b13          	slli	s6,a0,0x10
30001124:	410b5b13          	srai	s6,s6,0x10
30001128:	300026b7          	lui	a3,0x30002
3000112c:	ccc6a783          	lw	a5,-820(a3) # 30001ccc <first_frame>
30001130:	02d12623          	sw	a3,44(sp)
30001134:	000036b7          	lui	a3,0x3
30001138:	02f12223          	sw	a5,36(sp)
3000113c:	300037b7          	lui	a5,0x30003
30001140:	8d078d93          	addi	s11,a5,-1840 # 300028d0 <prev_mask_q15>
30001144:	33368793          	addi	a5,a3,819 # 3333 <hardware_spi_bootloader+0x32af>
30001148:	000056b7          	lui	a3,0x5
3000114c:	02f12823          	sw	a5,48(sp)
30001150:	ccd68793          	addi	a5,a3,-819 # 4ccd <hardware_spi_bootloader+0x4c49>
30001154:	00000d13          	li	s10,0
30001158:	02f12a23          	sw	a5,52(sp)
3000115c:	21448a93          	addi	s5,s1,532
30001160:	000ba603          	lw	a2,0(s7)
30001164:	000ca503          	lw	a0,0(s9)
30001168:	00000593          	li	a1,0
3000116c:	06c05263          	blez	a2,300011d0 <main+0x83c>
30001170:	40a60533          	sub	a0,a2,a0
30001174:	00055463          	bgez	a0,3000117c <main+0x7e8>
30001178:	00000513          	li	a0,0
3000117c:	41f55593          	srai	a1,a0,0x1f
30001180:	01155313          	srli	t1,a0,0x11
30001184:	00f59593          	slli	a1,a1,0xf
30001188:	41f65693          	srai	a3,a2,0x1f
3000118c:	00f51513          	slli	a0,a0,0xf
30001190:	00b365b3          	or	a1,t1,a1
30001194:	f4dfe0ef          	jal	ra,300000e0 <__divdi3>
30001198:	000087b7          	lui	a5,0x8
3000119c:	00050693          	mv	a3,a0
300011a0:	00f54463          	blt	a0,a5,300011a8 <main+0x814>
300011a4:	fff78693          	addi	a3,a5,-1 # 7fff <hardware_spi_bootloader+0x7f7b>
300011a8:	00000593          	li	a1,0
300011ac:	02a05263          	blez	a0,300011d0 <main+0x83c>
300011b0:	00f69513          	slli	a0,a3,0xf
300011b4:	e4dfe0ef          	jal	ra,30000000 <isqrt_bin>
300011b8:	01051793          	slli	a5,a0,0x10
300011bc:	0007d663          	bgez	a5,300011c8 <main+0x834>
300011c0:	000087b7          	lui	a5,0x8
300011c4:	fff78513          	addi	a0,a5,-1 # 7fff <hardware_spi_bootloader+0x7f7b>
300011c8:	01051593          	slli	a1,a0,0x10
300011cc:	4105d593          	srai	a1,a1,0x10
300011d0:	14800613          	li	a2,328
300011d4:	00058693          	mv	a3,a1
300011d8:	00c5d463          	bge	a1,a2,300011e0 <main+0x84c>
300011dc:	14800693          	li	a3,328
300011e0:	02412783          	lw	a5,36(sp)
300011e4:	01069693          	slli	a3,a3,0x10
300011e8:	4106d693          	srai	a3,a3,0x10
300011ec:	02079063          	bnez	a5,3000120c <main+0x878>
300011f0:	03012783          	lw	a5,48(sp)
300011f4:	000d9603          	lh	a2,0(s11)
300011f8:	02f60633          	mul	a2,a2,a5
300011fc:	03412783          	lw	a5,52(sp)
30001200:	02f686b3          	mul	a3,a3,a5
30001204:	00d606b3          	add	a3,a2,a3
30001208:	40f6d693          	srai	a3,a3,0xf
3000120c:	01069693          	slli	a3,a3,0x10
30001210:	4106d693          	srai	a3,a3,0x10
30001214:	01aa8633          	add	a2,s5,s10
30001218:	00dd9023          	sh	a3,0(s11)
3000121c:	00d61023          	sh	a3,0(a2)
30001220:	002d0d13          	addi	s10,s10,2
30001224:	20200693          	li	a3,514
30001228:	004b8b93          	addi	s7,s7,4
3000122c:	004c8c93          	addi	s9,s9,4
30001230:	002d8d93          	addi	s11,s11,2
30001234:	f2dd16e3          	bne	s10,a3,30001160 <main+0x7cc>
30001238:	00008cb7          	lui	s9,0x8
3000123c:	02c12783          	lw	a5,44(sp)
30001240:	01812603          	lw	a2,24(sp)
30001244:	01412683          	lw	a3,20(sp)
30001248:	fffc8c93          	addi	s9,s9,-1 # 7fff <hardware_spi_bootloader+0x7f7b>
3000124c:	416c8833          	sub	a6,s9,s6
30001250:	01081813          	slli	a6,a6,0x10
30001254:	cc07a623          	sw	zero,-820(a5)
30001258:	41085813          	srai	a6,a6,0x10
3000125c:	00068d13          	mv	s10,a3
30001260:	00060d93          	mv	s11,a2
30001264:	fff00593          	li	a1,-1
30001268:	00008eb7          	lui	t4,0x8
3000126c:	0fe00e13          	li	t3,254
30001270:	1fe00313          	li	t1,510
30001274:	000a9b83          	lh	s7,0(s5)
30001278:	00000513          	li	a0,0
3000127c:	07705263          	blez	s7,300012e0 <main+0x94c>
30001280:	037b88b3          	mul	a7,s7,s7
30001284:	00fb9513          	slli	a0,s7,0xf
30001288:	02c12e23          	sw	a2,60(sp)
3000128c:	02d12a23          	sw	a3,52(sp)
30001290:	02b12823          	sw	a1,48(sp)
30001294:	03012623          	sw	a6,44(sp)
30001298:	40f8d893          	srai	a7,a7,0xf
3000129c:	03112223          	sw	a7,36(sp)
300012a0:	d61fe0ef          	jal	ra,30000000 <isqrt_bin>
300012a4:	01051793          	slli	a5,a0,0x10
300012a8:	02412883          	lw	a7,36(sp)
300012ac:	02c12803          	lw	a6,44(sp)
300012b0:	03012583          	lw	a1,48(sp)
300012b4:	03412683          	lw	a3,52(sp)
300012b8:	03c12603          	lw	a2,60(sp)
300012bc:	0fe00e13          	li	t3,254
300012c0:	1fe00313          	li	t1,510
300012c4:	00008eb7          	lui	t4,0x8
300012c8:	0007d463          	bgez	a5,300012d0 <main+0x93c>
300012cc:	000c8513          	mv	a0,s9
300012d0:	03150533          	mul	a0,a0,a7
300012d4:	40f55513          	srai	a0,a0,0xf
300012d8:	01051513          	slli	a0,a0,0x10
300012dc:	41055513          	srai	a0,a0,0x10
300012e0:	03780bb3          	mul	s7,a6,s7
300012e4:	03650533          	mul	a0,a0,s6
300012e8:	00ab8533          	add	a0,s7,a0
300012ec:	40f55893          	srai	a7,a0,0xf
300012f0:	00055463          	bgez	a0,300012f8 <main+0x964>
300012f4:	00000893          	li	a7,0
300012f8:	00088f13          	mv	t5,a7
300012fc:	01d8c463          	blt	a7,t4,30001304 <main+0x970>
30001300:	000c8f13          	mv	t5,s9
30001304:	000d9883          	lh	a7,0(s11)
30001308:	000d1503          	lh	a0,0(s10)
3000130c:	03e888b3          	mul	a7,a7,t5
30001310:	03e50533          	mul	a0,a0,t5
30001314:	40f8d893          	srai	a7,a7,0xf
30001318:	01089893          	slli	a7,a7,0x10
3000131c:	4108d893          	srai	a7,a7,0x10
30001320:	011d9023          	sh	a7,0(s11)
30001324:	40f55513          	srai	a0,a0,0xf
30001328:	00ad1023          	sh	a0,0(s10)
3000132c:	02be6063          	bltu	t3,a1,3000134c <main+0x9b8>
30001330:	01812783          	lw	a5,24(sp)
30001334:	40a00533          	neg	a0,a0
30001338:	01878f33          	add	t5,a5,s8
3000133c:	01412783          	lw	a5,20(sp)
30001340:	011f1023          	sh	a7,0(t5)
30001344:	018788b3          	add	a7,a5,s8
30001348:	00a89023          	sh	a0,0(a7)
3000134c:	ffec0c13          	addi	s8,s8,-2
30001350:	002a8a93          	addi	s5,s5,2
30001354:	002d8d93          	addi	s11,s11,2
30001358:	002d0d13          	addi	s10,s10,2
3000135c:	00158593          	addi	a1,a1,1
30001360:	f06c1ae3          	bne	s8,t1,30001274 <main+0x8e0>
30001364:	00000513          	li	a0,0
30001368:	20000813          	li	a6,512
3000136c:	00050593          	mv	a1,a0
30001370:	00000793          	li	a5,0
30001374:	00900713          	li	a4,9
30001378:	0015f893          	andi	a7,a1,1
3000137c:	00179793          	slli	a5,a5,0x1
30001380:	fff70713          	addi	a4,a4,-1
30001384:	00f8e7b3          	or	a5,a7,a5
30001388:	0015d593          	srli	a1,a1,0x1
3000138c:	fe0716e3          	bnez	a4,30001378 <main+0x9e4>
30001390:	0006d583          	lhu	a1,0(a3)
30001394:	00065883          	lhu	a7,0(a2)
30001398:	00279793          	slli	a5,a5,0x2
3000139c:	01059593          	slli	a1,a1,0x10
300013a0:	0115e5b3          	or	a1,a1,a7
300013a4:	00f987b3          	add	a5,s3,a5
300013a8:	00b7a023          	sw	a1,0(a5)
300013ac:	00150513          	addi	a0,a0,1
300013b0:	00260613          	addi	a2,a2,2
300013b4:	00268693          	addi	a3,a3,2
300013b8:	fb051ae3          	bne	a0,a6,3000136c <main+0x9d8>
300013bc:	00100693          	li	a3,1
300013c0:	600017b7          	lui	a5,0x60001
300013c4:	c0d7a023          	sw	a3,-1024(a5) # 60000c00 <_stack_top+0x2fff8c00>
300013c8:	600016b7          	lui	a3,0x60001
300013cc:	c006a783          	lw	a5,-1024(a3) # 60000c00 <_stack_top+0x2fff8c00>
300013d0:	0027f793          	andi	a5,a5,2
300013d4:	fe078ce3          	beqz	a5,300013cc <main+0xa38>
300013d8:	000017b7          	lui	a5,0x1
300013dc:	04010693          	addi	a3,sp,64
300013e0:	81078793          	addi	a5,a5,-2032 # 810 <hardware_spi_bootloader+0x78c>
300013e4:	00d787b3          	add	a5,a5,a3
300013e8:	00a91613          	slli	a2,s2,0xa
300013ec:	000016b7          	lui	a3,0x1
300013f0:	00c78633          	add	a2,a5,a2
300013f4:	80068693          	addi	a3,a3,-2048 # 800 <hardware_spi_bootloader+0x77c>
300013f8:	00060793          	mv	a5,a2
300013fc:	00d989b3          	add	s3,s3,a3
30001400:	01012683          	lw	a3,16(sp)
30001404:	00278793          	addi	a5,a5,2
30001408:	0006a683          	lw	a3,0(a3)
3000140c:	fed79f23          	sh	a3,-2(a5)
30001410:	01012683          	lw	a3,16(sp)
30001414:	00468693          	addi	a3,a3,4
30001418:	00d12823          	sw	a3,16(sp)
3000141c:	fed992e3          	bne	s3,a3,30001400 <main+0xa6c>
30001420:	000016b7          	lui	a3,0x1
30001424:	fffff7b7          	lui	a5,0xfffff
30001428:	01068693          	addi	a3,a3,16 # 1010 <hardware_spi_bootloader+0xf8c>
3000142c:	04010593          	addi	a1,sp,64
30001430:	00b686b3          	add	a3,a3,a1
30001434:	40078793          	addi	a5,a5,1024 # fffff400 <_data_flash_start+0x7fffd734>
30001438:	00f687b3          	add	a5,a3,a5
3000143c:	00991913          	slli	s2,s2,0x9
30001440:	01278933          	add	s2,a5,s2
30001444:	300047b7          	lui	a5,0x30004
30001448:	0e878693          	addi	a3,a5,232 # 300040e8 <ola_buffer>
3000144c:	40000513          	li	a0,1024
30001450:	03812583          	lw	a1,56(sp)
30001454:	00e607b3          	add	a5,a2,a4
30001458:	00079783          	lh	a5,0(a5)
3000145c:	00e585b3          	add	a1,a1,a4
30001460:	00059583          	lh	a1,0(a1)
30001464:	00270713          	addi	a4,a4,2
30001468:	00468693          	addi	a3,a3,4
3000146c:	02b787b3          	mul	a5,a5,a1
30001470:	ffc6a583          	lw	a1,-4(a3)
30001474:	40f7d793          	srai	a5,a5,0xf
30001478:	00f587b3          	add	a5,a1,a5
3000147c:	fef6ae23          	sw	a5,-4(a3)
30001480:	fca718e3          	bne	a4,a0,30001450 <main+0xabc>
30001484:	01c12683          	lw	a3,28(sp)
30001488:	300047b7          	lui	a5,0x30004
3000148c:	00008537          	lui	a0,0x8
30001490:	20090813          	addi	a6,s2,512
30001494:	0e878613          	addi	a2,a5,232 # 300040e8 <ola_buffer>
30001498:	ffff88b7          	lui	a7,0xffff8
3000149c:	fff50313          	addi	t1,a0,-1 # 7fff <hardware_spi_bootloader+0x7f7b>
300014a0:	00062703          	lw	a4,0(a2)
300014a4:	0006a783          	lw	a5,0(a3)
300014a8:	02f705b3          	mul	a1,a4,a5
300014ac:	02f717b3          	mulh	a5,a4,a5
300014b0:	00f5d713          	srli	a4,a1,0xf
300014b4:	01179793          	slli	a5,a5,0x11
300014b8:	00e7e7b3          	or	a5,a5,a4
300014bc:	0117d463          	bge	a5,a7,300014c4 <main+0xb30>
300014c0:	ffff87b7          	lui	a5,0xffff8
300014c4:	00a7c463          	blt	a5,a0,300014cc <main+0xb38>
300014c8:	00030793          	mv	a5,t1
300014cc:	00f91023          	sh	a5,0(s2)
300014d0:	00290913          	addi	s2,s2,2
300014d4:	00460613          	addi	a2,a2,4
300014d8:	00468693          	addi	a3,a3,4
300014dc:	fd2812e3          	bne	a6,s2,300014a0 <main+0xb0c>
300014e0:	300047b7          	lui	a5,0x30004
300014e4:	0e878713          	addi	a4,a5,232 # 300040e8 <ola_buffer>
300014e8:	40070713          	addi	a4,a4,1024
300014ec:	0e878793          	addi	a5,a5,232
300014f0:	4007a683          	lw	a3,1024(a5)
300014f4:	00478793          	addi	a5,a5,4
300014f8:	fed7ae23          	sw	a3,-4(a5)
300014fc:	fee79ae3          	bne	a5,a4,300014f0 <main+0xb5c>
30001500:	300047b7          	lui	a5,0x30004
30001504:	0e878793          	addi	a5,a5,232 # 300040e8 <ola_buffer>
30001508:	4007a023          	sw	zero,1024(a5)
3000150c:	00478793          	addi	a5,a5,4
30001510:	fee79ce3          	bne	a5,a4,30001508 <main+0xb74>
30001514:	222207b7          	lui	a5,0x22220
30001518:	00fa67b3          	or	a5,s4,a5
3000151c:	30007937          	lui	s2,0x30007
30001520:	00f92023          	sw	a5,0(s2) # 30007000 <input_write_ptr+0x2718>
30001524:	001a0a13          	addi	s4,s4,1
30001528:	00800793          	li	a5,8
3000152c:	82fa1ee3          	bne	s4,a5,30000d68 <main+0x3d4>
30001530:	000017b7          	lui	a5,0x1
30001534:	04010713          	addi	a4,sp,64
30001538:	01078793          	addi	a5,a5,16 # 1010 <hardware_spi_bootloader+0xf8c>
3000153c:	00e787b3          	add	a5,a5,a4
30001540:	fffff537          	lui	a0,0xfffff
30001544:	00a78533          	add	a0,a5,a0
30001548:	10000593          	li	a1,256
3000154c:	60050513          	addi	a0,a0,1536 # fffff600 <_data_flash_start+0x7fffd934>
30001550:	af1fe0ef          	jal	ra,30000040 <io_hop>
30001554:	555557b7          	lui	a5,0x55555
30001558:	55578793          	addi	a5,a5,1365 # 55555555 <_stack_top+0x2554d555>
3000155c:	00f92023          	sw	a5,0(s2)
30001560:	0000006f          	j	30001560 <main+0xbcc>
30001564:	000017b7          	lui	a5,0x1
30001568:	01078793          	addi	a5,a5,16 # 1010 <hardware_spi_bootloader+0xf8c>
3000156c:	04010713          	addi	a4,sp,64
30001570:	00e787b3          	add	a5,a5,a4
30001574:	8ddff06f          	j	30000e50 <main+0x4bc>
30001578:	00000b13          	li	s6,0
3000157c:	badff06f          	j	30001128 <main+0x794>
30001580:	000087b7          	lui	a5,0x8
30001584:	fff78b13          	addi	s6,a5,-1 # 7fff <hardware_spi_bootloader+0x7f7b>
30001588:	ba1ff06f          	j	30001128 <main+0x794>

3000158c <fft_twiddles>:
3000158c:	7fff0000 7ffdfe6e 7ff5fcdc 7fe9fb4a     ....n.......J...
3000159c:	7fd8f9b8 7fc1f827 7fa6f696 7f86f505     ....'...........
300015ac:	7f61f374 7f37f1e4 7f09f055 7ed5eec6     t.a...7.U......~
300015bc:	7e9ced38 7e5febab 7e1dea1e 7dd5e892     8..~.._~...~...}
300015cc:	7d89e707 7d39e57e 7ce3e3f5 7c88e26d     ...}~.9}...|m..|
300015dc:	7c29e0e6 7bc5df61 7b5cdddd 7aeedc5a     ..)|a..{..\{Z..z
300015ec:	7a7cdad8 7a05d958 7989d7da 7909d65d     ..|zX..z...y]..y
300015fc:	7884d4e1 77fad367 776bd1ef 76d8d079     ...xg..w..kwy..v
3000160c:	7641cf05 75a5cd92 7504cc21 745fcab3     ..Av...u!..u.._t
3000161c:	73b5c946 7307c7dc 7254c674 719dc50e     F..s...st.Tr...q
3000162c:	70e2c3aa 7022c248 6f5ec0e9 6e96bf8d     ...pH."p..^o...n
3000163c:	6dc9be32 6cf8bcdb 6c23bb86 6b4aba33     2..m...l..#l3.Jk
3000164c:	6a6db8e4 698bb797 68a6b64c 67bcb505     ..mj...iL..h...g
3000165c:	66cfb3c1 65ddb27f 64e8b141 63eeb005     ...f...eA..d...c
3000166c:	62f1aecd 61f0ad98 60ebac65 5fe3ab37     ...b...ae..`7.._
3000167c:	5ed7aa0b 5dc7a8e3 5cb3a7be 5b9ca69c     ...^...]...\...[
3000168c:	5a82a57e 5964a464 5842a34d 571da239     ~..Zd.dYM.BX9..W
3000169c:	55f5a129 54c9a01d 539b9f15 52689e10     )..U...T...S..hR
300016ac:	51339d0f 4ffb9c12 4ebf9b18 4d819a23     ..3Q...O...N#..M
300016bc:	4c3f9931 4afb9844 49b4975a 48699675     1.?LD..JZ..Iu.iH
300016cc:	471c9593 45cd94b6 447a93dd 43259308     ...G...E..zD..%C
300016dc:	41ce9237 4073916a 3f1790a2 3db88fde     7..Aj.s@...?...=
300016ec:	3c568f1e 3af28e63 398c8dac 38248cf9     ..V<c..:...9..$8
300016fc:	36ba8c4b 354d8ba1 33df8afc 326e8a5b     K..6..M5...3[.n2
3000170c:	30fb89bf 2f878928 2e118895 2c998806     ...0(../.......,
3000171c:	2b1f877c 29a386f7 28268677 26a885fb     |..+...)w.&(...&
3000172c:	25288584 23a68512 222384a4 209f843b     ..(%...#..#";.. 
3000173c:	1f1a83d7 1d938378 1c0b831d 1a8282c7     ....x...........
3000174c:	18f98277 176e822b 15e281e3 145581a1     w...+.n.......U.
3000175c:	12c88164 113a812b 0fab80f7 0e1c80c9     d...+.:.........
3000176c:	0c8c809f 0afb807a 096a805a 07d9803f     ....z...Z.j.?...
3000177c:	06488028 04b68017 0324800b 01928003     (.H.......$.....
3000178c:	00008001 fe6e8003 fcdc800b fb4a8017     ......n.......J.
3000179c:	f9b88028 f827803f f696805a f505807a     (...?.'.Z...z...
300017ac:	f374809f f1e480c9 f05580f7 eec6812b     ..t.......U.+...
300017bc:	ed388164 ebab81a1 ea1e81e3 e892822b     d.8.........+...
300017cc:	e7078277 e57e82c7 e3f5831d e26d8378     w.....~.....x.m.
300017dc:	e0e683d7 df61843b dddd84a4 dc5a8512     ....;.a.......Z.
300017ec:	dad88584 d95885fb d7da8677 d65d86f7     ......X.w.....].
300017fc:	d4e1877c d3678806 d1ef8895 d0798928     |.....g.....(.y.
3000180c:	cf0589bf cd928a5b cc218afc cab38ba1     ....[.....!.....
3000181c:	c9468c4b c7dc8cf9 c6748dac c50e8e63     K.F.......t.c...
3000182c:	c3aa8f1e c2488fde c0e990a2 bf8d916a     ......H.....j...
3000183c:	be329237 bcdb9308 bb8693dd ba3394b6     7.2...........3.
3000184c:	b8e49593 b7979675 b64c975a b5059844     ....u...Z.L.D...
3000185c:	b3c19931 b27f9a23 b1419b18 b0059c12     1...#.....A.....
3000186c:	aecd9d0f ad989e10 ac659f15 ab37a01d     ..........e...7.
3000187c:	aa0ba129 a8e3a239 a7bea34d a69ca464     )...9...M...d...
3000188c:	a57ea57e a464a69c a34da7be a239a8e3     ~.~...d...M...9.
3000189c:	a129aa0b a01dab37 9f15ac65 9e10ad98     ..).7...e.......
300018ac:	9d0faecd 9c12b005 9b18b141 9a23b27f     ........A.....#.
300018bc:	9931b3c1 9844b505 975ab64c 9675b797     ..1...D.L.Z...u.
300018cc:	9593b8e4 94b6ba33 93ddbb86 9308bcdb     ....3...........
300018dc:	9237be32 916abf8d 90a2c0e9 8fdec248     2.7...j.....H...
300018ec:	8f1ec3aa 8e63c50e 8dacc674 8cf9c7dc     ......c.t.......
300018fc:	8c4bc946 8ba1cab3 8afccc21 8a5bcd92     F.K.....!.....[.
3000190c:	89bfcf05 8928d079 8895d1ef 8806d367     ....y.(.....g...
3000191c:	877cd4e1 86f7d65d 8677d7da 85fbd958     ..|.].....w.X...
3000192c:	8584dad8 8512dc5a 84a4dddd 843bdf61     ....Z.......a.;.
3000193c:	83d7e0e6 8378e26d 831de3f5 82c7e57e     ....m.x.....~...
3000194c:	8277e707 822be892 81e3ea1e 81a1ebab     ..w...+.........
3000195c:	8164ed38 812beec6 80f7f055 80c9f1e4     8.d...+.U.......
3000196c:	809ff374 807af505 805af696 803ff827     t.....z...Z.'.?.
3000197c:	8028f9b8 8017fb4a 800bfcdc 8003fe6e     ..(.J.......n...

3000198c <trigger_vecs_q15>:
	...

30001b90 <__clz_tab>:
30001b90:	02020100 03030303 04040404 04040404     ................
30001ba0:	05050505 05050505 05050505 05050505     ................
30001bb0:	06060606 06060606 06060606 06060606     ................
30001bc0:	06060606 06060606 06060606 06060606     ................
30001bd0:	07070707 07070707 07070707 07070707     ................
30001be0:	07070707 07070707 07070707 07070707     ................
30001bf0:	07070707 07070707 07070707 07070707     ................
30001c00:	07070707 07070707 07070707 07070707     ................
30001c10:	08080808 08080808 08080808 08080808     ................
30001c20:	08080808 08080808 08080808 08080808     ................
30001c30:	08080808 08080808 08080808 08080808     ................
30001c40:	08080808 08080808 08080808 08080808     ................
30001c50:	08080808 08080808 08080808 08080808     ................
30001c60:	08080808 08080808 08080808 08080808     ................
30001c70:	08080808 08080808 08080808 08080808     ................
30001c80:	08080808 08080808 08080808 08080808     ................
