
firmware.elf:     file format elf32-littleriscv


Disassembly of section .text:

00000000 <_start>:
   0:	30001117          	auipc	sp,0x30001
   4:	00010113          	mv	sp,sp
   8:	00001517          	auipc	a0,0x1
   c:	9c450513          	addi	a0,a0,-1596 # 9cc <_data_load_start>
  10:	30000597          	auipc	a1,0x30000
  14:	ff058593          	addi	a1,a1,-16 # 30000000 <_bss_end>
  18:	30000617          	auipc	a2,0x30000
  1c:	fe860613          	addi	a2,a2,-24 # 30000000 <_bss_end>
  20:	00c5dc63          	bge	a1,a2,38 <end_init_data>

00000024 <loop_init_data>:
  24:	00052683          	lw	a3,0(a0)
  28:	00d5a023          	sw	a3,0(a1)
  2c:	00450513          	addi	a0,a0,4
  30:	00458593          	addi	a1,a1,4
  34:	fec5c8e3          	blt	a1,a2,24 <loop_init_data>

00000038 <end_init_data>:
  38:	30000517          	auipc	a0,0x30000
  3c:	fc850513          	addi	a0,a0,-56 # 30000000 <_bss_end>
  40:	30000597          	auipc	a1,0x30000
  44:	fc058593          	addi	a1,a1,-64 # 30000000 <_bss_end>
  48:	00b55863          	bge	a0,a1,58 <end_init_bss>

0000004c <loop_init_bss>:
  4c:	00052023          	sw	zero,0(a0)
  50:	00450513          	addi	a0,a0,4
  54:	feb54ce3          	blt	a0,a1,4c <loop_init_bss>

00000058 <end_init_bss>:
  58:	030000ef          	jal	ra,88 <main>

0000005c <trap>:
  5c:	0000006f          	j	5c <trap>

00000060 <bit_reverse>:
  60:	00050793          	mv	a5,a0
  64:	00900713          	li	a4,9
  68:	00000513          	li	a0,0
  6c:	0017f693          	andi	a3,a5,1
  70:	00151513          	slli	a0,a0,0x1
  74:	fff70713          	addi	a4,a4,-1
  78:	00a6e533          	or	a0,a3,a0
  7c:	0017d793          	srli	a5,a5,0x1
  80:	fe0716e3          	bnez	a4,6c <bit_reverse+0xc>
  84:	00008067          	ret

