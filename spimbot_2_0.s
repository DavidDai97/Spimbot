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

.data
# put your data things here
.align 2
tile_data: .space 1600
puzzle_data: .space 4096
solution_data: .space 328

.text
############################FUNCTION FOR PUZZLE####################################
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
start_move:
	bge	$s3, 300, end_move_to_x_y
	bge	$s4, 300, end_move_to_x_y
	bne	$s3, $s1, angle_X
	bne	$s4, $s2, angle_Y
	j	end_move_to_x_y
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
	#beq	$s1, $s3, angle_Y
	li	$s0, 10
	sw	$s0, VELOCITY
	lw	$s1, BOT_X
	j	start_move
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
	#beq	$s2, $s4, end_move_to_x_y
	li	$s0, 10
	sw	$s0, VELOCITY
	lw	$s2, BOT_Y
	j	start_move
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
#####################FUNCTION########move_to_x_y#############################
scan_plant:
	la	$t0, tile_data			
	sw	$t0, TILE_SCAN
	move	$v0, $t0
	jr	$ra
#####################FUNCTION########scan_plant##############################
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
	jal	request_source
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
#####################FUNCTION########plant_seed##############################
seed_tile:
	sub	$sp, $sp, 4
	sw	$ra, 0($sp)
	#jal	request_source
go_seed:
	jal	move_to_x_y
	jal	plant_seed
seed_unsuccess:
	#bne	$v0, 1, seed_next_x
	j	end_seed_tile
seed_next_x:
	bge	$a0, 270, seed_next_y
	add	$a0, $a0, 30
	jal	move_to_x_y
	jal	plant_seed
	bne	$v0, 1, seed_next_x
	j	end_seed_tile
	#j	end_seed_tile
seed_next_y:
	bge	$a1, 270, seed_last_x
	add	$a1, $a1, 30
	jal	move_to_x_y
	jal	plant_seed
	bne	$v0, 1, seed_next_y
	j	end_seed_tile
seed_last_x:
	ble	$a0, 30, seed_last_y
	jal	move_to_x_y
	jal	plant_seed
	bne	$v0, 1, seed_last_x
	j	end_seed_tile
seed_last_y:
	ble	$a1, 30, seed_next_x
	jal	move_to_x_y
	jal	plant_seed
	bne	$v0, 1, seed_last_y
	j	end_seed_tile
end_seed_tile:
	#jal	request_source
	lw	$ra, 0($sp)
	add	$sp, $sp, 4
	jr	$ra
#####################FUNCTION########seed_tile###############################
request_puzzle:
	move	$t0, $a0
	sw	$t0, SET_RESOURCE_TYPE
	
	la	$t0, puzzle_data
	sw	$t0, REQUEST_PUZZLE
end_request_puzzle:
	jr	$ra
#####################FUNCTION########request_puzzle##########################
request_source:
	sub	$sp, $sp, 8
	sw	$ra, 0($sp)
	sw	$a0, 4($sp)
	la	$t0, solution_data
	la	$t1, puzzle_data
	lw	$t1, 0($t1)
	lw	$t0, 0($t0)
	bne	$t0, 0, go
	bne	$t1, 0, end_request_source
go:
	lw	$t0, GET_NUM_SEEDS
	lw	$t1, GET_NUM_WATER_DROPS
	lw	$t2, GET_NUM_FIRE_STARTERS
	blt	$t0, 7, seed
	blt	$t1, 50, water
	blt	$t2, 1, fire_starter
	j	end_request_source
seed:
	li	$a0, 1
	j	request
water:
	li	$a0, 0
	j	request
fire_starter:
	li	$a0, 2
request:
	jal	request_puzzle
end_request_source:
	lw	$ra, 0($sp)
	lw	$a0, 4($sp)
	add	$sp, $sp, 8
	jr	$ra

#####################FUNCTION########requset_source###########################
harvest:
	sub	$sp, $sp, 12
	sw	$ra, 0($sp)
	sw	$s3, 4($sp)
	sw	$s4, 8($sp)
	#jal	request_source
scan:
	jal	scan_plant
	li	$t1, 33				#	i = 0;
	li	$t2, 66				#	length = 100;
find_plant_for:
	bge	$t1, $t2, end_harvest
	sll	$t3, $t1, 4
	add	$t4, $t0, $t3
	lw	$t4, 8($t4)
	bge	$t4, 400, has_plant
	add	$t1, $t1, 1
	j	find_plant_for
