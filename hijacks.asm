; empty/unreachable bytes overwritten:
; $00A249 - 16 / 18 bytes
; $00F9F5 - 35 / 36 bytes
; $00C578 - 10 / 13 bytes
; $00CC86 - 53 / 53 bytes
; $009510 - 18 / 25 bytes

; hijacks

; run on overworld load
;$00A087
; run every frame on overworld
;$00A1BE
; run every frame in level
;$00A1DA
; run on level load before fade in
;$0096D5
; run on level load as soon as player gets control
;$00A1DA (first frame)
; run on level complete (switch, key, goal, orb, boss, bowser)
;$------
; run on vblank
;$008176
; run on every frame
;$008072

!level_loaded = $0F3A
!level_finished = $1DEF

; run on vblank
ORG $0081AA
		JSR vblank_hijack
		NOP
		NOP
		
ORG $009510
vblank_hijack:
		LDA #$80
		STA $2100
		JSL $168000 ; vblank.asm
		RTS
every_frame_hijack:
		JSR $9322
		JSL $178000 ; every_frame.asm
		RTS

; run on every frame
ORG $008072
		JSR every_frame_hijack

; run on overworld load
ORG $00A087
		JSR overworld_load_hijack
	
ORG $00A249
overworld_load_hijack:
		JSL $118000 ; overworld_load.asm
		JSR $937D
		RTS
overworld_hijack:
		JSL $148000 ; overworld_tick.asm
		JSR $9A74
		RTS
		
; run every frame on overworld
ORG $00A1BE
		JSR overworld_hijack
		
; run every frame in level
ORG $00A1DA
		JSR level_hijack
		
ORG $00F9F5
level_hijack:
		JSL $158000 ; level_tick.asm
		LDA !level_loaded
		BEQ .already_loaded
		STZ !level_loaded
		JSL $108000 ; level_mario_appear.asm
	.already_loaded:
		JSL test_last_frame
		LDA $1426
		RTS
level_load_hijack:
		JSL $128000 ; level_load.asm
		STZ $4200
		INC !level_loaded
		RTS
		
; run on level load before fade in
ORG $0096D5
		JSR level_load_hijack
		
; test if level completed this frame
; X = 0 for normal exit, 1 for secret exit
ORG $00CC86
test_last_frame:
		LDA !level_finished
		BNE .exit
		LDX $141C
		LDA $9E
		CMP #$C5
		BNE .not_big_boo
		LDX #$01
	.not_big_boo:
		LDA $1493
		BNE .trigger
		LDA $190D
		BNE .trigger
		LDX #$01
		LDA $1434
		BNE .trigger
		LDA $1B95
		BEQ .exit
		LDA $0DD5
		BEQ .exit
		LDX #$00
		BRA .trigger
	.exit:
		RTL
		
	.trigger:
		JSL $138000 ; level_finish.asm
		RTL
		
; hijack for overworld menu game modes
ORG $009363
		dw overworld_menu_load_gm
ORG $009367
		dw overworld_menu_gm
		
; game modes for overworld menu
ORG $00C578
overworld_menu_load_gm:
		JSL $188000 ; overworld_menu.asm
		RTS
overworld_menu_gm:
		JSL $198000 ; overworld_menu.asm
		RTS
		