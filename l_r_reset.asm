ORG $1A8000

; this code is run when the player presses L + R in a level to reset the current room
activate_room_reset:
		; if we are in first room of level, just level reset
		LDA $141A ; sublevel count
		AND #$7F
		BNE .room_reset
		JSL activate_level_reset
		RTL
		
	.room_reset:
		LDA #$01
		STA !l_r_function
		
		LDA !recent_screen_exit
		LDY !recent_secondary_flag
		JSL set_global_exit
		JSR trigger_screen_exit
		
		RTL

; this code is run when the player presses L + R + A + B in a level to reset the entire level
activate_level_reset:
		LDA #$02
		STA !l_r_function
		
		JSR get_level_low_byte
		LDY #$00
		JSL set_global_exit
		JSR trigger_screen_exit
		
		RTL

; this code is run when the player presses L + R + X + Y in a level to advance to the next room
activate_room_advance:
		PHP
		LDA #$03
		STA !l_r_function
		
		; X = level bank
		LDX #$00
		LDA $13BF ; translevel number
		CMP #$25
		BCC .low_level_bank
		INX
	.low_level_bank:
		
		LDA $141A ; sublevel count
		AND #$7F
		BNE .load_from_backup
		
		; we just entered the level, so backup may not be available
		; we know we entered via screen exit, not from secondary exit
		JSR get_level_low_byte
		LDY #$00
		BRA .merge
	.load_from_backup:
		; we are in some sublevel, so backup is available
		LDA !recent_screen_exit
		LDY !recent_secondary_flag
	
	.merge:
		JSR get_next_sensible_exit
		PHX
		JSL set_global_exit
		JSR trigger_screen_exit
		PLA
		REP #$20
		AND #$00FF
		ASL A
		ASL A
		ASL A
		ASL A
		ASL A
		STA !restore_room_xpos
		
		PLP
		RTL

; set the screen exit for all screens to be set to the exit number in A
; Y = 1 iff this exit is a secondary exit
set_global_exit:
		LDX #$20
	.loop_exits:
		DEX
		STA $19B8,X ; exit table
		BNE .loop_exits
		STY $1B93 ; secondary exit flag
		RTL

; get the low byte of the level number, not the translevel number
get_level_low_byte:
		LDA $13BF ; translevel number
		CMP #$25
		BCC .done
		SEC
		SBC #$24
	.done:
		RTS

; actually trigger the screen exit
trigger_screen_exit:
		LDA #$05
		STA $71 ; player animation trigger
		STZ $88
		STZ $89 ; pipe timers
		
		LDA #$20 ; bow sound
		STA $1DF9 ; apu i/o
		RTS

; given the current sub/level, return a sub/level that 'advances' one room forward
; given A = level number low byte, X = level number high byte, Y = secondary exit flag
; return A = level number low byte / secondary exit number, Y = secondary exit flag, X = mario x position
get_next_sensible_exit:
		PHP
		PHB
		PHK
		PLB
		CPX #$00
		BEQ .low_bank
		TAX
		CPY #$00
		BEQ .high_level_number
		LDA room_advance_table+$000,X
		LDY room_advance_table+$200,X
		PHY
		LDY room_advance_table+$100,X
		PLX
		BRA .done
	.high_level_number:
		LDA room_advance_table+$300,X
		LDY room_advance_table+$500,X
		PHY
		LDY room_advance_table+$400,X
		PLX
		BRA .done
		
	.low_bank:
		TAX
		CPY #$00
		BEQ .low_level_number
		LDA room_advance_table+$600,X
		LDY room_advance_table+$800,X
		PHY
		LDY room_advance_table+$700,X
		PLX
		BRA .done
	.low_level_number:
		LDA room_advance_table+$900,X
		LDY room_advance_table+$B00,X
		PHY
		LDY room_advance_table+$A00,X
		PLX
		
	.done:
		PLB
		PLP
		RTS
		