00000088 <main>:
  88:	fa010113          	addi	sp,sp,-96 # 30000fa0 <_bss_end+0xfa0>
  8c:	400017b7          	lui	a5,0x40001
  90:	00010837          	lui	a6,0x10
  94:	04112e23          	sw	ra,92(sp)
  98:	04812c23          	sw	s0,88(sp)
  9c:	04912a23          	sw	s1,84(sp)
  a0:	05212823          	sw	s2,80(sp)
  a4:	05312623          	sw	s3,76(sp)
  a8:	05412423          	sw	s4,72(sp)
  ac:	05512223          	sw	s5,68(sp)
  b0:	05612023          	sw	s6,64(sp)
  b4:	03712e23          	sw	s7,60(sp)
  b8:	03812c23          	sw	s8,56(sp)
  bc:	03912a23          	sw	s9,52(sp)
  c0:	03a12823          	sw	s10,48(sp)
  c4:	03b12623          	sw	s11,44(sp)
  c8:	3cc00613          	li	a2,972
  cc:	80078693          	addi	a3,a5,-2048 # 40000800 <_stack_start+0xffff800>
  d0:	20000737          	lui	a4,0x20000
  d4:	fff80813          	addi	a6,a6,-1 # ffff <_data_load_start+0xf633>
  d8:	ffff0337          	lui	t1,0xffff0
  dc:	c0078513          	addi	a0,a5,-1024
  e0:	00062583          	lw	a1,0(a2)
  e4:	00e688b3          	add	a7,a3,a4
  e8:	00468693          	addi	a3,a3,4
  ec:	01059793          	slli	a5,a1,0x10
  f0:	4107d793          	srai	a5,a5,0x10
  f4:	40f007b3          	neg	a5,a5
  f8:	feb6ae23          	sw	a1,-4(a3)
  fc:	0107f7b3          	and	a5,a5,a6
 100:	0065f5b3          	and	a1,a1,t1
 104:	00b7e7b3          	or	a5,a5,a1
 108:	00f8a023          	sw	a5,0(a7)
 10c:	00460613          	addi	a2,a2,4
 110:	fca698e3          	bne	a3,a0,e0 <main+0x58>
 114:	200107b7          	lui	a5,0x20010
 118:	00100693          	li	a3,1
 11c:	f0d7a823          	sw	a3,-240(a5) # 2000ff10 <_data_load_start+0x2000f544>
 120:	20020637          	lui	a2,0x20020
 124:	f0d62823          	sw	a3,-240(a2) # 2001ff10 <_data_load_start+0x2001f544>
 128:	00200693          	li	a3,2
 12c:	00d72223          	sw	a3,4(a4) # 20000004 <_data_load_start+0x1ffff638>
 130:	00d7a223          	sw	a3,4(a5)
 134:	20b00613          	li	a2,523
 138:	00c72a23          	sw	a2,20(a4)
 13c:	00c7aa23          	sw	a2,20(a5)
 140:	00d72823          	sw	a3,16(a4)
 144:	00d7a823          	sw	a3,16(a5)
 148:	0007a023          	sw	zero,0(a5)
 14c:	0007a023          	sw	zero,0(a5)
 150:	0007a023          	sw	zero,0(a5)
 154:	0007a023          	sw	zero,0(a5)
 158:	0007a023          	sw	zero,0(a5)
 15c:	0007a023          	sw	zero,0(a5)
 160:	0007a023          	sw	zero,0(a5)
 164:	0007a023          	sw	zero,0(a5)
 168:	00300693          	li	a3,3
 16c:	00d72823          	sw	a3,16(a4)
 170:	00d7a823          	sw	a3,16(a5)
 174:	300017b7          	lui	a5,0x30001
 178:	0007a023          	sw	zero,0(a5) # 30001000 <_stack_start>
 17c:	30000737          	lui	a4,0x30000
 180:	20020537          	lui	a0,0x20020
 184:	00e00813          	li	a6,14
 188:	200106b7          	lui	a3,0x20010
 18c:	200005b7          	lui	a1,0x20000
 190:	80078793          	addi	a5,a5,-2048
 194:	e0052603          	lw	a2,-512(a0) # 2001fe00 <_data_load_start+0x2001f434>
 198:	fec86ee3          	bltu	a6,a2,194 <main+0x10c>
 19c:	0006a023          	sw	zero,0(a3) # 20010000 <_data_load_start+0x2000f634>
 1a0:	e0052603          	lw	a2,-512(a0)
 1a4:	fec86ee3          	bltu	a6,a2,1a0 <main+0x118>
 1a8:	0006a023          	sw	zero,0(a3)
 1ac:	e006a603          	lw	a2,-512(a3)
 1b0:	fe060ee3          	beqz	a2,1ac <main+0x124>
 1b4:	0005a603          	lw	a2,0(a1) # 20000000 <_data_load_start+0x1ffff634>
 1b8:	00161613          	slli	a2,a2,0x1
 1bc:	00c72023          	sw	a2,0(a4) # 30000000 <_bss_end>
 1c0:	e006a603          	lw	a2,-512(a3)
 1c4:	fe060ee3          	beqz	a2,1c0 <main+0x138>
 1c8:	0005a603          	lw	a2,0(a1)
 1cc:	00470713          	addi	a4,a4,4
 1d0:	fcf712e3          	bne	a4,a5,194 <main+0x10c>
 1d4:	00000413          	li	s0,0
 1d8:	300004b7          	lui	s1,0x30000
 1dc:	20000913          	li	s2,512
 1e0:	00040513          	mv	a0,s0
 1e4:	e7dff0ef          	jal	ra,60 <bit_reverse>
 1e8:	02a47263          	bgeu	s0,a0,20c <main+0x184>
 1ec:	00241793          	slli	a5,s0,0x2
 1f0:	00251513          	slli	a0,a0,0x2
 1f4:	009787b3          	add	a5,a5,s1
 1f8:	00a48533          	add	a0,s1,a0
 1fc:	0007a703          	lw	a4,0(a5)
 200:	00052683          	lw	a3,0(a0)
 204:	00d7a023          	sw	a3,0(a5)
 208:	00e52023          	sw	a4,0(a0)
 20c:	00140413          	addi	s0,s0,1
 210:	fd2418e3          	bne	s0,s2,1e0 <main+0x158>
 214:	11111737          	lui	a4,0x11111
 218:	11170793          	addi	a5,a4,273 # 11111111 <_data_load_start+0x11110745>
 21c:	22222737          	lui	a4,0x22222
 220:	00f12623          	sw	a5,12(sp)
 224:	555554b7          	lui	s1,0x55555
 228:	22270793          	addi	a5,a4,546 # 22222222 <_data_load_start+0x22221856>
 22c:	30001cb7          	lui	s9,0x30001
 230:	40001437          	lui	s0,0x40001
 234:	00f12823          	sw	a5,16(sp)
 238:	33333937          	lui	s2,0x33333
 23c:	55548793          	addi	a5,s1,1365 # 55555555 <_stack_start+0x25554555>
 240:	00000d93          	li	s11,0
 244:	800c8d13          	addi	s10,s9,-2048 # 30000800 <_bss_end+0x800>
 248:	c0040413          	addi	s0,s0,-1024 # 40000c00 <_stack_start+0xffffc00>
 24c:	20000a13          	li	s4,512
 250:	60001ab7          	lui	s5,0x60001
 254:	20020b37          	lui	s6,0x20020
 258:	00e00b93          	li	s7,14
 25c:	200109b7          	lui	s3,0x20010
 260:	20000c37          	lui	s8,0x20000
 264:	00f12a23          	sw	a5,20(sp)
 268:	33390913          	addi	s2,s2,819 # 33333333 <_stack_start+0x3332333>
 26c:	001df713          	andi	a4,s11,1
 270:	14070863          	beqz	a4,3c0 <main+0x338>
 274:	000d0593          	mv	a1,s10
 278:	300004b7          	lui	s1,0x30000
 27c:	00eca023          	sw	a4,0(s9)
 280:	00100793          	li	a5,1
 284:	00f42023          	sw	a5,0(s0)
 288:	00042703          	lw	a4,0(s0)
 28c:	00277713          	andi	a4,a4,2
 290:	fe070ce3          	beqz	a4,288 <main+0x200>
 294:	00000713          	li	a4,0
 298:	00070513          	mv	a0,a4
 29c:	00b12e23          	sw	a1,28(sp)
 2a0:	00e12c23          	sw	a4,24(sp)
 2a4:	dbdff0ef          	jal	ra,60 <bit_reverse>
 2a8:	01812703          	lw	a4,24(sp)
 2ac:	01c12583          	lw	a1,28(sp)
 2b0:	02a77263          	bgeu	a4,a0,2d4 <main+0x24c>
 2b4:	00271813          	slli	a6,a4,0x2
 2b8:	00251513          	slli	a0,a0,0x2
 2bc:	01058833          	add	a6,a1,a6
 2c0:	00a58533          	add	a0,a1,a0
 2c4:	00082883          	lw	a7,0(a6)
 2c8:	00052303          	lw	t1,0(a0)
 2cc:	00682023          	sw	t1,0(a6)
 2d0:	01152023          	sw	a7,0(a0)
 2d4:	00170713          	addi	a4,a4,1
 2d8:	fd4710e3          	bne	a4,s4,298 <main+0x210>
 2dc:	00100793          	li	a5,1
 2e0:	c0faa023          	sw	a5,-1024(s5) # 60000c00 <_stack_start+0x2ffffc00>
 2e4:	c00aa703          	lw	a4,-1024(s5)
 2e8:	00277713          	andi	a4,a4,2
 2ec:	fe070ce3          	beqz	a4,2e4 <main+0x25c>
 2f0:	00000713          	li	a4,0
 2f4:	e00b2503          	lw	a0,-512(s6) # 2001fe00 <_data_load_start+0x2001f434>
 2f8:	feabeee3          	bltu	s7,a0,2f4 <main+0x26c>
 2fc:	00e58533          	add	a0,a1,a4
 300:	00052503          	lw	a0,0(a0)
 304:	00a9a023          	sw	a0,0(s3) # 20010000 <_data_load_start+0x2000f634>
 308:	e00b2503          	lw	a0,-512(s6)
 30c:	feabeee3          	bltu	s7,a0,308 <main+0x280>
 310:	0009a023          	sw	zero,0(s3)
 314:	e009a503          	lw	a0,-512(s3)
 318:	fe050ee3          	beqz	a0,314 <main+0x28c>
 31c:	000c2503          	lw	a0,0(s8) # 20000000 <_data_load_start+0x1ffff634>
 320:	00970833          	add	a6,a4,s1
 324:	00151513          	slli	a0,a0,0x1
 328:	00a82023          	sw	a0,0(a6)
 32c:	e009a503          	lw	a0,-512(s3)
 330:	fe050ee3          	beqz	a0,32c <main+0x2a4>
 334:	000c2503          	lw	a0,0(s8)
 338:	00470713          	addi	a4,a4,4
 33c:	80070513          	addi	a0,a4,-2048
 340:	fa051ae3          	bnez	a0,2f4 <main+0x26c>
 344:	00000713          	li	a4,0
 348:	00070513          	mv	a0,a4
 34c:	00e12c23          	sw	a4,24(sp)
 350:	d11ff0ef          	jal	ra,60 <bit_reverse>
 354:	01812703          	lw	a4,24(sp)
 358:	02a77263          	bgeu	a4,a0,37c <main+0x2f4>
 35c:	00271593          	slli	a1,a4,0x2
 360:	00251513          	slli	a0,a0,0x2
 364:	00b485b3          	add	a1,s1,a1
 368:	00a48533          	add	a0,s1,a0
 36c:	0005a803          	lw	a6,0(a1)
 370:	00052883          	lw	a7,0(a0)
 374:	0115a023          	sw	a7,0(a1)
 378:	01052023          	sw	a6,0(a0)
 37c:	00170713          	addi	a4,a4,1
 380:	fd4714e3          	bne	a4,s4,348 <main+0x2c0>
 384:	00c12703          	lw	a4,12(sp)
 388:	020d8063          	beqz	s11,3a8 <main+0x320>
 38c:	00100793          	li	a5,1
 390:	01012703          	lw	a4,16(sp)
 394:	00fd8a63          	beq	s11,a5,3a8 <main+0x320>
 398:	00200793          	li	a5,2
 39c:	01412703          	lw	a4,20(sp)
 3a0:	00fd9463          	bne	s11,a5,3a8 <main+0x320>
 3a4:	00090713          	mv	a4,s2
 3a8:	300007b7          	lui	a5,0x30000
 3ac:	10e7a223          	sw	a4,260(a5) # 30000104 <_bss_end+0x104>
 3b0:	001d8d93          	addi	s11,s11,1
 3b4:	00400713          	li	a4,4
 3b8:	eaed9ae3          	bne	s11,a4,26c <main+0x1e4>
 3bc:	0000006f          	j	3bc <main+0x334>
 3c0:	300005b7          	lui	a1,0x30000
 3c4:	000d0493          	mv	s1,s10
 3c8:	eb5ff06f          	j	27c <main+0x1f4>

