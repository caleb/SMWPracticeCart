; empty/unreachable bytes overwritten:
; $00B091 - 7 / 15 bytes

; 1FE2 cape interaction table
ORG $00FCC2
		STA !new_cape_interaction,X
ORG $01810E
		LDA !new_cape_interaction,X
ORG $018113
		DEC !new_cape_interaction,X
ORG $0191FB
		ORA !new_cape_interaction,X
ORG $0195D8
		STA !new_cape_interaction,X
ORG $0199CF
		STA !new_cape_interaction,X
ORG $01D2CA
		LDA !new_cape_interaction,X
ORG $01D2D1
		STA !new_cape_interaction,X
ORG $01EDA0
		STA !new_cape_interaction,X
ORG $0293C9
		ORA !new_cape_interaction,X
ORG $02A9D4
		STA !new_cape_interaction,X
ORG $02C4F3
		LDA !new_cape_interaction,X
ORG $02C4FF
		STA !new_cape_interaction,X
ORG $02DDC1
		STA !new_cape_interaction,X
ORG $02DEBC
		LDA !new_cape_interaction,X
ORG $039569
		LDA !new_cape_interaction,X
ORG $0395C3
		STA !new_cape_interaction,X
ORG $039688
		LDA !new_cape_interaction,X
ORG $07F74B
		STZ !new_cape_interaction,X
	
; clear unused table
ORG $07F782
		NOP #3
	
; clear moons, dragon coins, 1ups tables
ORG $00F2B8
		NOP #6
ORG $00F322
		NOP #6
ORG $00F351
		NOP #6
ORG $0DA59C
		LDA #$00
		NOP
ORG $0DA5A7
		LDA #$00
		NOP
ORG $0DB2D7
		LDA #$00
		NOP

; clear save file buffer table
ORG $009BC9
		RTL
ORG $009D18
		NOP #3
ORG $00A19A
		NOP #6
ORG $01E765
		NOP #3
ORG $049046
		NOP #3

; change special effects flag to use the new one we made instead of checking if Funky is beaten
ORG $00AA73
		LDA !status_special
		db $F0 ; BEQ
ORG $00AD2A
		JSR load_special_16
		db $F0 ; BEQ
ORG $019825
		LDA !status_special
		db $D0 ; BNE
ORG $01B9CC
		LDA !status_special
		db $F0 ; BEQ
ORG $02A985
		LDY !status_special
		db $F0 ; BEQ
ORG $0CAE0E
		LDA !status_special
		db $F0 ; BEQ
	
ORG $00B091
load_special_16:
		LDA !status_special
		AND #$00FF
		RTS

; clear unused exit table
ORG $0DA533
		NOP #3

; move layer 3 border data from $04A400 to $04A200
; insert new overworld tilemap, which is slightly larger than the original
ORG $04A200
overworld_layer3_stripe:
		incbin "bin/overworld_layer3_stripe.bin"
overworld_layer2_tiles:
		incbin "bin/overworld_layer2_tiles_compressed.bin"
overworld_layer2_properties:
		incbin "bin/overworld_layer2_properties_compressed.bin"
		
ORG $0084D6
		dl overworld_layer3_stripe
ORG $04DC72
		dw overworld_layer2_tiles
ORG $04DC8D
		dw overworld_layer2_properties
		
ORG $05D000
		incbin "bin/overworld_layer1_characters.bin"
ORG $0CF7DF
		incbin "bin/overworld_layer1_tiles.bin"

; update music upload routine
ORG $00810E
		LDX #$00
		JSL set_music_bank
		JMP $811D
ORG $008148
		LDX #$01
		JSL set_music_bank
		JMP $8157
ORG $008159
		LDX #$02
		JSL set_music_bank
		JMP $8168