room_advance_table:
		; =======================================
		; This bin file contains 12 tables that hold screen exit data to be used
		; by the advance room function. Each table is 0x100 bytes long.
		; Table 01: exit number to take if last exit was a secondary exit, bank 1
		; Table 02: secondary exit flag for above table number
		; Table 03: player x position data for above table (sssssxxx, s = screen, x = x pos / 2)
		; Table 04: exit number to take if last exit was a level exit, bank 1
		; Table 05: secondary exit flag for above table number
		; Table 06: player x position data for above table (sssssxxx, s = screen, x = x pos / 2)
		; Table 07: exit number to take if last exit was a secondary exit, bank 0
		; Table 08: secondary exit flag for above table number
		; Table 09: player x position data for above table (sssssxxx, s = screen, x = x pos / 2)
		; Table 10: exit number to take if last exit was a level exit, bank 0
		; Table 11: secondary exit flag for above table number
		; Table 12: player x position data for above table (sssssxxx, s = screen, x = x pos / 2)
		incbin "bin/room_advance_table.bin"
		; =======================================
		
; this code is run when the player presses R + select to make a save state
activate_save_state:
		LDA #$0E ; swim sound
		STA $1DF9 ; apu i/o
		
		LDA !use_poverty_save_states
		BEQ .complete
		JSR go_poverty_save_state
		BRA .done
	.complete:
		JSR go_complete_save_state
	.done:
		LDA #$01
		STA.L !spliced_run
		LDA #$BD
		STA.L !save_state_exists
		RTL
		
go_poverty_save_state:
		PHP
		LDA #$80
		STA $2100 ; force blank
		STZ $4200 ; nmi disable
		
		REP #$10
		
		; save wram $0000-$1FFF to wram $7F9C7B-$7FBC7A
		LDX #$1FFF
	.loop_mirror:
		LDA $7E0000,X
		STA $7F9C7B,X
		DEX
		BPL .loop_mirror
		
		; save wram $C680-$C6DF to $707DA0-$707DFF
		LDX #$005F
	.loop_boss:
		LDA $7EC680,X
		STA $707DA0,X
		DEX
		BPL .loop_boss
		
		; save wram $7F9A7B-$7F9C7A to $707BA0-$707D9F
		LDX #$01FF
	.loop_wiggler:
		LDA $7F9A7B,X
		STA $707BA0,X
		DEX
		BPL .loop_wiggler
		
		; save wram $C800-$FFFF to $700BA0-$70439F
		LDX #$37FF
	.loop_tilemap_low:
		LDA $7EC800,X
		STA $700BA0,X
		DEX
		BPL .loop_tilemap_low
		
		; save wram $7FC800-$7FFFFF to $7043A0-$707B9F
		LDX #$37FF
	.loop_tilemap_high:
		LDA $7FC800,X
		STA $7043A0,X
		DEX
		BPL .loop_tilemap_high
		
		; save cgram w$00-w$FF to $707E00-$707FFF
		LDX #$0000
		STX $2121 ; cgram address
		LDX #$7E00
		STX $4302 ; dma0 destination address
		LDA #$70
		STA $4304 ; dma0 destination bank
		LDX #$0200
		STX $4305 ; dma0 length
		LDA #$80 ; 1-byte
		STA $4300 ; dma0 parameters
		LDA #$3B ; $213B cgram data read
		STA $4301 ; dma0 source
		LDA #$01 ; channel 0
		STA $420B ; dma enable
		
		; save vram w$1000-w$3FFF to wram $7F0000-$7F5FFF
		LDA #$80
		STA $2115 ; vram increment
		LDX #$1000
		STX $2116 ; vram address
		LDX $2139 ; vram data read (dummy read)
		LDX #$0000
		STX $4302 ; dma0 destination address
		LDA #$7F
		STA $4304 ; dma0 destination bank
		LDX #$6000
		STX $4305 ; dma0 length
		LDA #$81 ; 2-byte, low-high
		STA $4300 ; dma0 parameters
		LDA #$39 ; $2139 vram data read
		STA $4301 ; dma0 source
		LDA #$01 ; channel 0
		STA $420B ; dma enable
		
		; save vram w$7000-w$7FFF to wram $7F6000-$7F7FFF
		LDA #$80
		STA $2115 ; vram increment
		LDX #$7000
		STX $2116 ; vram address
		LDX $2139 ; vram data read (dummy read)
		LDX #$6000
		STX $4302 ; dma0 destination address
		LDA #$7F
		STA $4304 ; dma0 destination bank
		LDX #$2000
		STX $4305 ; dma0 length
		LDA #$81 ; 2-byte, low-high
		STA $4300 ; dma0 parameters
		LDA #$39 ; $2139 vram data read
		STA $4301 ; dma0 source
		LDA #$01 ; channel 0
		STA $420B ; dma enable
		
		; save some hardware registers to $7FC7F7 - $7FC7FF
		; TODO this is theoretically correct; however, you can't read from any of these
		; registers other than $2106 so I have to find a clever way to restore these...
		LDA $2106 ; mosaic
		STA $7FC7F7
		LDA $212E ; through main
		STA $7FC7F8
		LDA $212F ; through sub
		STA $7FC7F9
		LDX #$0005
	.loop_screens:
		LDA $2107,X ; BG screen size, tilemap address, character address
		STA $7FC7FA,X
		DEX
		BPL .loop_screens
		
		LDA #$81
		STA $4200 ; nmi enable
		LDA #$0F
		STA $2100 ; exit force blank
		PLP
		RTS
		