000003cc <fft_twiddles>:
 3cc:	7fff0000 7ffdfe6e 7ff5fcdc 7fe9fb4a     ....n.......J...
 3dc:	7fd8f9b8 7fc1f827 7fa6f696 7f86f505     ....'...........
 3ec:	7f61f374 7f37f1e4 7f09f055 7ed5eec6     t.a...7.U......~
 3fc:	7e9ced38 7e5febab 7e1dea1e 7dd5e892     8..~.._~...~...}
 40c:	7d89e707 7d39e57e 7ce3e3f5 7c88e26d     ...}~.9}...|m..|
 41c:	7c29e0e6 7bc5df61 7b5cdddd 7aeedc5a     ..)|a..{..\{Z..z
 42c:	7a7cdad8 7a05d958 7989d7da 7909d65d     ..|zX..z...y]..y
 43c:	7884d4e1 77fad367 776bd1ef 76d8d079     ...xg..w..kwy..v
 44c:	7641cf05 75a5cd92 7504cc21 745fcab3     ..Av...u!..u.._t
 45c:	73b5c946 7307c7dc 7254c674 719dc50e     F..s...st.Tr...q
 46c:	70e2c3aa 7022c248 6f5ec0e9 6e96bf8d     ...pH."p..^o...n
 47c:	6dc9be32 6cf8bcdb 6c23bb86 6b4aba33     2..m...l..#l3.Jk
 48c:	6a6db8e4 698bb797 68a6b64c 67bcb505     ..mj...iL..h...g
 49c:	66cfb3c1 65ddb27f 64e8b141 63eeb005     ...f...eA..d...c
 4ac:	62f1aecd 61f0ad98 60ebac65 5fe3ab37     ...b...ae..`7.._
 4bc:	5ed7aa0b 5dc7a8e3 5cb3a7be 5b9ca69c     ...^...]...\...[
 4cc:	5a82a57e 5964a464 5842a34d 571da239     ~..Zd.dYM.BX9..W
 4dc:	55f5a129 54c9a01d 539b9f15 52689e10     )..U...T...S..hR
 4ec:	51339d0f 4ffb9c12 4ebf9b18 4d819a23     ..3Q...O...N#..M
 4fc:	4c3f9931 4afb9844 49b4975a 48699675     1.?LD..JZ..Iu.iH
 50c:	471c9593 45cd94b6 447a93dd 43259308     ...G...E..zD..%C
 51c:	41ce9237 4073916a 3f1790a2 3db88fde     7..Aj.s@...?...=
 52c:	3c568f1e 3af28e63 398c8dac 38248cf9     ..V<c..:...9..$8
 53c:	36ba8c4b 354d8ba1 33df8afc 326e8a5b     K..6..M5...3[.n2
 54c:	30fb89bf 2f878928 2e118895 2c998806     ...0(../.......,
 55c:	2b1f877c 29a386f7 28268677 26a885fb     |..+...)w.&(...&
 56c:	25288584 23a68512 222384a4 209f843b     ..(%...#..#";.. 
 57c:	1f1a83d7 1d938378 1c0b831d 1a8282c7     ....x...........
 58c:	18f98277 176e822b 15e281e3 145581a1     w...+.n.......U.
 59c:	12c88164 113a812b 0fab80f7 0e1c80c9     d...+.:.........
 5ac:	0c8c809f 0afb807a 096a805a 07d9803f     ....z...Z.j.?...
 5bc:	06488028 04b68017 0324800b 01928003     (.H.......$.....
 5cc:	00008001 fe6e8003 fcdc800b fb4a8017     ......n.......J.
 5dc:	f9b88028 f827803f f696805a f505807a     (...?.'.Z...z...
 5ec:	f374809f f1e480c9 f05580f7 eec6812b     ..t.......U.+...
 5fc:	ed388164 ebab81a1 ea1e81e3 e892822b     d.8.........+...
 60c:	e7078277 e57e82c7 e3f5831d e26d8378     w.....~.....x.m.
 61c:	e0e683d7 df61843b dddd84a4 dc5a8512     ....;.a.......Z.
 62c:	dad88584 d95885fb d7da8677 d65d86f7     ......X.w.....].
 63c:	d4e1877c d3678806 d1ef8895 d0798928     |.....g.....(.y.
 64c:	cf0589bf cd928a5b cc218afc cab38ba1     ....[.....!.....
 65c:	c9468c4b c7dc8cf9 c6748dac c50e8e63     K.F.......t.c...
 66c:	c3aa8f1e c2488fde c0e990a2 bf8d916a     ......H.....j...
 67c:	be329237 bcdb9308 bb8693dd ba3394b6     7.2...........3.
 68c:	b8e49593 b7979675 b64c975a b5059844     ....u...Z.L.D...
 69c:	b3c19931 b27f9a23 b1419b18 b0059c12     1...#.....A.....
 6ac:	aecd9d0f ad989e10 ac659f15 ab37a01d     ..........e...7.
 6bc:	aa0ba129 a8e3a239 a7bea34d a69ca464     )...9...M...d...
 6cc:	a57ea57e a464a69c a34da7be a239a8e3     ~.~...d...M...9.
 6dc:	a129aa0b a01dab37 9f15ac65 9e10ad98     ..).7...e.......
 6ec:	9d0faecd 9c12b005 9b18b141 9a23b27f     ........A.....#.
 6fc:	9931b3c1 9844b505 975ab64c 9675b797     ..1...D.L.Z...u.
 70c:	9593b8e4 94b6ba33 93ddbb86 9308bcdb     ....3...........
 71c:	9237be32 916abf8d 90a2c0e9 8fdec248     2.7...j.....H...
 72c:	8f1ec3aa 8e63c50e 8dacc674 8cf9c7dc     ......c.t.......
 73c:	8c4bc946 8ba1cab3 8afccc21 8a5bcd92     F.K.....!.....[.
 74c:	89bfcf05 8928d079 8895d1ef 8806d367     ....y.(.....g...
 75c:	877cd4e1 86f7d65d 8677d7da 85fbd958     ..|.].....w.X...
 76c:	8584dad8 8512dc5a 84a4dddd 843bdf61     ....Z.......a.;.
 77c:	83d7e0e6 8378e26d 831de3f5 82c7e57e     ....m.x.....~...
 78c:	8277e707 822be892 81e3ea1e 81a1ebab     ..w...+.........
 79c:	8164ed38 812beec6 80f7f055 80c9f1e4     8.d...+.U.......
 7ac:	809ff374 807af505 805af696 803ff827     t.....z...Z.'.?.
 7bc:	8028f9b8 8017fb4a 800bfcdc 8003fe6e     ..(.J.......n...

000007cc <audio_in_data>:
 7cc:	151e2d26 38504224 beb0c800 d3e2ebdc     &-..$BP8........
 7dc:	603b03da f909335b cdf70700 fdc5a0a5     ..;`[3..........
 7ec:	151e2d26 38504224 beb0c800 d3e2ebdc     &-..$BP8........
 7fc:	603b03da f909335b cdf70700 fdc5a0a5     ..;`[3..........
 80c:	151e2d26 38504224 beb0c800 d3e2ebdc     &-..$BP8........
 81c:	603b03da f909335b cdf70700 fdc5a0a5     ..;`[3..........
 82c:	151e2d26 38504224 beb0c800 d3e2ebdc     &-..$BP8........
 83c:	603b03da f909335b cdf70700 fdc5a0a5     ..;`[3..........
 84c:	151e2d26 38504224 beb0c800 d3e2ebdc     &-..$BP8........
 85c:	603b03da f909335b cdf70700 fdc5a0a5     ..;`[3..........
 86c:	151e2d26 38504224 beb0c800 d3e2ebdc     &-..$BP8........
 87c:	603b03da f909335b cdf70700 fdc5a0a5     ..;`[3..........
 88c:	151e2d26 38504224 beb0c800 d3e2ebdc     &-..$BP8........
 89c:	603b03da f909335b cdf70700 fdc5a0a5     ..;`[3..........
 8ac:	151e2d26 38504224 beb0c800 d3e2ebdc     &-..$BP8........
 8bc:	603b03da f909335b cdf70700 fdc5a0a5     ..;`[3..........
 8cc:	151e2d26 38504224 beb0c800 d3e2ebdc     &-..$BP8........
 8dc:	603b03da f909335b cdf70700 fdc5a0a5     ..;`[3..........
 8ec:	151e2d26 38504224 beb0c800 d3e2ebdc     &-..$BP8........
 8fc:	603b03da f909335b cdf70700 fdc5a0a5     ..;`[3..........
 90c:	151e2d26 38504224 beb0c800 d3e2ebdc     &-..$BP8........
 91c:	603b03da f909335b cdf70700 fdc5a0a5     ..;`[3..........
 92c:	151e2d26 38504224 beb0c800 d3e2ebdc     &-..$BP8........
 93c:	603b03da f909335b cdf70700 fdc5a0a5     ..;`[3..........
 94c:	151e2d26 38504224 beb0c800 d3e2ebdc     &-..$BP8........
 95c:	603b03da f909335b cdf70700 fdc5a0a5     ..;`[3..........
 96c:	151e2d26 38504224 beb0c800 d3e2ebdc     &-..$BP8........
 97c:	603b03da f909335b cdf70700 fdc5a0a5     ..;`[3..........
 98c:	151e2d26 38504224 beb0c800 d3e2ebdc     &-..$BP8........
 99c:	603b03da f909335b cdf70700 fdc5a0a5     ..;`[3..........
 9ac:	151e2d26 38504224 beb0c800 d3e2ebdc     &-..$BP8........
 9bc:	603b03da f909335b cdf70700 fdc5a0a5     ..;`[3..........
