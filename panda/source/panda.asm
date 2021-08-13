###############################################################################
# WiiTests - Wii test ROMs and demos written in PPC assembly.
# Copyright (C) 2021  Michelle-Marie Schiller
###############################################################################
# panda.asm - Red Panda bitmap demo.
###############################################################################

    .include  "../../dol.asm"   # DOL header
    .include  "../../start.asm" # Minimal initialization code

    # TODO: Make this work on real HW
    # TODO: Fix vertical timings

    # TODO: Stuff these definitions into dedicated files
    # SPR definitions
    .set      LR , 8
    .set      CTR, 9

    # Register definitions (offsets)
    .set      VI_VTR  , 0x2000
    .set      VI_DCR  , 0x2002
    .set      VI_HTR0 , 0x2004
    .set      VI_HTR1 , 0x2008
    .set      VI_VTO  , 0x200C
    .set      VI_VTE  , 0x2010
    .set      VI_BBEI , 0x2014
    .set      VI_BBOI , 0x2018
    .set      VI_TFBL , 0x201C
    .set      VI_BFBL , 0x2024
    .set      VI_HSR  , 0x204A
    .set      VI_FCT0 , 0x204C
    .set      VI_FCT1 , 0x2050
    .set      VI_FCT2 , 0x2054
    .set      VI_FCT3 , 0x2058
    .set      VI_FCT4 , 0x205C
    .set      VI_FCT5 , 0x2060
    .set      VI_FCT6 , 0x2064
    .set      VI_VICLK, 0x206C

    # Video Interface definitions
    .set      DCR_ENB, 1 << 0 # VI enable
    .set      DCR_RST, 1 << 1 # VI reset
    .set      DCR_NIN, 1 << 2 # VI non-interlaced
    .set      DCR_PAL, 1 << 8 # VI PAL

    .set      VICLK_NINMODE, 1 << 0 # VI Clock non-interlaced

    # Video timing definitions (thanks, libogc)
    .set      TIMING_EQU, 0xA

    .set      TIMING_ACV, 0x240

    .set      TIMING_PRB_ODD , 0x44
    .set      TIMING_PRB_EVEN, 0x44

    .set      TIMING_PSB_ODD , 0
    .set      TIMING_PSB_EVEN, 0

    .set      TIMING_BS1, 0x14
    .set      TIMING_BS2, 0x14
    .set      TIMING_BS3, 0x14
    .set      TIMING_BS4, 0x14

    .set      TIMING_BE1, 0x4D8
    .set      TIMING_BE2, 0x4D8
    .set      TIMING_BE3, 0x4D8
    .set      TIMING_BE4, 0x4D8

    .set      TIMING_NHLINES, 0x4E2
    .set      TIMING_HLW    , 0x1B0

    .set      TIMING_HSY   , 0x40
    .set      TIMING_HCS   , 0x4B
    .set      TIMING_HCE   , 0x6A
    .set      TIMING_HBE640, 0xAC

    .set      TIMING_HBS640, 0x17C

Pool:
    # MemCpy32 - (XFB address, bitmap address, bitmap size) [0x00]
    .4byte    0xC0104000, 0xC0004000 + Data_Panda - 0x100, (End_Data_Panda - Data_Panda) / 4
    # Video Interface - HTR0 [0x0C]
    .4byte    (((TIMING_HCS << 8) | TIMING_HCE) << 16) | TIMING_HLW
    # Video Interface - HTR1 [0x10]
    .4byte    ((TIMING_HBS640 << 1) << 16) | ((TIMING_HBE640 << 7) | TIMING_HSY)
    # Video Interface - VTR [0x14]
    .4byte    (TIMING_ACV << 4) | TIMING_EQU
    # Video Interface - VTO [0x18]
    .4byte    ((TIMING_PSB_ODD + 2) << 16) | (TIMING_PRB_ODD + ((TIMING_ACV << 1) - 2))
    # Video Interface - VTE [0x1C]
    .4byte    ((TIMING_PSB_EVEN + 2) << 16) | (TIMING_PRB_EVEN + ((TIMING_ACV << 1) - 2))
    # Video Interface - BBEI [0x20]
    .4byte    (((TIMING_BE3 << 5) | TIMING_BS3) << 16) | ((TIMING_BE1 << 5) | TIMING_BS1)
    # Video Interface - BBOI [0x24]
    .4byte    (((TIMING_BE4 << 5) | TIMING_BS4) << 16) | ((TIMING_BE2 << 5) | TIMING_BS2)