has_plant:
	div	$s4, $t1, 10
	rem	$s3, $t1, 10
	mul	$s3, $s3, 30
	mul	$s4, $s4, 30
	add	$s3, $s3, 15
	add	$s4, $s4, 15
	move	$a0, $s3
	move	$a1, $s4
	jal	move_to_x_y
	sw	$zero, HARVEST_TILE
	jal	seed_tile
	j	scan
end_harvest:
	lw	$ra, 0($sp)
	lw	$s3, 4($sp)
	lw	$s4, 8($sp)
	add	$sp, $sp, 12
	jr	$ra
##################################################################################
water_plant:
	li	$t0, 10
	sw	$t0, WATER_TILE
	jr	$ra
################################Water#############################################
###################################################################################
main:
	# put your code here :)
	li	$t4, TIMER_MASK		# 	timer interrupt enable bit
	or	$t4, $t4, BONK_MASK	# 	bonk interrupt bit
	or	$t4, $t4, ON_FIRE_MASK	# 	on_fire interrupt bit
	or	$t4, $t4, REQUEST_PUZZLE_INT_MASK
	or	$t4, $t4, MAX_GROWTH_INT_MASK
	or	$t4, $t4, 1		# 	global interrupt enable
	mtc0	$t4, $12		# 	set interrupt mask (Status register)
start_main:
	jal	request_source
	li	$s1, 105
	li	$s0, 105
outter_loop:
	bge	$s1, 225, end_seeding_out
	
	beq	$s0, 195, inner_loop_abnormal
inner_loop_normal:
	bge	$s0, 225, end_seeding_in
	#jal	request_source
	move	$a0, $s0
	move	$a1, $s1
	jal	move_to_x_y
	jal	seed_tile
	#move	$s1, $v0
	#move	$s0, $v1
	add	$s0, $s0, 30
	j	inner_loop_normal
inner_loop_abnormal:
	ble	$s0, 95, end_seeding_in
	#jal	request_source
	move	$a0, $s0
	move	$a1, $s1
	jal	move_to_x_y
	jal	seed_tile
	#move	$s0, $v0
	#move	$s1, $v1
	sub	$s0, $s0, 30
	j	inner_loop_abnormal
end_seeding_in:
	beq	$s0, 225, subtract
	add	$s0, $s0, 30
	j	temp
subtract:
	sub	$s0, $s0, 30
temp:
	add	$s1, $s1, 30
	j	outter_loop
end_seeding_out:
	li	$a0, 135
	li	$a1, 135
	jal	move_to_x_y
infinite:
	li	$a0, 165
	jal	move_to_x_y
	li	$a1, 165
	jal	move_to_x_y
	jal	water_plant
	li	$a0, 135
	jal	move_to_x_y
	li	$a1, 135
	jal	move_to_x_y
	jal	water_plant
	jal	request_source
	jal	harvest
	j	infinite
	# request on_fire interrupt
	

.kdata				# interrupt handler data (separated just for readability)
chunkIH:	.space 64	# space for two registers
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
	sw	$a2, 28($k0)
	sw	$t4, 32($k0)
	sw	$t5, 36($k0)
	sw	$t6, 40($k0)
	sw	$s1, 44($k0)
	sw	$s2, 48($k0)
	sw	$s3, 52($k0)
	sw	$s4, 56($k0)
	sw	$v1, 60($k0)
	

	mfc0	$k0, $13		# Get Cause register                       
	srl	$v1, $k0, 2                
	and	$v1, $v1, 0xf		# ExcCode field                            
	bne	$v1, 0, non_intrpt         

interrupt_dispatch:			# Interrupt:                             
	mfc0	$k0, $13		# Get Cause register, again                 
	beq	$k0, 0, done		# handled all outstanding interrupts     

	and	$v1, $k0, BONK_MASK	# is there a bonk interrupt?                
	bne	$v1, 0, bonk_interrupt   

	and	$v1, $k0, TIMER_MASK	# is there a timer interrupt?
	bne	$v1, 0, timer_interrupt
	
	and	$v1, $k0, ON_FIRE_MASK
	bne	$v1, 0, on_fire_interrupt
	
	and	$v1, $k0, REQUEST_PUZZLE_INT_MASK
	bne	$v1, 0, get_puzzle_interrupt

	and	$v1, $k0, MAX_GROWTH_INT_MASK
	bne	$v1, 0, harvest_interrupt
	# add dispatch for other interrupt types here.

	li	$v0, PRINT_STRING	# Unhandled interrupt types
	la	$v1, unhandled_str
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
##################################################################################
set_fire:
	lw	$t0, BOT_X		#	$t2 = bot_x
	lw	$t1, BOT_Y
	blt	$t0, 90, label_1
	blt	$t1, 90, label_1
	bgt	$t0, 240, label_1
	bgt	$t1, 240, label_1
	jr	$ra