go_complete_save_state:
		PHP
		LDA #$80
		STA $2100 ; force blank
		STZ $4200 ; nmi disable
		
		REP #$10
		
		; save wram $0000-$1FFF to $701000-$702FFF
		LDX #$1FFF
	.loop_mirror:
		LDA $7E0000,X
		STA $701000,X
		DEX
		BPL .loop_mirror
		
		; save wram $C680-$C6DF to $703000-$70305F
		LDX #$005F
	.loop_boss:
		LDA $7EC680,X
		STA $703000,X
		DEX
		BPL .loop_boss
		
		; save wram $7F9A7B-$7F9C7A to $703060-$70325F
		LDX #$01FF
	.loop_wiggler:
		LDA $7F9A7B,X
		STA $703060,X
		DEX
		BPL .loop_wiggler
		
		; save wram $C800-$FFFF to $703260-$706A5F
		LDX #$37FF
	.loop_tilemap_low:
		LDA $7EC800,X
		STA $703260,X
		DEX
		BPL .loop_tilemap_low
		
		; save wram $7FC800-$7FFFFF to $710000-$7137FF
		LDX #$37FF
	.loop_tilemap_high:
		LDA $7FC800,X
		STA $710000,X
		DEX
		BPL .loop_tilemap_high
		
		; save cgram w$00-w$FF to $713800-$713AFF
		LDX #$0000
		STX $2121 ; cgram address
		LDX #$3800
		STX $4302 ; dma0 destination address
		LDA #$71
		STA $4304 ; dma0 destination bank
		LDX #$0200
		STX $4305 ; dma0 length
		LDA #$80 ; 1-byte
		STA $4300 ; dma0 parameters
		LDA #$3B ; $213B cgram data read
		STA $4301 ; dma0 source
		LDA #$01 ; channel 0
		STA $420B ; dma enable
		
		; save vram w$0000-w$3FFF to $720000-$727FFF
		LDA #$80
		STA $2115 ; vram increment
		LDX #$0000
		STX $2116 ; vram address
		LDX $2139 ; vram data read (dummy read)
		LDX #$0000
		STX $4302 ; dma0 destination address
		LDA #$72
		STA $4304 ; dma0 destination bank
		LDX #$8000
		STX $4305 ; dma0 length
		LDA #$81 ; 2-byte, low-high
		STA $4300 ; dma0 parameters
		LDA #$39 ; $2139 vram data read
		STA $4301 ; dma0 source
		LDA #$01 ; channel 0
		STA $420B ; dma enable
		
		; save vram w$4000-w$7FFF to $730000-$737FFF
		LDA #$80
		STA $2115 ; vram increment
		LDX #$4000
		STX $2116 ; vram address
		LDX $2139 ; vram data read (dummy read)
		LDX #$0000
		STX $4302 ; dma0 destination address
		LDA #$73
		STA $4304 ; dma0 destination bank
		LDX #$8000
		STX $4305 ; dma0 length
		LDA #$81 ; 2-byte, low-high
		STA $4300 ; dma0 parameters
		LDA #$39 ; $2139 vram data read
		STA $4301 ; dma0 source
		LDA #$01 ; channel 0
		STA $420B ; dma enable
		
		; save some hardware registers to $717FF7 - $717FFF
		; TODO this is theoretically correct; however, you can't read from any of these
		; registers other than $2106 so I have to find a clever way to restore these...
		LDA $2106 ; mosaic
		STA $717FF7
		LDA $212E ; through main
		STA $717FF8
		LDA $212F ; through sub
		STA $717FF9
		LDX #$0005
	.loop_screens:
		LDA $2107,X ; BG screen size, tilemap address, character address
		STA $717FFA,X
		DEX
		BPL .loop_screens
		
		LDA #$81
		STA $4200 ; nmi enable
		LDA #$0F
		STA $2100 ; exit force blank
		PLP
		RTS

