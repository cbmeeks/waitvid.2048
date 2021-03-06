''
'' VGA display 100xH (dual cog) - video driver and pixel generator
''
''        Author: Marko Lukat
'' Last modified: 2012/03/24
''       Version: 0.8
''
'' long[par][0]:  screen:      [!Z]:addr =   16:16 -> zero (accepted)
'' long[par][1]:    font: size:[!Z]:addr =  8:8:16 -> zero (accepted)
'' long[par][2]: colours:  c/a:[!Z]:addr = 1:15:16 -> zero (accepted), optional colour [buffer]
'' long[par][3]: frame indicator/sync lock
''
'' colour [buffer] format
''
''  - (%0--//--0) address (full colour, word array)
''  - (%1--//---) colour value (waitvid 2 colour VGA format)
'' 
'' acknowledgements
'' - loader and emitter code based on work done by Phil Pilgrim (PhiPi) and Ray Rodrick (Cluso99)
''
'' 20120318: make sure we don't block sync signals while fetching data
''           separate slots for loading pixel and colour data
''           clean-up colours in full colour mode
'' 20120324: relax timing for palette initialisation
'' 
OBJ
  system: "core.con.system"
  
PUB null
'' This is not a top level object.

PUB init(ID, mailbox) : release | cog
                                      
  word[mailbox][6] := word[mailbox][7] := @release

  cog := system.launch( ID, @reader, mailbox) & 7
 {cog :=}system.launch(cog, @reader, mailbox|$8000)

  repeat
  while long[mailbox][3]

  release := TRUE

DAT             org     0                       ' cog binary header

header_2048     long    system#ID_2             ' magic number for a cog binary
                word    header_size             ' header size
                word    %00000000_00000000      ' flags
                word    0, 0                    ' start register, register count

header_size     fit     16
                
DAT             org     0                       ' video driver and pixel generator

reader          jmpret  $, #setup               ' once

                mov     dira, mask              ' drive outputs

' horizontal timing 800(800) 5(40) 16(128) 11(88)
'   vertical timing 600(600) 1(1)   4(4)   23(23)
                
:vsync          mov     do_v, #pointer          ' reset task chain (vsync)
        
'               mov     ecnt, #1
                call    #blank                  ' front porch
'               djnz    ecnt, #$-1

                xor     sync, #$0101            ' active

                mov     ecnt, #4
                call    #blank                  ' vertical sync
                djnz    ecnt, #$-1

                xor     sync, #$0101            ' inactive

                mov     ecnt, #23 -4
                call    #blank                  ' back porch
                djnz    ecnt, #$-1

        if_nc   mov     ecnt, #4                ' |
        if_nc   call    #blank                  ' |
        if_nc   djnz    ecnt, #$-1              ' remaining 4 back porch lines

' Vertical sync chain done, do visible area.

                mov     zwei, scrn              ' screen base address
                mov     drei, plte              ' colour [buffer]
                
                mov     lcnt, #75
                mov     slot, #0                ' secondary: 0 2 1 ...
        if_nc   mov     slot, #1                '   primary:  1 0 2 ...

:line           mov     vscl, many              ' |
                waitvid zero, #0                ' 210 hub windows for pixel data
                
                mov     eins, slot              ' |
                shl     eins, #10               ' 1K per font section
                add     eins, font              ' font base + slot offset

                call    #load_pixels

                mov     vscl, lots              ' |
                waitvid zero, #0                ' 318 hub windows for colour data
                mov     cnt, cnt                ' record sync point

                shr     eins, #24               ' get font size (size:[!Z]:addr = 8:8:16)
                cmp     eins, #8 wz             ' small size: 0->1: 1(update)->(3)->0
        if_z    add     slot, #1                '             1->2: 2(update)->(4)->1
                                                  
                call    #load_colour

' Slot advancement. Note that we deal with the colour buffer earlier
' (in load_colour) to take advantage of the it's-a-buffer condition.

                cmp     slot, #0 wz             ' check current slot state
                add     slot, #2                ' next slot
        if_nz   sub     zwei, #100              ' anything but 0->2 is a line transition
        if_nz   sub     slot, #3                ' 1->(3)->0, 2->(4)->1
                
' We collected 4 lines worth of data, now send them out.
'
' back-to-back waitvid overhead --------+    +---------- additional insn overhead
'               318 hub windows ---+    |    |    +----- intrinsic wait overhead
'                                  |    |    |    |
                long    9{14} + (5088 - 7 - 24 - 14)
                add     cnt, $-1
                waitcnt cnt, #0

                mov     vier, #4                ' -24
                
:emit           movd    :latch, #pal            ' -20   |
                movs    :latch, #pix            ' -16   restore initial settings
                
                mov     vscl, fast              ' -12   speed up (one pixel per frame clock)
                mov     ecnt, #100              '  -8   character count
                
                cmp     ecnt, #1 wz             '  -4   hide djnz overhead
:latch          cmp     0-0, 0-0                '  +0 # WHOP
                add     $-1, d1s1               '  +4   advance indices
        if_nz   djnz    ecnt, #$-3              '  +8   repeat

                mov     vscl, slow              '  -4   slow down
                cmp     sync, slow_pixels       '  +0 # WHOP (horizontal sync)
                mov     cnt, cnt                '       record sync point

' Horizontal sync covers 32 hub windows (equiv 128 insn).

                shr     pix+$00, #8
                shr     pix+$01, #8
                shr     pix+$02, #8
                shr     pix+$03, #8
                shr     pix+$04, #8
                shr     pix+$05, #8
                shr     pix+$06, #8
                shr     pix+$07, #8
                shr     pix+$08, #8
                shr     pix+$09, #8
                shr     pix+$0A, #8
                shr     pix+$0B, #8
                shr     pix+$0C, #8
                shr     pix+$0D, #8
                shr     pix+$0E, #8
                shr     pix+$0F, #8             ' chars 0..15

                shr     pix+$10, #8
                shr     pix+$11, #8
                shr     pix+$12, #8
                shr     pix+$13, #8
                shr     pix+$14, #8
                shr     pix+$15, #8
                shr     pix+$16, #8
                shr     pix+$17, #8
                shr     pix+$18, #8
                shr     pix+$19, #8
                shr     pix+$1A, #8
                shr     pix+$1B, #8
                shr     pix+$1C, #8
                shr     pix+$1D, #8
                shr     pix+$1E, #8
                shr     pix+$1F, #8             ' chars 16..31

                shr     pix+$20, #8
                shr     pix+$21, #8
                shr     pix+$22, #8
                shr     pix+$23, #8
                shr     pix+$24, #8
                shr     pix+$25, #8
                shr     pix+$26, #8
                shr     pix+$27, #8
                shr     pix+$28, #8
                shr     pix+$29, #8
                shr     pix+$2A, #8
                shr     pix+$2B, #8
                shr     pix+$2C, #8
                shr     pix+$2D, #8
                shr     pix+$2E, #8
                shr     pix+$2F, #8             ' chars 32..47

                shr     pix+$30, #8
                shr     pix+$31, #8
                shr     pix+$32, #8
                shr     pix+$33, #8
                shr     pix+$34, #8
                shr     pix+$35, #8
                shr     pix+$36, #8
                shr     pix+$37, #8
                shr     pix+$38, #8
                shr     pix+$39, #8
                shr     pix+$3A, #8
                shr     pix+$3B, #8
                shr     pix+$3C, #8
                shr     pix+$3D, #8
                shr     pix+$3E, #8
                shr     pix+$3F, #8             ' chars 48..63

                shr     pix+$40, #8
                shr     pix+$41, #8
                shr     pix+$42, #8
                shr     pix+$43, #8
                shr     pix+$44, #8
                shr     pix+$45, #8
                shr     pix+$46, #8
                shr     pix+$47, #8
                shr     pix+$48, #8
                shr     pix+$49, #8
                shr     pix+$4A, #8
                shr     pix+$4B, #8
                shr     pix+$4C, #8
                shr     pix+$4D, #8
                shr     pix+$4E, #8
                shr     pix+$4F, #8             ' chars 64..79

                shr     pix+$50, #8
                shr     pix+$51, #8
                shr     pix+$52, #8
                shr     pix+$53, #8
                shr     pix+$54, #8
                shr     pix+$55, #8
                shr     pix+$56, #8
                shr     pix+$57, #8
                shr     pix+$58, #8
                shr     pix+$59, #8
                shr     pix+$5A, #8
                shr     pix+$5B, #8
                shr     pix+$5C, #8
                shr     pix+$5D, #8
                shr     pix+$5E, #8
                shr     pix+$5F, #8             ' chars 80..95

                shr     pix+$60, #8
                shr     pix+$61, #8
                shr     pix+$62, #8
                shr     pix+$63, #8             ' chars 96..99

' We ignore the intra-line-delay when the stripe is finished because
' the worst case delay to the next waitvid is > 24 cycles.
'
                cmp     vier, #1 wz
'
'     back-to-back cmp overhead -------------+    +----- additional insn overhead
'    one horizontal sync period --------+    |    |   +- intrinsic wait overhead
'                                       |    |    |   |
                add     cnt, #9{14} + (512 - 4 - 24 - 14)
        if_nz   waitcnt cnt, #0

                djnz    vier, #:emit            ' -24
                djnz    lcnt, #:line
                
        if_c    mov     ecnt, #4                ' secondary finishes early so
        if_c    call    #blank                  ' let him do some blank lines
        if_c    djnz    ecnt, #$-1              ' before restarting

                jmp     #:vsync
                
                
blank           mov     vscl, line              ' 200/800
                waitvid sync, #%0000
                
' This is where we can update screen buffer, font definition and palette.
' With the setup used we have about 100 hub windows available per line.

                jmpret  do_v, do_v

                mov     vscl, slow              '   8/256
                waitvid sync, slow_pixels
                
blank_ret       ret


load_pixels     movd    :one, #pix+0            ' |
                movd    :two, #pix+1            ' restore initial settings
                
                mov     frqb, zwei              ' current screen base
                shr     frqb, #1{/2}            ' frqb is added twice     
                mov     phsb, #100 -1           ' byte count -1
                
:loop           rdbyte  temp, phsb              ' get character
                shl     temp, #2                ' long index
                add     temp, eins              ' add current font base
:one            rdlong  0-0, temp               ' read 4 scan lines of character
                add     $-1, dst2               ' advance destination
                sub     phsb, #1 wz

                rdbyte  temp, phsb              ' get character
                shl     temp, #2                ' long index
                add     temp, eins              ' add current font base
:two            rdlong  0-0, temp               ' read 4 scan lines of character
                add     $-1, dst2               ' advance destination
        if_nz   djnz    phsb, #:loop

load_pixels_ret ret


load_colour     shr     plte, #31 wz,nr         ' monochrome or colour buffer
        if_nz   jmp     load_colour_ret         ' early return

                movd    :one, #pal+99           ' |
                movd    :two, #pal+98           ' restore initial settings
                
                mov     frqb, drei              ' current colour buffer base
                shr     frqb, #1{/2}            ' frqb is added twice
                mov     phsb, #200 -1           ' byte count -1

:loop           rdword  temp, phsb              ' get colour
                and     temp, mask_import       ' |
                or      temp, idle              ' clean-up
:one            mov     0-0, temp
                sub     $-1, dst2               ' advance destination
                sub     phsb, #3 wz

                rdword  temp, phsb              ' get colour
                and     temp, mask_import       ' |
                or      temp, idle              ' clean-up
:two            mov     0-0, temp
                sub     $-1, dst2               ' advance destination
        if_nz   djnz    phsb, #:loop

                cmp     slot, #0 wz             ' check current slot state
        if_nz   add     drei, #200              ' advance colour buffer
                
load_colour_ret ret

' Stuff to do during vertical blank.

pointer         mov     vref, cnt               ' waitvid reference
                wrlong  vref, fcnt_             ' announce vertical blank
                mov     href, cnt               ' hub window reference

                sub     href, vref
                shr     href, #1                ' 12/13 -> 6
        if_c    cmp     href, #6 wz             ' secondary (primary missed hub window)

                mov     cnt, #5{18} + 6         ' |
  if_z_and_c    add     cnt, #16                ' |
                add     cnt, cnt                ' |
                waitcnt cnt, #0                 ' bring primary/secondary back in line


                rdlong  temp, scrn_ wz          ' |
        if_nz   mov     scrn, temp              ' |
        if_nz   wrlong  zero, scrn_             ' update and acknowledge screen buffer setup
        
                rdlong  temp, font_ wz          ' |
        if_nz   mov     font, temp              ' |
        if_nz   wrlong  zero, font_             ' update and acknowledge font definition setup

                rdlong  temp, plte_ wz          ' |
        if_nz   mov     plte, temp              ' |
        if_nz   wrlong  zero, plte_             ' update and acknowledge colour buffer setup

        if_nz   shr     plte, #31 wz,nr         ' |
        if_nz   call    #palette                ' optionally update palette

{split}         jmpret  do_v, do_v nr           ' End Of Chain (no more tasks for this frame)


palette         and     plte, mask_import       ' |
                or      plte, idle              ' insert idle sync bits

                movd    :one, #pal+0            ' |
                movd    :two, #pal+1            ' restore initial settings

                mov     ecnt, #100/2
                
:one            mov     0-0, plte               ' |
                add     $-1, dst2               ' |
:two            mov     0-0, plte               ' |
                add     $-1, dst2               ' |
                djnz    ecnt, #$-4              ' initialise (line) palette

palette_ret     ret

' initialised data and/or presets

idle            long    hv_idle
sync            long    hv_idle ^ $0200

slow_pixels     long    $001FFFE0               ' 5/16/11 (LSB first)
slow            long      8 << 12 | 256         '   8/256
fast            long      1 << 12 | 8           '   1/8
line            long    200 << 12 | 800         ' 200/800
many            long      0 << 12 | 1680        ' 256/1680 (210 hub windows)
lots            long      0 << 12 | 2544        ' 256/2544 (318 hub windows)

mask_import     long    hv_mask                 ' stay clear of sync bits
mask            long    vpin << (vgrp * 8)      ' pin I/O setup

d1s1            long    1 << 9 | 1              ' dst/src +/-= 1
dst1            long    1 << 9                  ' dst     +/-= 1
dst2            long    2 << 9                  ' dst     +/-= 2

scrn_           long    +0              -12     ' |
font_           long    +4              -12     ' |
plte_           long    +8              -12     ' |
fcnt_           long    12              -12     ' mailbox addresses (local copy)

plte            long    NEGX | dcolour          ' colour [buffer]

hram            long    $00007FFF               ' hub RAM mask  
addr            long    $FFFF8000       +12

setup           add     addr, par wc            ' carry set -> secondary
                and     addr, hram              ' confine to hub RAM

                add     scrn_, addr             ' @long[par][0]
                add     font_, addr             ' @long[par][1]
                add     plte_, addr             ' @long[par][2]
                add     fcnt_, addr             ' @long[par][3]

                muxc    addr, #%10              ' add secondary offset
                rdword  lock, addr              ' release lock location
                wrword  zero, addr              ' up and running

                rdlong  temp, lock wz           ' |
        if_z    jmp     #$-1                    ' synchronized start

'   primary: cnt + 0              
' secondary: cnt + 2

                rdlong  scrn, scrn_             ' get screen address (2n)
                rdlong  font, font_             ' get font address   (2n)

                wrlong  zero, scrn_             ' acknowledge screen buffer setup
                wrlong  zero, font_             ' acknowledge font definition setup

                cmp     scrn, #0 wz             ' if either one is null during
        if_nz   cmp     font, #0 wz             ' initialisation set default colour
        if_z    shl     plte, #(>| ((NEGX | dcolour) >< 32) -1) ' to black-on-black
                                                                
' Upset video h/w ... I don't trust the freezer approach yet (to sync multiple cogs)
' so it's done with a slightly modified stretch/restore sequence.

                rdlong  vref, #0                ' clkfreq
                shr     vref, #10               ' ~1ms
        if_nc   add     vref, #2                ' adjust primary

                add     vref, cnt

                movi    ctrb, #%0_11111_000     ' LOGIC always (loader support)
                movi    ctra, #%0_00001_110     ' PLL, VCO / 2
                movi    frqa, #%0001_00000      ' 5MHz * 16 / 2 = 40MHz

                mov     vscl, #16               ' 256/16
                
                movd    vcfg, #vgrp             ' pin group
                movs    vcfg, #vpin             ' pins
                movi    vcfg, #%0_01_0_00_000   ' VGA, 2 colour mode

                waitcnt vref, #256              ' PLL settled

                waitvid zero, #0                ' dummy (first one is unpredictable)
                waitvid zero, #0                ' point of reference

                sub     vref, cnt               ' difference to target
                shr     vref, #1                ' ... in frame cycles

                add     vscl, vref              ' |
                waitvid zero, #0                ' stretch frame
                mov     vscl, slow              ' |
                waitvid zero, #0                ' force slow frame

' Setup complete, do the heavy lifting upstairs ...

' This is the first time we call palette() so its ret insn is a jmp #0. We can't
' come back here (res overlay) so we simply jump.

                jmp     #palette                ' initialise default (line) palette

                fit

                org     setup
                
' uninitialised data and/or temporaries

ecnt            res     1                       ' element/character count
lcnt            res     1                       ' line count
slot            res     1                       ' character line part [0..2]
href            res     1                       ' hub window reference
vref            res     1                       ' waitvid reference

do_v            res     1                       ' task index (vertical)

scrn            res     1                       ' screen buffer
font            res     1                       ' font definition

pal             res     100                     ' palette buffer
pix             res     100                     ' pattern buffer

lock            res     1                       ' release lock location

temp            res     1
eins            res     1
zwei            res     1
drei            res     1
vier            res     1

                fit
                
CON
  zero    = $1F0                                ' par (dst only)
  vpin    = $0FF                                ' pin group mask
  vgrp    = 2                                   ' pin group
  hv_idle = $01010101 * %00 {%hv}               ' h/v sync inactive
  hv_mask = $FCFCFCFC                           ' colour mask
  dcolour = %%0220_0010 & hv_mask | hv_idle     ' default colour

  res_x   = 800                                 ' |
  res_y   = 600                                 ' |
  res_m   = 4                                   ' UI support
  
DAT