label_1:
	sw	$0, BURN_TILE
	jr	$ra

get_puzzle_interrupt:
	sw	$a1, REQUEST_PUZZLE_ACK
	li	$t0, 0
	#sw	$t0, VELOCITY
	la	$t1, solution_data
delete_data:
	add	$t2, $t0, $t1
	sw	$zero, 0($t2)
	add	$t0, $t0, 4
	blt	$t0, 328, delete_data
	la	$t0, puzzle_data
	move	$s0, $t1
	move	$a0, $t1
	move	$a1, $t0
	jal	set_fire
	jal	recursive_backtracking
	sw	$s0, SUBMIT_SOLUTION
	j	interrupt_dispatch
	################################################
request_puzzle_I:
	move	$t0, $a0
	sw	$t0, SET_RESOURCE_TYPE
	
	la	$t0, puzzle_data
	sw	$t0, REQUEST_PUZZLE
end_request_puzzle_I:
	jr	$ra
#####################FUNCTION########request_puzzle##########################
request_source_I:
	sub	$sp, $sp, 4
	sw	$ra, 0($sp)
	la	$t0, solution_data
	la	$t1, puzzle_data
	lw	$t1, 0($t1)
	lw	$t0, 0($t0)
	bne	$t0, 0, go_I
	bne	$t1, 0, end_request_source_I
go_I:
	lw	$t0, GET_NUM_SEEDS
	lw	$t1, GET_NUM_WATER_DROPS
	lw	$t2, GET_NUM_FIRE_STARTERS
	blt	$t0, 7, seed_I
	blt	$t1, 50, water_I
	blt	$t2, 1, fire_starter_I
	j	end_request_source_I
seed_I:
	li	$a0, 1
	j	request_I
water_I:
	li	$a0, 0
	j	request_I
fire_starter_I:
	li	$a0, 2
request_I:
	jal	request_puzzle_I
end_request_source_I:
	lw	$ra, 0($sp)
	add	$sp, $sp, 4
	jr	$ra
	################################################
forward_checking:
  	sub   $sp, $sp, 24
  	sw    $ra, 0($sp)
  	sw    $a0, 4($sp)
  	sw    $a1, 8($sp)
  	sw    $s0, 12($sp)
  	sw    $s1, 16($sp)
  	sw    $s2, 20($sp)
  	lw    $t0, 0($a1)     # size
  	li    $t1, 0          # col = 0
fc_for_col:
  	bge   $t1, $t0, fc_end_for_col  # col < size
  	div   $a0, $t0
  	mfhi  $t2             # position % size
  	mflo  $t3             # position / size
  	beq   $t1, $t2, fc_for_col_continue    # if (col != position % size)
  	mul   $t4, $t3, $t0
  	add   $t4, $t4, $t1   # position / size * size + col
  	mul   $t4, $t4, 8
  	lw    $t5, 4($a1) # puzzle->grid
  	add   $t4, $t4, $t5   # &puzzle->grid[position / size * size + col].domain
  	mul   $t2, $a0, 8   # position * 8
  	add   $t2, $t5, $t2 # puzzle->grid[position]
  	lw    $t2, 0($t2) # puzzle -> grid[position].domain
  	not   $t2, $t2        # ~puzzle->grid[position].domain
  	lw    $t3, 0($t4) #
  	and   $t3, $t3, $t2
  	sw    $t3, 0($t4)
  	beq   $t3, $0, fc_return_zero # if (!puzzle->grid[position / size * size + col].domain)
fc_for_col_continue:
  	add   $t1, $t1, 1     # col++
  	j     fc_for_col
fc_end_for_col:
  	li    $t1, 0          # row = 0
fc_for_row:
  	bge   $t1, $t0, fc_end_for_row  # row < size
  	div   $a0, $t0
  	mflo  $t2             # position / size
  	mfhi  $t3             # position % size
  	beq   $t1, $t2, fc_for_row_continue
  	lw    $t2, 4($a1)     # puzzle->grid
  	mul   $t4, $t1, $t0
  	add   $t4, $t4, $t3
  	mul   $t4, $t4, 8
  	add   $t4, $t2, $t4   # &puzzle->grid[row * size + position % size]
  	lw    $t6, 0($t4)
  	mul   $t5, $a0, 8
  	add   $t5, $t2, $t5
  	lw    $t5, 0($t5)     # puzzle->grid[position].domain
  	not   $t5, $t5
  	and   $t5, $t6, $t5
  	sw    $t5, 0($t4)
  	beq   $t5, $0, fc_return_zero