; this code is run when the player presses L + select to load a save state
activate_load_state:
		LDA !use_poverty_save_states
		BEQ .complete
		JSR go_poverty_load_state
		BRA .done
	.complete:
		JSR go_complete_load_state
	.done:
		RTL
		
go_poverty_load_state:
		PHP
		LDA #$80
		STA $2100 ; force blank
		STZ $4200 ; nmi disable
		
		REP #$10
		
		; load wram $7F9C7B-$7FBC7A to wram $0000-$1FFF 
		LDX #$1FFF
	.loop_mirror:
		LDA $7F9C7B,X
		STA $7E0000,X
		DEX
		BPL .loop_mirror
		
		; load $707DA0-$707DFF to wram $C680-$C6DF
		LDX #$005F
	.loop_boss:
		LDA $707DA0,X
		STA $7EC680,X
		DEX
		BPL .loop_boss
		
		; load $707BA0-$707D9F to wram $7F9A7B-$7F9C7A
		LDX #$01FF
	.loop_wiggler:
		LDA $707BA0,X
		STA $7F9A7B,X
		DEX
		BPL .loop_wiggler
		
		; load $700BA0-$70439F to wram $C800-$FFFF
		LDX #$37FF
	.loop_tilemap_low:
		LDA $700BA0,X
		STA $7EC800,X
		DEX
		BPL .loop_tilemap_low
		
		; load $7043A0-$707B9F to wram $7FC800-$7FFFFF
		LDX #$37FF
	.loop_tilemap_high:
		LDA $7043A0,X
		STA $7FC800,X
		DEX
		BPL .loop_tilemap_high
		
		; load $707E00-$707FFF to cgram w$00-w$FF
		LDX #$0000
		STX $2121 ; cgram address
		LDX #$7E00
		STX $4302 ; dma0 destination address
		LDA #$70
		STA $4304 ; dma0 destination bank
		LDX #$0200
		STX $4305 ; dma0 length
		STZ $4300 ; dma0 parameters
		LDA #$22 ; $2122 cgram data write
		STA $4301 ; dma0 source
		LDA #$01 ; channel 0
		STA $420B ; dma enable
		
		; load wram $7F0000-$7F5FFF to vram w$1000-w$3FFF
		LDA #$80
		STA $2115 ; vram increment
		LDX #$1000
		STX $2116 ; vram address
		LDX #$0000
		STX $4302 ; dma0 destination address
		LDA #$7F
		STA $4304 ; dma0 destination bank
		LDX #$6000
		STX $4305 ; dma0 length
		LDA #$01 ; 2-byte, low-high
		STA $4300 ; dma0 parameters
		LDA #$18 ; $2118 vram data write
		STA $4301 ; dma0 source
		LDA #$01 ; channel 0
		STA $420B ; dma enable
		
		; load wram $7F6000-$7F7FFF to vram w$7000-w$7FFF
		LDA #$80
		STA $2115 ; vram increment
		LDX #$7000
		STX $2116 ; vram address
		LDX #$6000
		STX $4302 ; dma0 destination address
		LDA #$7F
		STA $4304 ; dma0 destination bank
		LDX #$2000
		STX $4305 ; dma0 length
		LDA #$01 ; 2-byte, low-high
		STA $4300 ; dma0 parameters
		LDA #$18 ; $2118 vram data write
		STA $4301 ; dma0 source
		LDA #$01 ; channel 0
		STA $420B ; dma enable
		
		; load some hardware registers from $7FC7F7 - $7FC7FF
		LDA $7FC7F7
		STA $2106 ; mosaic
