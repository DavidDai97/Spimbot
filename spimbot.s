# syscall constants
PRINT_STRING = 4
PRINT_CHAR   = 11
PRINT_INT    = 1

# debug constants
PRINT_INT_ADDR   = 0xffff0080
PRINT_FLOAT_ADDR = 0xffff0084
PRINT_HEX_ADDR   = 0xffff0088

# spimbot constants
VELOCITY       = 0xffff0010
ANGLE          = 0xffff0014
ANGLE_CONTROL  = 0xffff0018
BOT_X          = 0xffff0020
BOT_Y          = 0xffff0024
OTHER_BOT_X    = 0xffff00a0
OTHER_BOT_Y    = 0xffff00a4
TIMER          = 0xffff001c
SCORES_REQUEST = 0xffff1018

TILE_SCAN       = 0xffff0024
SEED_TILE       = 0xffff0054
WATER_TILE      = 0xffff002c
MAX_GROWTH_TILE = 0xffff0030
HARVEST_TILE    = 0xffff0020
BURN_TILE       = 0xffff0058
GET_FIRE_LOC    = 0xffff0028
PUT_OUT_FIRE    = 0xffff0040

GET_NUM_WATER_DROPS   = 0xffff0044
GET_NUM_SEEDS         = 0xffff0048
GET_NUM_FIRE_STARTERS = 0xffff004c
SET_RESOURCE_TYPE     = 0xffff00dc
REQUEST_PUZZLE        = 0xffff00d0
SUBMIT_SOLUTION       = 0xffff00d4

# interrupt constants
BONK_MASK               = 0x1000
BONK_ACK                = 0xffff0060
TIMER_MASK              = 0x8000
TIMER_ACK               = 0xffff006c
ON_FIRE_MASK            = 0x400
ON_FIRE_ACK             = 0xffff0050
MAX_GROWTH_ACK          = 0xffff005c
MAX_GROWTH_INT_MASK     = 0x2000
REQUEST_PUZZLE_ACK      = 0xffff00d8
REQUEST_PUZZLE_INT_MASK = 0x800

.align 2
tile_data: .space 1600
.data
# put your data things here


.text
move_to_x_y:
	sub	$sp, $sp, 24
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$s2, 12($sp)
	sw	$s3, 16($sp)
	sw	$s4, 20($sp)
	lw	$s1, BOT_X
	lw	$s2, BOT_Y
	move	$s3, $a0
	move	$s4, $a1
	bge	$s3, 300, end_move_to_x_y
	bge	$s4, 300, end_move_to_x_y
angle_X:
	ble	$s3, $s1, turn_X
	li	$s0, 0
	sw	$s0, ANGLE
	li	$s0, 1
	sw	$s0, ANGLE_CONTROL
	j	move_X
turn_X:
	li	$s0, 180
	sw	$s0, ANGLE
	li	$s0, 1
	sw	$s0, ANGLE_CONTROL
move_X:
	beq	$s1, $s3, angle_Y
	li	$s0, 10
	sw	$s0, VELOCITY
	lw	$s1, BOT_X
	j	move_X
angle_Y:
	ble	$s4, $s2, turn_Y
	li	$s0, 90
	sw	$s0, ANGLE
	li	$s0, 1
	sw	$s0, ANGLE_CONTROL
	j	move_Y
turn_Y:
	li	$s0, 270
	sw	$s0, ANGLE
	li	$s0, 1
	sw	$s0, ANGLE_CONTROL
move_Y:
	beq	$s2, $s4, end_move_to_x_y
	li	$s0, 10
	sw	$s0, VELOCITY
	lw	$s2, BOT_Y
	j	move_Y
end_move_to_x_y:
	li	$s0, 0
	sw	$s0, VELOCITY
	lw	$ra, 0($sp)
	lw	$s0, 4($sp)
	lw	$s1, 8($sp)
	lw	$s2, 12($sp)
	lw	$s3, 16($sp)
	lw	$s4, 20($sp)
	add	$sp, $sp, 24
	jr	$ra