fc_for_row_continue:
  	add   $t1, $t1, 1     # row++
  	j     fc_for_row
fc_end_for_row:

  	li    $s0, 0          # i = 0
fc_for_i:
  	lw    $t2, 4($a1)
  	mul   $t3, $a0, 8
  	add   $t2, $t2, $t3
  	lw    $t2, 4($t2)     # &puzzle->grid[position].cage
  	lw    $t3, 8($t2)     # puzzle->grid[position].cage->num_cell
  	bge   $s0, $t3, fc_return_one
  	lw    $t3, 12($t2)    # puzzle->grid[position].cage->positions
  	mul   $s1, $s0, 4
  	add   $t3, $t3, $s1
  	lw    $t3, 0($t3)     # pos
  	lw    $s1, 4($a1)
  	mul   $s2, $t3, 8
  	add   $s2, $s1, $s2   # &puzzle->grid[pos].domain
  	lw    $s1, 0($s2)
  	move  $a0, $t3
  	jal get_domain_for_cell
  	lw    $a0, 4($sp)
  	lw    $a1, 8($sp)
  	and   $s1, $s1, $v0
  	sw    $s1, 0($s2)     # puzzle->grid[pos].domain &= get_domain_for_cell(pos, puzzle)
  	beq   $s1, $0, fc_return_zero
fc_for_i_continue:
  	add   $s0, $s0, 1     # i++
  	j     fc_for_i
fc_return_one:
  	li    $v0, 1
  	j     fc_return
fc_return_zero:
  	li    $v0, 0
fc_return:
  	lw    $ra, 0($sp)
  	lw    $a0, 4($sp)
  	lw    $a1, 8($sp)
  	lw    $s0, 12($sp)
  	lw    $s1, 16($sp)
  	lw    $s2, 20($sp)
  	add   $sp, $sp, 24
  	jr    $ra
############################forward_checking
recursive_backtracking:
  	sub   $sp, $sp, 680
  	sw    $ra, 0($sp)
  	sw    $a0, 4($sp)     # solution
  	sw    $a1, 8($sp)     # puzzle
  	sw    $s0, 12($sp)    # position
  	sw    $s1, 16($sp)    # val
  	sw    $s2, 20($sp)    # 0x1 << (val - 1)
  	                      # sizeof(Puzzle) = 8
  	                      # sizeof(Cell [81]) = 648
	
  	jal   is_complete
  	bne   $v0, $0, recursive_backtracking_return_one
  	lw    $a0, 4($sp)     # solution
  	lw    $a1, 8($sp)     # puzzle
  	jal   get_unassigned_position
  	move  $s0, $v0        # position
  	li    $s1, 1          # val = 1
recursive_backtracking_for_loop:
  	lw    $a0, 4($sp)     # solution
  	lw    $a1, 8($sp)     # puzzle
  	lw    $t0, 0($a1)     # puzzle->size
  	add   $t1, $t0, 1     # puzzle->size + 1
  	bge   $s1, $t1, recursive_backtracking_return_zero  # val < puzzle->size + 1	
  	lw    $t1, 4($a1)     # puzzle->grid
  	mul   $t4, $s0, 8     # sizeof(Cell) = 8
  	add   $t1, $t1, $t4   # &puzzle->grid[position]
  	lw    $t1, 0($t1)     # puzzle->grid[position].domain
  	sub   $t4, $s1, 1     # val - 1
  	li    $t5, 1
  	sll   $s2, $t5, $t4   # 0x1 << (val - 1)
  	and   $t1, $t1, $s2   # puzzle->grid[position].domain & (0x1 << (val - 1))
  	beq   $t1, $0, recursive_backtracking_for_loop_continue # if (domain & (0x1 << (val - 1)))
  	mul   $t0, $s0, 4     # position * 4
  	add   $t0, $t0, $a0
  	add   $t0, $t0, 4     # &solution->assignment[position]
  	sw    $s1, 0($t0)     # solution->assignment[position] = val
  	lw    $t0, 0($a0)     # solution->size
  	add   $t0, $t0, 1
  	sw    $t0, 0($a0)     # solution->size++
  	add   $t0, $sp, 32    # &grid_copy
  	sw    $t0, 28($sp)    # puzzle_copy.grid = grid_copy !!!
  	move  $a0, $a1        # &puzzle
  	add   $a1, $sp, 24    # &puzzle_copy
  	jal   clone           # clone(puzzle, &puzzle_copy)
  	mul   $t0, $s0, 8     # !!! grid size 8
  	lw    $t1, 28($sp)
  	
  	add   $t1, $t1, $t0   # &puzzle_copy.grid[position]
  	sw    $s2, 0($t1)     # puzzle_copy.grid[position].domain = 0x1 << (val - 1);
  	move  $a0, $s0
  	add   $a1, $sp, 24
  	jal   forward_checking  # forward_checking(position, &puzzle_copy)
  	beq   $v0, $0, recursive_backtracking_skip
	
  	lw    $a0, 4($sp)     # solution
  	add   $a1, $sp, 24    # &puzzle_copy
  	jal   recursive_backtracking
  	beq   $v0, $0, recursive_backtracking_skip
  	j     recursive_backtracking_return_one # if (recursive_backtracking(s	olution, &puzzle_copy))
