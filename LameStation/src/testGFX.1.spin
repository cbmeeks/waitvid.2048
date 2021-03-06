CON
  _clkmode = XTAL1|PLL16X
  _xinfreq = 5_000_000

OBJ
   gfx: "coreGFX"
  view: "coreView"

   dbg: "FullDuplexSerial"

PUB null

  dbg.start(31, 30, %0000, 115200)

  gfx.init($02000000|view.init(0))
  waitcnt(clkfreq + cnt)
  gfx.fillBuffer(0, %%33333333)
  gfx.postBuffer

  waitcnt(clkfreq*2 + cnt)
  gfx.copybuffer(0, @gfx_rpgtowncrop)
  gfx.postBuffer

  waitcnt(clkfreq*2 + cnt)
  view.setn(@gfx_rpgtowncrop, 0)

' speed
{
  dbg.tx(0)
  repeat
    view.waitVBL
    frqa := cnt
    gfx.postBuffer
    frqb := cnt
    gfx.postBuffer
    vscl := cnt
    dbg.hex(frqa, 8)
    dbg.tx(32)
    dbg.hex(frqb - frqa, 8)
    dbg.tx(32)
    dbg.hex(vscl - frqa, 8)
    dbg.tx(13)
    waitcnt(clkfreq + cnt)
'}
  waitpne(0, 0, 0)

PRI speed : a | t, x, y

  waitcnt(clkfreq*3 + cnt)

  gfx.fillbuffer(0, 0)

  frqa := cnt
  frqb := cnt

  dbg.tx(0)
  repeat 10
    t := -cnt
    repeat 10000
      x := ||(?frqa // 121) -8
      y := ||(?frqb //  57) -8
      gfx.blitSprite(0, @gfx_blackhole, x, y, 0)
    t +=  cnt
    a += t
    dbg.dec(t)
    dbg.tx(13)

  dbg.tx(13)
  dbg.dec(a/10 - 53_000_000)
  dbg.tx(13)

  gfx.postBuffer
  waitcnt(clkfreq*3 + cnt)

DAT

word    2048  'frameboost
word    128, 64   'width, height

gfx_rpgtowncrop

word    $43c4, $d7c0, $d7c3, $d7c3, $c3d7, $c3d7, $03d7, $575c, $31f0, $43c4, $d7c0, $d7c3, $c3d7, $d7c3, $d7c3, $d7c3
word    $1551, $3d7c, $3d7c, $3d7c, $3d7c, $3d7c, $3d7c, $5515, $0000, $1551, $3d7c, $3d7c, $3d7c, $3d7c, $3d7c, $3d7c
word    $f55c, $c3d4, $c3d7, $c3d7, $d7c3, $d7c3, $17c3, $5d57, $4c7c, $f55c, $c3d4, $c3d7, $d7c3, $c3d7, $c3d7, $c3d7
word    $3554, $7c3f, $7c3d, $7c3d, $7c3d, $7c3d, $fc3d, $d555, $4000, $3554, $7c3f, $7c3d, $7c3d, $7c3d, $7c3d, $7c3d
word    $f554, $d7c0, $d7c3, $d7c3, $c3d7, $c3d7, $03d7, $45d5, $31f1, $f554, $d7c0, $d7c3, $c3d7, $d7c3, $d7c3, $d7c3
word    $3554, $3d7c, $3d7c, $3d7c, $3d7c, $3d7c, $3d7c, $5557, $0000, $3554, $3d7c, $3d7c, $3d7c, $3d7c, $3d7c, $3d7c
word    $0ff4, $c3d4, $c3d7, $c3d7, $d7c3, $d7c3, $17c3, $7551, $4c7c, $0ff4, $c3d4, $c3d7, $d7c3, $c3d7, $c3d7, $c3d7
word    $50c1, $7c3f, $7c3d, $7c3d, $7c3d, $7c3d, $fc3d, $5d55, $4000, $50c1, $7c3f, $7c3d, $7c3d, $7c3d, $7c3d, $7c3d
word    $43c4, $d7c0, $d7c3, $d7c3, $c3d7, $c3d7, $03d7, $575c, $31f0, $575c, $d7c0, $03c3, $c3c0, $d7c3, $d7c3, $03c3
word    $1551, $3d7c, $3d7c, $3d7c, $3d7c, $3d7c, $3d7c, $5515, $0000, $5515, $3d7c, $003c, $3c00, $3d7c, $3d7c, $003c
word    $f55c, $c3d4, $c3d7, $c3d7, $d7c3, $d7c3, $17c3, $5d57, $4c7c, $5d57, $c3d4, $1143, $c144, $c3d7, $c3d7, $1143
word    $3554, $7c3f, $7c3d, $3c3d, $7c3c, $7c3d, $fc3d, $d555, $4000, $d555, $3c3f, $1154, $7c04, $7c3d, $3c3d, $1154
word    $f554, $d7c0, $d7c3, $43c3, $c3c1, $c3d7, $03d7, $45d5, $31f1, $45d5, $43c0, $1155, $d7c0, $d7c3, $43c3, $1155
word    $3554, $3d7c, $3d7c, $543c, $3c15, $3d7c, $3d7c, $5557, $0000, $5557, $543c, $1155, $3d7c, $3d7c, $543c, $1155
word    $0ff4, $c3d4, $c3d7, $0003, $c000, $d7c3, $17c3, $7551, $4c7c, $7551, $0000, $1000, $c3d4, $c3d7, $0003, $1000
word    $50c1, $7c3f, $7c3d, $fffc, $3fff, $7c3d, $fc3d, $5d55, $4000, $5d55, $fffc, $03ff, $7c3f, $7c3d, $fffc, $03ff
word    $575c, $d7c0, $03c3, $0000, $0000, $c3c0, $03d7, $575c, $31f0, $575c, $0000, $0000, $d7c0, $03c3, $0000, $0000
word    $5515, $3d7c, $003c, $5555, $5555, $3c00, $3d7c, $5515, $0000, $5515, $0000, $0000, $3d7c, $003c, $5555, $5555
word    $5d57, $c3d4, $1143, $5555, $5555, $c144, $17c3, $5d57, $4c7c, $5d57, $4444, $4444, $c3d4, $1143, $5555, $5555
word    $d555, $3c3f, $1154, $5555, $5555, $1544, $fc3c, $d555, $4000, $d555, $4444, $4444, $3c3f, $1154, $5555, $5555
word    $45d5, $43c0, $1155, $5555, $5555, $5544, $03c1, $45d5, $31f1, $45d5, $0000, $0000, $43c0, $1155, $5555, $5555
word    $5557, $543c, $1155, $5555, $5555, $5544, $3c15, $5557, $0000, $5557, $0000, $0000, $543c, $1155, $5555, $5555
word    $7551, $0000, $1000, $0000, $0000, $0004, $0000, $7551, $4c7c, $7551, $1554, $1554, $0000, $1000, $0000, $0000
word    $5d55, $fffc, $03ff, $ffff, $ffff, $ffc0, $3fff, $5d55, $4000, $5d55, $0000, $0000, $fffc, $03ff, $ffff, $ffff
word    $575c, $0000, $0000, $0000, $0000, $0000, $0000, $575c, $31f0, $575c, $575c, $43c4, $0000, $0000, $0000, $0000
word    $5515, $0000, $0000, $3ffc, $3ffc, $0000, $0000, $5515, $0000, $5515, $5515, $1551, $0000, $0000, $3ffc, $0000
word    $5d57, $4444, $4444, $355c, $355c, $4444, $4444, $5d57, $4c7c, $5d57, $5d57, $f55c, $4444, $4444, $355c, $4444
word    $d555, $4444, $4444, $355c, $355c, $4444, $4444, $d555, $4000, $d555, $d555, $3554, $4444, $4444, $355c, $4444
word    $45d5, $0000, $0000, $03fc, $3fc0, $0000, $0000, $45d5, $31f1, $45d5, $45d5, $f554, $0000, $0000, $03fc, $0000
word    $5557, $0000, $0000, $355c, $355c, $0000, $0000, $5557, $0000, $5557, $5557, $3554, $0000, $0000, $355c, $0000
word    $7551, $1554, $1554, $3ffc, $3ffc, $1554, $1554, $7551, $4c7c, $7551, $7551, $0ff4, $1554, $1554, $3ffc, $1554
word    $5d55, $0000, $0000, $0000, $0000, $0000, $0000, $5d55, $4000, $5d55, $5d55, $50c1, $0000, $0000, $0000, $0000
word    $5554, $575c, $575c, $575c, $31f0, $4000, $575c, $575c, $31f0, $575c, $575c, $575c, $575c, $575c, $31f0, $4000
word    $5005, $5515, $5515, $5515, $0000, $3ffc, $5515, $5515, $0000, $5515, $5515, $5515, $5515, $5515, $0000, $3ffc
word    $4711, $5d57, $5d57, $5d57, $4c7c, $30cc, $5d57, $5d57, $4c7c, $5d57, $5d57, $5d57, $5d57, $5d57, $4c7c, $30cc
word    $0df0, $d555, $d555, $d555, $4000, $3ffc, $d555, $d555, $4000, $d555, $d555, $d555, $d555, $d555, $4000, $3ffc
word    $1cdc, $45d5, $45d5, $45d5, $31f1, $4001, $45d5, $45d5, $31f1, $45d5, $45d5, $45d5, $45d5, $45d5, $31f1, $4001
word    $11c0, $5557, $5557, $5557, $0000, $5415, $5557, $5557, $0000, $5557, $5557, $5557, $5557, $5557, $0000, $5415
word    $0f10, $7551, $7551, $7551, $4c7c, $5714, $7551, $7551, $4c7c, $7551, $7551, $7551, $7551, $7551, $4c7c, $5714
word    $11c0, $5d55, $5d55, $5d55, $4000, $1575, $5d55, $5d55, $4000, $5d55, $5d55, $5d55, $5d55, $5d55, $4000, $1575
word    $3300, $575c, $575c, $575c, $f1f0, $f1f0, $f1f0, $f1f0, $f1f0, $f1f0, $f1f0, $f1f0, $f1f0, $f1f0, $f1f0, $f1f0
word    $0000, $5515, $5515, $5515, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001
word    $4001, $5d57, $5d57, $5d57, $7c7c, $7c7c, $7c7c, $7c7c, $7c7c, $7c7c, $7c7c, $7c7c, $7c7c, $7c7c, $7c7c, $7c7c
word    $5c15, $d555, $d555, $d555, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
word    $54dd, $45d5, $45d5, $45d5, $f1f1, $f1f1, $f1f1, $f1f1, $f1f1, $f1f1, $f1f1, $f1f1, $f1f1, $f1f1, $f1f1, $f1f1
word    $7715, $5557, $5557, $5557, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001, $0001
word    $4cf1, $7551, $7551, $7551, $7c7c, $7c7c, $7c7c, $7c7c, $7c7c, $7c7c, $7c7c, $7c7c, $7c7c, $7c7c, $7c7c, $7c7c
word    $5555, $5d55, $5d55, $5d55, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000
word    $575c, $575c, $43c4, $575c, $575c, $575c, $575c, $575c, $575c, $575c, $575c, $575c, $575c, $575c, $575c, $575c
word    $5515, $5515, $1551, $5515, $5515, $5515, $5515, $5515, $5515, $5515, $5515, $5515, $5515, $5515, $5515, $5515
word    $5d57, $5d57, $f55c, $5d57, $5d57, $5d57, $5d57, $5d57, $5d57, $5d57, $5d57, $5d57, $5d57, $5d57, $5d57, $5d57
word    $d555, $d555, $3554, $d555, $d555, $d555, $d555, $d555, $d555, $d555, $d555, $d555, $d555, $d555, $d555, $d555
word    $45d5, $45d5, $f554, $45d5, $45d5, $45d5, $45d5, $45d5, $45d5, $45d5, $45d5, $45d5, $45d5, $45d5, $45d5, $45d5
word    $5557, $5557, $3554, $5557, $5557, $5557, $5557, $5557, $5557, $5557, $5557, $5557, $5557, $5557, $5557, $5557
word    $7551, $7551, $0ff4, $7551, $7551, $7551, $7551, $7551, $7551, $7551, $7551, $7551, $7551, $7551, $7551, $7551
word    $5d55, $5d55, $50c1, $5d55, $5d55, $5d55, $5d55, $5d55, $5d55, $5d55, $5d55, $5d55, $5d55, $5d55, $5d55, $5d55
word    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $575c
word    $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $5515
word    $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $5d57
word    $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $d555
word    $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $45d5
word    $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $5557
word    $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $4444, $7551
word    $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000, $5d55

word    144  'frameboost
word    24, 24   'width, height

gfx_blackhole

word    $aaaa, $aaaa, $aaaa, $ff5a, $aaaa, $a5fa, $eaa5, $aaaf, $9abf, $aaa9, $ffff, $9aab, $daa9, $0003, $9aa7, $5aa9
word    $5001, $a6b5, $4ea6, $5405, $a5c1, $cf96, $1f17, $a900, $435a, $0d03, $ab50, $056a, $0000, $ab14, $15aa, $5000
word    $ab01, $57aa, $5500, $ab00, $f7aa, $5f55, $ab00, $d3aa, $17d7, $ab00, $53aa, $05d7, $af00, $d3ea, $0755, $bfc0
word    $55fe, $1555, $faf0, $1d6d, $5537, $dab5, $fd55, $d437, $6aa5, $b5a5, $d7f7, $6a57, $a5aa, $deb6, $55aa, $a5aa
word    $9e96, $aaaa, $a6aa, $9696, $aaaa, $aaaa, $aaaa, $aaaa

DAT