#######################################FUNCTION########move_to_x_y###############
scan_plant:
	la	$t0, tile_data			
	sw	$t0, TILE_SCAN
	move	$v0, $t0
	jr	$ra
#######################################FUNCTION########scan_plant################
plant_seed:
	sub	$sp, $sp, 16
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$s2, 12($sp)
	lw	$s1, BOT_X
	lw	$s2, BOT_Y
	jal	scan_plant
	li	$s0, 30
	div	$t0, $s1, $s0
	div	$t1, $s2, $s0
	mul	$t1, $t1, 10
	add	$t0, $t0, $t1
	sll	$t0, $t0, 4
	add	$t0, $t0, $v0
	lw	$t0, 0($t0)
	bne	$t0, $zero, error
	sw	$0, SEED_TILE
	li	$v0, 1
	j	end_plant_seed
error:
	li	$v0, 0
end_plant_seed:
	lw	$ra, 0($sp)
	lw	$s0, 4($sp)
	lw	$s1, 8($sp)
	lw	$s2, 12($sp)
	add	$sp, $sp, 16
	jr	$ra
#######################################FUNCTION########plant_seed################
seed_tile:
	sub	$sp, $sp, 4
	sw	$ra, 0($sp)
	jal	move_to_x_y
	jal	plant_seed
	bne	$v0, 1, seed_next
	j	end_seed_tile
seed_next:
	bge	$a0, 270, seed_next_y
seed_next_x:
	add	$a0, $a0, 30
	jal	seed_tile
	j	end_seed_tile
seed_next_y:
	add	$a1, $a1, 30
	jal	seed_tile
end_seed_tile:
	lw	$ra, 0($sp)
	add	$sp, $sp, 4
	jr	$ra
#######################################FUNCTION########seed_tile######
###################################################################################
main:
	# put your code here :)
	li	$t4, TIMER_MASK		# 	timer interrupt enable bit
	or	$t4, $t4, BONK_MASK	# 	bonk interrupt bit
	or	$t4, $t4, ON_FIRE_MASK	# 	on_fire interrupt bit
	or	$t4, $t4, 1		# 	global interrupt enable
	mtc0	$t4, $12		# 	set interrupt mask (Status register)
	lw	$s1, BOT_X
	lw	$s2, BOT_Y
try_seed:
	li	$a0, 15
	li	$a1, 15
	jal	seed_tile
	li	$a0, 15
	li	$a1, 45
	jal	seed_tile
infinite:
	j	try_seed
	# request on_fire interrupt
	

.kdata				# interrupt handler data (separated just for readability)
chunkIH:	.space 28	# space for two registers
non_intrpt_str:	.asciiz "Non-interrupt exception\n"
unhandled_str:	.asciiz "Unhandled interrupt type\n"


.ktext 0x80000180
interrupt_handler:
.set noat
	move	$k1, $at		# Save $at                               
.set at
	la	$k0, chunkIH
	sw	$a0, 0($k0)		# Get some free registers                  
	sw	$a1, 4($k0)		# by storing them to a global variable     
	sw	$t0, 8($k0)
	sw	$t1, 12($k0)
	sw	$t2, 16($k0)
	sw	$t3, 20($k0)
	sw	$s0, 24($k0)

	mfc0	$k0, $13		# Get Cause register                       
	srl	$a0, $k0, 2                
	and	$a0, $a0, 0xf		# ExcCode field                            
	bne	$a0, 0, non_intrpt         

