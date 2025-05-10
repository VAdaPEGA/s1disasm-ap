; ---------------------------------------------------------------------------
; Object 2E - contents of monitors
; ---------------------------------------------------------------------------

PowerUp:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Pow_Index(pc,d0.w),d1
		jsr	Pow_Index(pc,d1.w)
		bra.w	DisplaySprite
; ===========================================================================
Pow_Index:	dc.w Pow_Main-Pow_Index
		dc.w Pow_Move-Pow_Index
		dc.w Pow_Delete-Pow_Index
; ===========================================================================

Pow_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.w	#make_art_tile(ArtTile_Monitor,0,0),obGfx(a0)
		move.b	#$24,obRender(a0)
		move.b	#3,obPriority(a0)
		move.b	#8,obActWid(a0)
		move.w	#-$300,obVelY(a0)
		move.b	#8,obFrame(a0)	; use correct frame
		; Ugly hack to save a bunch of space, this is the address of the ring monitor spriteimage
		move.l	#(Map_Monitor_internal.rings+1),obMap(a0)

Pow_Move:	; Routine 2
		tst.w	obVelY(a0)	; is object moving?
		bpl.w	Pow_Checks	; if not, branch
		bsr.w	SpeedToPos
		addi.w	#$18,obVelY(a0)	; reduce object	speed
		rts	
; ===========================================================================

Pow_Checks:
		addq.b	#2,obRoutine(a0)
		move.w	#29,obTimeFrame(a0) ; display icon for half a second

Pow_ChkEggman:
		bra Pow_ChkRings
; ===========================================================================

Pow_ChkShoes:
		move.b	#1,(v_shoes).w	; speed up the BG music
		move.w	#$4B0,(v_player+$34).w	; time limit for the power-up
		move.w	#$C00,(v_sonspeedmax).w ; change Sonic's top speed
		move.w	#$18,(v_sonspeedacc).w	; change Sonic's acceleration
		move.w	#$80,(v_sonspeeddec).w	; change Sonic's deceleration
		move.w	#bgm_Scary,d0	; Scary music
		jmp	(PlaySound).l		; Speed	up the music
; ===========================================================================

Pow_ChkShield:
		move.b	#1,(v_shield).w	; give Sonic a shield
		move.b	#id_ShieldItem,(v_shieldobj).w ; load shield object ($38)
		move.w	#sfx_Shield,d0
		jmp	(PlaySound).l	; play shield sound
; ===========================================================================

Pow_ChkInvinc:
		move.b	#1,(v_invinc).w	; make Sonic invincible
		move.w	#$4B0,(v_player+$32).w ; time limit for the power-up
		move.b	#id_ShieldItem,(v_starsobj1).w ; load stars object ($3801)
		move.b	#1,(v_starsobj1+obAnim).w
		move.b	#id_ShieldItem,(v_starsobj2).w ; load stars object ($3802)
		move.b	#2,(v_starsobj2+obAnim).w
		move.b	#id_ShieldItem,(v_starsobj3).w ; load stars object ($3803)
		move.b	#3,(v_starsobj3+obAnim).w
		move.b	#id_ShieldItem,(v_starsobj4).w ; load stars object ($3804)
		move.b	#4,(v_starsobj4+obAnim).w
		tst.b	(f_lockscreen).w ; is boss mode on?
		bne.s	Pow_NoMusic	; if yes, branch
		if Revision<>0
			cmpi.w	#$C,(v_air).w
			bls.s	Pow_NoMusic
		endif
		move.w	#bgm_Invincible,d0
		jmp	(PlaySound).l ; play invincibility music
; ===========================================================================

Pow_NoMusic:
		rts	
; ===========================================================================

Pow_ChkRings:
		addi.w	#10,(v_rings).w	; add 10 rings to the number of rings you have
		ori.b	#1,(f_ringcount).w ; update the ring counter
		move.w	#sfx_Ring,d0
		jmp	(PlaySound).l	; play ring sound
; ===========================================================================

Pow_Delete:	; Routine 4
		subq.w	#1,obTimeFrame(a0)
		bmi.w	DeleteObject	; delete after half a second
		rts	

; All but a1 registers are fair game.
KAI_PowerUp_Checks:
		tst.b	(v_gamemode).w	; is title card still playing?
		bmi.s	.done		; if so, branch
		cmpi.b	#id_Death,(v_player+obAnim).w
		beq.s	.done
		movem.w SR_Invinc_in,d0-d7
		tst.b	(v_invinc).w
		bne.s	.alreadyShielded
		cmp.b	d0,d1 ; compare used-in, looking for negative
		blo.s	.doInvinc
		; Do we need to kill Sonic?
		cmp.b	d6,d7 ; compare used-in, looking for negative
		blo.s	.doDeathL
		; How about a shield?
		tst.b	(v_shield).w
		bne.s	.alreadyShielded
		cmp.b	d2,d3 ; compare used-in, looking for negative
		blo.s	.doShield
.alreadyShielded:
		tst.b	(v_shoes).w
		bne.s	.done
		cmp.b	d4,d5 ; compare used-in, looking for negative
		blo.s	.doShoes
.done:
		rts
.doInvinc:
		addi.w	#1,(SR_Invinc_out)
		bra	Pow_ChkInvinc
.doDeathL:
		move.w	d6,(SR_DeathL_out)
		lea	(v_player),a0	
		jmp	(KillSonicNoCount).l
.doShield:
		addi.w	#1,(SR_Shield_out)
		bra	Pow_ChkShield
.doShoes:
		addi.w	#1,(SR_SpeedS_out)
		bra	Pow_ChkShoes