;		LDA $7FC7F8
;		STA $212E ; through main
;		LDA $7FC7F9
;		STA $212F ; through sub
;		LDX #$0005
;	.loop_screens:
;		LDA $7FC7FA,X
;		STA $2107,X ; BG screen size, tilemap address, character address
;		DEX
;		BPL .loop_screens
		
		LDA #$81
		STA $4200 ; nmi enable
		LDA #$0F
		STA $2100 ; exit force blank
		PLP
		RTS
		
go_complete_load_state:
		PHP
		LDA #$80
		STA $2100 ; force blank
		STZ $4200 ; nmi disable
		
		REP #$10
		
		; load $701000-$702FFF to wram $0000-$1FFF
		LDX #$1FFF
	.loop_mirror:
		LDA $701000,X
		STA $7E0000,X
		DEX
		BPL .loop_mirror
		
		; load $703000-$70305F to wram $C680-$C6DF
		LDX #$005F
	.loop_boss:
		LDA $703000,X
		STA $7EC680,X
		DEX
		BPL .loop_boss
		
		; load $703060-$70325F to wram $7F9A7B-$7F9C7A
		LDX #$01FF
	.loop_wiggler:
		LDA $703060,X
		STA $7F9A7B,X
		DEX
		BPL .loop_wiggler
		
		; load $703260-$706A5F to save wram $C800-$FFFF
		LDX #$37FF
	.loop_tilemap_low:
		LDA $703260,X
		STA $7EC800,X
		DEX
		BPL .loop_tilemap_low
		
		; load $710000-$7137FF to wram $7FC800-$7FFFFF
		LDX #$37FF
	.loop_tilemap_high:
		LDA $710000,X
		STA $7FC800,X
		DEX
		BPL .loop_tilemap_high
		
		; load $713800-$713AFF to cgram w$00-w$FF
		LDX #$0000
		STX $2121 ; cgram address
		LDX #$3800
		STX $4302 ; dma0 destination address
		LDA #$71
		STA $4304 ; dma0 destination bank
		LDX #$0200
		STX $4305 ; dma0 length
		STZ $4300 ; dma0 parameters
		LDA #$22 ; $2122 cgram data write
		STA $4301 ; dma0 source
		LDA #$01 ; channel 0
		STA $420B ; dma enable
		
		; load $720000-$727FFF to vram w$0000-w$3FFF
		LDA #$80
		STA $2115 ; vram increment
		LDX #$0000
		STX $2116 ; vram address
		LDX #$0000
		STX $4302 ; dma0 destination address
		LDA #$72
		STA $4304 ; dma0 destination bank
		LDX #$8000
		STX $4305 ; dma0 length
		LDA #$01 ; 2-byte, low-high
		STA $4300 ; dma0 parameters
		LDA #$18 ; $2118 vram data write
		STA $4301 ; dma0 source
		LDA #$01 ; channel 0
		STA $420B ; dma enable
		
		; load $730000-$737FFF to vram w$4000-w$7FFF
		LDA #$80
		STA $2115 ; vram increment
		LDX #$4000
		STX $2116 ; vram address
		LDX #$0000
		STX $4302 ; dma0 destination address
		LDA #$73
		STA $4304 ; dma0 destination bank
		LDX #$8000
		STX $4305 ; dma0 length
		LDA #$01 ; 2-byte, low-high
		STA $4300 ; dma0 parameters
		LDA #$18 ; $2118 vram data write
		STA $4301 ; dma0 source
		LDA #$01 ; channel 0
		STA $420B ; dma enable
		
		; load some hardware registers from $717FF7 - $717FFF
		LDA $717FF7
		STA $2106 ; mosaic
;		LDA $717FF8
;		STA $212E ; through main
;		LDA $717FF9
;		STA $212F ; through sub
;		LDX #$0005
;	.loop_screens:
;		LDA $717FFA,X
;		STA $2107,X ; BG screen size, tilemap address, character address
;		DEX
;		BPL .loop_screens
		
		LDA #$81
		STA $4200 ; nmi enable
		LDA #$0F
		STA $2100 ; exit force blank
		PLP
		RTS