interrupt_dispatch:			# Interrupt:                             
	mfc0	$k0, $13		# Get Cause register, again                 
	beq	$k0, 0, done		# handled all outstanding interrupts     

	and	$a0, $k0, BONK_MASK	# is there a bonk interrupt?                
	bne	$a0, 0, bonk_interrupt   

	and	$a0, $k0, TIMER_MASK	# is there a timer interrupt?
	bne	$a0, 0, timer_interrupt
	
	and	$a0, $k0, ON_FIRE_MASK
	bne	$a0, 0, on_fire_interrupt

	# add dispatch for other interrupt types here.

	li	$v0, PRINT_STRING	# Unhandled interrupt types
	la	$a0, unhandled_str
	syscall 
	j	done

bonk_interrupt:
	sw	$a1, BONK_ACK		# acknowledge interrupt
	li	$s0, 90			# ???
	sw	$s0, ANGLE		# ???
	li	$s0, 0
	sw	$s0, ANGLE_CONTROL

	j	interrupt_dispatch	# see if other interrupts are waiting

timer_interrupt:
	sw	$a1, TIMER_ACK		# acknowledge interrupt

	li	$t0, 90			# ???
	sw	$t0, ANGLE		# ???
	sw	$zero, ANGLE_CONTROL	# ???

	lw	$v0, TIMER		# current time
	add	$v0, $v0, 50000  
	sw	$v0, TIMER		# request timer in 50000 cycles

	j	interrupt_dispatch	# see if other interrupts are waiting

on_fire_interrupt:
	sw	$a1, ON_FIRE_ACK	# acknowledge interrupt
	lw	$t0, GET_FIRE_LOC
	and	$t1, $t0, 0xffff	#	$t1 = yCoord
	srl	$t0, $t0, 16		#	$t0 = xCoord
	mul	$t0, $t0, 30
	mul	$t1, $t1, 30
	add	$t0, $t0, 15
	add	$t1, $t1, 15
	lw	$t2, BOT_X		#	$t2 = bot_x
	lw	$t3, BOT_Y		#	$t3 = bot_y
	sub	$t2, $t2, $t0
	sub	$t3, $t3, $t1
find_x:
	blt	$t2, 0, turn_east
	bgt	$t2, 0, turn_west
find_y:
	blt	$t3, 0, turn_south
	bgt	$t3, 0, turn_north
	j	put_fire
turn_west:
	li	$s0, 180		# ???
	sw	$s0, ANGLE		# ???
	li	$s0, 1
	sw	$s0, ANGLE_CONTROL
	j	go_x
turn_east:
	li	$s0, 0			# ???
	sw	$s0, ANGLE		# ???
	li	$s0, 1
	sw	$s0, ANGLE_CONTROL
	j	go_x
turn_north:
	li	$s0, 270		# ???
	sw	$s0, ANGLE		# ???
	li	$s0, 1
	sw	$s0, ANGLE_CONTROL
	j	go_y
turn_south:
	li	$s0, 90			# ???
	sw	$s0, ANGLE		# ???
	li	$s0, 1
	sw	$s0, ANGLE_CONTROL
	j	go_y
go_x:
	li	$s0, 10
	sw	$s0, VELOCITY		# drive
	lw	$t2, BOT_X
	beq	$t0, $t2, find_y
	j	go_x
go_y:
	li	$s0, 10
	sw	$s0, VELOCITY		# drive
	lw	$t3, BOT_Y
	beq	$t1, $t3, put_fire
	j	go_y
put_fire:
	sw	$zero, PUT_OUT_FIRE
	j	interrupt_dispatch
##############################################################################
non_intrpt:				# was some non-interrupt
	li	$v0, PRINT_STRING
	la	$a0, non_intrpt_str
	syscall				# print out an error message
	# fall through to done
done:
	la	$k0, chunkIH
	lw	$a0, 0($k0)		# Restore saved registers
	lw	$a1, 4($k0)
	lw	$t0, 8($k0)
	lw	$t1, 12($k0)
	lw	$t2, 16($k0)
	lw	$t3, 20($k0)
	lw	$s0, 24($k0)
.set noat
	move	$at, $k1		# Restore $at
.set at 
	eret