recursive_backtracking_skip:
  	lw    $a0, 4($sp)     # solution
  	mul   $t0, $s0, 4
  	add   $t1, $a0, 4
  	add   $t1, $t1, $t0
  	sw    $0, 0($t1)      # solution->assignment[position] = 0
  	lw    $t0, 0($a0)
  	sub   $t0, $t0, 1
  	sw    $t0, 0($a0)     # solution->size -= 1
recursive_backtracking_for_loop_continue:
  	add   $s1, $s1, 1     # val++
  	j     recursive_backtracking_for_loop
recursive_backtracking_return_zero:
  	li    $v0, 0
  	j     recursive_backtracking_return
recursive_backtracking_return_one:
  	li    $v0, 1
recursive_backtracking_return:
  	lw    $ra, 0($sp)
  	lw    $a0, 4($sp)
  	lw    $a1, 8($sp)
  	lw    $s0, 12($sp)
  	lw    $s1, 16($sp)
  	lw    $s2, 20($sp)
  	add   $sp, $sp, 680
  	jr    $ra
############################recursive_backtracking
get_unassigned_position:
  	li    $v0, 0            # unassigned_pos = 0
  	lw    $t0, 0($a1)       # puzzle->size
  	mul  $t0, $t0, $t0     # puzzle->size * puzzle->size
  	add   $t1, $a0, 4       # &solution->assignment[0]
get_unassigned_position_for_begin:
  	bge   $v0, $t0, get_unassigned_position_return  # if (unassigned_pos < puzzle->size * puzzle->size)
  	mul  $t2, $v0, 4
  	add   $t2, $t1, $t2     # &solution->assignment[unassigned_pos]
  	lw    $t2, 0($t2)       # solution->assignment[unassigned_pos]
  	beq   $t2, 0, get_unassigned_position_return  # if (solution->assignment[unassigned_pos] == 0)
  	add   $v0, $v0, 1       # unassigned_pos++
  	j   get_unassigned_position_for_begin
get_unassigned_position_return:
  	jr    $ra
############################get_unassigned_positions
is_complete:
  	lw    $t0, 0($a0)       # solution->size
  	lw    $t1, 0($a1)       # puzzle->size
  	mul   $t1, $t1, $t1     # puzzle->size * puzzle->size
  	move	$v0, $0
  	seq   $v0, $t0, $t1
  	j     $ra
############################is_complete
convert_highest_bit_to_int:
    	move  $v0, $0   	      # result = 0
	
chbti_loop:
    	beq   $a0, $0, chbti_end
    	add   $v0, $v0, 1         # result ++
    	sra   $a0, $a0, 1         # domain >>= 1
    	j     chbti_loop

chbti_end:
    	jr	  $ra
############################convert_highest_bit_to_int
get_domain_for_addition:
    	sub    $sp, $sp, 20
    	sw     $ra, 0($sp)
    	sw     $s0, 4($sp)
    	sw     $s1, 8($sp)
    	sw     $s2, 12($sp)
    	sw     $s3, 16($sp)
    	move   $s0, $a0                     # s0 = target
    	move   $s1, $a1                     # s1 = num_cell
    	move   $s2, $a2                     # s2 = domain
	
    	move   $a0, $a2
    	jal    convert_highest_bit_to_int
    	move   $s3, $v0                     # s3 = upper_bound

    	sub    $a0, $0, $s2	                # -domain
    	and    $a0, $a0, $s2                # domain & (-domain)
    	jal    convert_highest_bit_to_int   # v0 = lower_bound
		   
    	sub    $t0, $s1, 1                  # num_cell - 1
    	mul    $t0, $t0, $v0                # (num_cell - 1) * lower_bound
    	sub    $t0, $s0, $t0                # t0 = high_bits
    	bge    $t0, 0, gdfa_skip0
	
    	li     $t0, 0

gdfa_skip0:
    	bge    $t0, $s3, gdfa_skip1
	
    	li     $t1, 1          
    	sll    $t0, $t1, $t0                # 1 << high_bits
    	sub    $t0, $t0, 1                  # (1 << high_bits) - 1
    	and    $s2, $s2, $t0                # domain & ((1 << high_bits) - 1)

gdfa_skip1:	   
    	sub    $t0, $s1, 1                  # num_cell - 1
    	mul    $t0, $t0, $s3                # (num_cell - 1) * upper_bound
    	sub    $t0, $s0, $t0                # t0 = low_bits
    	ble    $t0, $0, gdfa_skip2
	
    	sub    $t0, $t0, 1                  # low_bits - 1
    	sra    $s2, $s2, $t0                # domain >> (low_bits - 1)
    	sll    $s2, $s2, $t0                # domain >> (low_bits - 1) << (low	_bits - 1)

gdfa_skip2:	   
    	move   $v0, $s2                     # return domain
    	lw     $ra, 0($sp)
    	lw     $s0, 4($sp)
    	lw     $s1, 8($sp)
    	lw     $s2, 12($sp)
    	lw     $s3, 16($sp)
    	add    $sp, $sp, 20
    	jr     $ra
############################get_domain_for_addigion
get_domain_for_subtraction:
    	li     $t0, 1              
    	li     $t1, 2
    	mul    $t1, $t1, $a0            # target * 2
    	sll    $t1, $t0, $t1            # 1 << (target * 2)
    	or     $t0, $t0, $t1            # t0 = base_mask
    	li     $t1, 0                   # t1 = mask

gdfs_loop:
    	beq    $a2, $0, gdfs_loop_end	
    	and    $t2, $a2, 1              # other_domain & 1
    	beq    $t2, $0, gdfs_if_end
	   
    	sra    $t2, $t0, $a0            # base_mask >> target
    	or     $t1, $t1, $t2            # mask |= (base_mask >> target)

gdfs_if_end:
    	sll    $t0, $t0, 1              # base_mask <<= 1
    	sra    $a2, $a2, 1              # other_domain >>= 1
    	j      gdfs_loop

gdfs_loop_end:
    	and    $v0, $a1, $t1            # domain & mask
    	jr	   $ra
############################get_domain_for_subtraction
is_single_value_domain:
    	beq    	$a0, $0, isvd_zero     # return 0 if domain == 0
    	sub    	$t0, $a0, 1	          # (domain - 1)
    	and    	$t0, $t0, $a0          # (domain & (domain - 1))
    	bne    	$t0, $0, isvd_zero     # return 0 if (domain & (domain - 1)) != 0
    	li     	$v0, 1
    	jr	$ra

isvd_zero:	   
    	li   $v0, 0
    	jr   $ra
############################is_single_value_domain
get_domain_for_cell:
    # save registers    
    sub $sp, $sp, 36
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)
    sw $s3, 16($sp)
    sw $s4, 20($sp)
    sw $s5, 24($sp)
    sw $s6, 28($sp)
    sw $s7, 32($sp)

    li $t0, 0 # valid_domain
    lw $t1, 4($a1) # puzzle->grid (t1 free)
    sll $t2, $a0, 3 # position*8 (actual offset) (t2 free)
    add $t3, $t1, $t2 # &puzzle->grid[position]
    lw  $t4, 4($t3) # &puzzle->grid[position].cage
    lw  $t5, 0($t4) # puzzle->grid[posiition].cage->operation

    lw $t2, 4($t4) # puzzle->grid[position].cage->target

    move $s0, $t2   # remain_target = $s0  *!*!
    lw $s1, 8($t4) # remain_cell = $s1 = puzzle->grid[position].cage->num_cell
    lw $s2, 0($t3) # domain_union = $s2 = puzzle->grid[position].domain
    move $s3, $t4 # puzzle->grid[position].cage
    li $s4, 0   # i = 0
    move $s5, $t1 # $s5 = puzzle->grid
    move $s6, $a0 # $s6 = position
    # move $s7, $s2 # $s7 = puzzle->grid[position].domain

    bne $t5, 0, gdfc_check_else_if

    li $t1, 1
    sub $t2, $t2, $t1 # (puzzle->grid[position].cage->target-1)
    sll $v0, $t1, $t2 # valid_domain = 0x1 << (prev line comment)
    j gdfc_end # somewhere!!!!!!!!

gdfc_check_else_if:
    bne $t5, '+', gdfc_check_else

gdfc_else_if_loop:
    lw $t5, 8($s3) # puzzle->grid[position].cage->num_cell
    bge $s4, $t5, gdfc_for_end # branch if i >= puzzle->grid[position].cage->num_cell
    sll $t1, $s4, 2 # i*4
    lw $t6, 12($s3) # puzzle->grid[position].cage->positions
    add $t1, $t6, $t1 # &puzzle->grid[position].cage->positions[i]
    lw $t1, 0($t1) # pos = puzzle->grid[position].cage->positions[i]
    add $s4, $s4, 1 # i++

    sll $t2, $t1, 3 # pos * 8
    add $s7, $s5, $t2 # &puzzle->grid[pos]
    lw  $s7, 0($s7) # puzzle->grid[pos].domain

    beq $t1, $s6 gdfc_else_if_else # branch if pos == position

    

    move $a0, $s7 # $a0 = puzzle->grid[pos].domain
    jal is_single_value_domain#https://prairielearn.engr.illinois.edu/
    bne $v0, 1 gdfc_else_if_else # branch if !is_single_value_domain()
    move $a0, $s7
    jal convert_highest_bit_to_int
    sub $s0, $s0, $v0 # remain_target -= convert_highest_bit_to_int
    addi $s1, $s1, -1 # remain_cell -= 1
    j gdfc_else_if_loop
gdfc_else_if_else:
    or $s2, $s2, $s7 # domain_union |= puzzle->grid[pos].domain
    j gdfc_else_if_loop

gdfc_for_end:
    move $a0, $s0
    move $a1, $s1
    move $a2, $s2
    jal get_domain_for_addition # $v0 = valid_domain = get_domain_for_addition()
    j gdfc_end

gdfc_check_else:
    lw $t3, 12($s3) # puzzle->grid[position].cage->positions
    lw $t0, 0($t3) # puzzle->grid[position].cage->positions[0]
    lw $t1, 4($t3) # puzzle->grid[position].cage->positions[1]
    xor $t0, $t0, $t1
    xor $t0, $t0, $s6 # other_pos = $t0 = $t0 ^ position
    lw $a0, 4($s3) # puzzle->grid[position].cage->target

    sll $t2, $s6, 3 # position * 8
    add $a1, $s5, $t2 # &puzzle->grid[position]
    lw  $a1, 0($a1) # puzzle->grid[position].domain
    # move $a1, $s7 

    sll $t1, $t0, 3 # other_pos*8 (actual offset)
    add $t3, $s5, $t1 # &puzzle->grid[other_pos]
    lw $a2, 0($t3)  # puzzle->grid[other_pos].domian

    jal get_domain_for_subtraction # $v0 = valid_domain = get_domain_for_subtraction()
    # j gdfc_end
gdfc_end:
# restore registers
    
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    lw $s3, 16($sp)
    lw $s4, 20($sp)
    lw $s5, 24($sp)
    lw $s6, 28($sp)
    lw $s7, 32($sp)
    add $sp, $sp, 36    
    jr $ra
###########################
clone:

    lw  $t0, 0($a0)
    sw  $t0, 0($a1)

    mul $t0, $t0, $t0
    mul $t0, $t0, 2 # two words in one grid

    lw  $t1, 4($a0) # &puzzle(ori).grid
    lw  $t2, 4($a1) # &puzzle(clone).grid

    li  $t3, 0 # i = 0;
clone_for_loop:
    bge  $t3, $t0, clone_for_loop_end
    sll $t4, $t3, 2 # i * 4
    add $t5, $t1, $t4 # puzzle(ori).grid ith word
    lw   $t6, 0($t5)

    add $t5, $t2, $t4 # puzzle(clone).grid ith word
    sw   $t6, 0($t5)
    
    addi $t3, $t3, 1 # i++
    
    j    clone_for_loop
clone_for_loop_end:
    jr  $ra
########################################################
harvest_interrupt:
	sw	$a1, MAX_GROWTH_ACK
	lw	$t0, MAX_GROWTH_TILE
	and	$t1, $t0, 0xffff	#	$t1 = yCoord
	srl	$t0, $t0, 16		#	$t0 = xCoord
	mul	$t0, $t0, 30
	mul	$t1, $t1, 30
	add	$t0, $t0, 15
	add	$t1, $t1, 15
	move	$a1, $t1
	move	$a0, $t0
	jal	move_to_x_y_for_harvest
	sw	$0, HARVEST_TILE
	lw	$a0, BOT_X
	lw	$a1, BOT_Y
	jal	seed_tile_for_harvest
	j	interrupt_dispatch
	################################
move_to_x_y_for_harvest:
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
	bge	$s3, 300, end_move_to_x_y_for_harvest
	bge	$s4, 300, end_move_to_x_y_for_harvest
angle_X_for_harvest:
	ble	$s3, $s1, turn_X_for_harvest
	li	$s0, 0
	sw	$s0, ANGLE
	li	$s0, 1
	sw	$s0, ANGLE_CONTROL
	j	move_X_for_harvest
turn_X_for_harvest:
	li	$s0, 180
	sw	$s0, ANGLE
	li	$s0, 1
	sw	$s0, ANGLE_CONTROL
move_X_for_harvest:
	beq	$s1, $s3, angle_Y_for_harvest
	li	$s0, 10
	sw	$s0, VELOCITY
	lw	$s1, BOT_X
	j	move_X_for_harvest
angle_Y_for_harvest:
	ble	$s4, $s2, turn_Y_for_harvest
	li	$s0, 90
	sw	$s0, ANGLE
	li	$s0, 1
	sw	$s0, ANGLE_CONTROL
	j	move_Y_for_harvest
turn_Y_for_harvest:
	li	$s0, 270
	sw	$s0, ANGLE
	li	$s0, 1
	sw	$s0, ANGLE_CONTROL
move_Y_for_harvest:
	beq	$s2, $s4, end_move_to_x_y_for_harvest
	li	$s0, 10
	sw	$s0, VELOCITY
	lw	$s2, BOT_Y
	j	move_Y_for_harvest
end_move_to_x_y_for_harvest:
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
	###############
#####################FUNCTION########move_to_x_y#############################
scan_plant_for_harvest:
	la	$t0, tile_data			
	sw	$t0, TILE_SCAN
	move	$v0, $t0
	jr	$ra
#####################FUNCTION########scan_plant##############################
plant_seed_for_harvest:
	sub	$sp, $sp, 16
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$s2, 12($sp)
	lw	$s1, BOT_X
	lw	$s2, BOT_Y
	jal	scan_plant_for_harvest
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
	j	end_plant_seed_for_harvest
error_for_harvest:
	li	$v0, 0
end_plant_seed_for_harvest:
	lw	$ra, 0($sp)
	lw	$s0, 4($sp)
	lw	$s1, 8($sp)
	lw	$s2, 12($sp)
	add	$sp, $sp, 16
	jr	$ra
#####################FUNCTION########plant_seed##############################
seed_tile_for_harvest:
	sub	$sp, $sp, 4
	sw	$ra, 0($sp)
	jal	plant_seed_for_harvest
	bne	$v0, 1, seed_next_for_harvest
	j	end_seed_tile_for_harvest
seed_next_for_harvest:
	bge	$a0, 270, seed_next_y_for_harvest
seed_next_x_for_harvest:
	add	$a0, $a0, 30
	jal	seed_tile_for_harvest
	j	end_seed_tile_for_harvest
seed_next_y_for_harvest:
	add	$a1, $a1, 30
	jal	seed_tile_for_harvest
end_seed_tile_for_harvest:
	#jal	request_source_I
	lw	$ra, 0($sp)
	add	$sp, $sp, 4
	jr	$ra
##############################################################################
non_intrpt:				# was some non-interrupt
	li	$v0, PRINT_STRING
	la	$v1, non_intrpt_str
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
	lw	$v1, 28($k0)
	lw	$t4, 32($k0)
	lw	$t5, 36($k0)
	lw	$t6, 40($k0)
	lw	$s1, 44($k0)
	lw	$s2, 48($k0)
	lw	$s3, 52($k0)
	lw	$s4, 56($k0)
	lw	$v1, 60($k0)
.set noat
	move	$at, $k1		# Restore $at
.set at 
	eret