###############################################################################
# Main() function.
###############################################################################
Main:
    # Save Link Register
    mfspr     r0, LR
    stwu      r0, -4(sp)

    # Get Table of Contents
    lis       r2, POOL_BASE >> 16
    ori       r2, r2, POOL_BASE & 0xFFFF

    # Initialize and set up Video Interface
    bl        InitVI

    # Copy bitmap data to XFB
    lwz       r3, 0(r2)
    lwz       r4, 4(r2)
    lwz       r5, 8(r2)
    bl        MemCpy32

    # Restore Link Register
    lwz       r0, 0(sp)
    mtspr     LR, r0

    addi      sp, sp, 4 # Restore Stack Pointer
    blr

###############################################################################
# Resets and initializes the Video Interface.
# Note: I heavily referenced libogc VI code.
###############################################################################
InitVI:
    # Set CTR
    li        r0, 0x400
    mtspr     CTR, r0

    # Set the RST bit in DCR (=> reset the VI)
    li        r3, DCR_RST
    sth       r3, VI_DCR(r13)

    li        r3, 0

    # Wait 400h "cycles"
    .0:
        bdnz      .0
    
    # Clear RST bit
    sth       r3, VI_DCR(r13)
    
    # TODO: Don't use raw register values

    # Initialize HTR0 and HTR1
    lwz       r3, 0xC(r2)
    stw       r3, VI_HTR0(r13)
    lwz       r3, 0x10(r2)
    stw       r3, VI_HTR1(r13)

    # Initialize VTR
    lwz       r3, 0x14(r2)
    sth       r3, VI_VTR(r13)

    # Initialize VTO and VTE
    lwz       r3, 0x18(r2)
    stw       r3, VI_VTO(r13)
    lwz       r3, 0x1C(r2)
    stw       r3, VI_VTE(r13)

    # Initialize BBEI and BBOI
    lwz       r3, 0x20(r2)
    stw       r3, VI_BBEI(r13)
    lwz       r3, 0x24(r2)
    stw       r3, VI_BBOI(r13)

    # Initialize XFB addresses
    lis       r3, 0x10
    ori       r3, r3, 0x4000
    stw       r3, VI_TFBL(r13)
    stw       r3, VI_BFBL(r13) # This is not necessary for 480p

    # Initialize Filter Coefficient Tables
    lis       r3, 0x1AE7
    ori       r3, r3, 0x71F0
    stw       r3, VI_FCT0(r13)
    lis       r3, 0xDB4
    ori       r3, r3, 0xA574
    stw       r3, VI_FCT1(r13)
    lis       r3, 0xC1
    ori       r3, r3, 0x188E
    stw       r3, VI_FCT2(r13)
    lis       r3, 0xC4C0
    ori       r3, r3, 0xCBE2
    stw       r3, VI_FCT3(r13)
    lis       r3, 0xFCEC
    ori       r3, r3, 0xDECF
    stw       r3, VI_FCT4(r13)
    lis       r3, 0x1313
    ori       r3, r3, 0xF08
    stw       r3, VI_FCT5(r13)
    lis       r3, 8
    ori       r3, r3, 0xC0F
    stw       r3, VI_FCT6(r13)

    # Initialize HSR
    lis       r3, 0x2828
    sth       r3, VI_HSR(r13)

    # Initialize VI_2070h
    li        r3, 0x280
    sth       r3, 0x2070(r13)

    # Initialize VI Clock
    li        r3, VICLK_NINMODE
    sth       r3, VI_VICLK(r13)

    # Enable the VI
    li        r3, DCR_PAL | DCR_NIN | DCR_ENB
    sth       r3, VI_DCR(r13)

    blr

###############################################################################
# Copies n 4-byte words of data from src to dst.
# r3 - dst
# r4 - src
# r5 - n
###############################################################################
MemCpy32:
    # Return if n == 0
    cmpwi     r5, 0
    beqlr

    # Set CTR, get start pointers (=> dst/src + n * 4)
    mtspr     CTR, r5
    slwi      r5, r5, 2
    add       r3, r3, r5
    add       r4, r4, r5

    # Copy data until CTR == 0
    .0:
        lwzu      r5, -4(r4)
        stwu      r5, -4(r3)
        bdnz      .0
    
    blr

###############################################################################
# Repeatedly copies data n times to dst. (Unused)
# r3 - dst
# r4 - data
# r5 - n
###############################################################################
MemSet32:
    # Return if n == 0
    cmpwi     r5, 0
    beqlr

    # Set CTR, get start pointers (=> dst + n * 4)
    mtspr     CTR, r5
    slwi      r5, r5, 2
    add       r3, r3, r5

    # Copy data until CTR == 0
    .0:
        stwu      r4, -4(r3)
        bdnz      .0
    
    blr

Data_Panda:
    .incbin   "panda.ycbycr"

End_Data_Panda:
