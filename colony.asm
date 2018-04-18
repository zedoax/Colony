#
# File:            colony.asm
# 
# Title:           Colony Project: Concepts of Computer Systems
# ---------------------------------------------------------------
# Description:     Runs a game of life based on parameter input
#
# Author:          Elijah Bendinsky
#
# Date Modified:   03/24/2018
#

	.data

#
# INPUT Prompts
#
prompt_size:
        .asciiz "\nEnter board size: "
prompt_generations:
        .asciiz "\nEnter number of generations to run: "
prompt_a_alive:
        .asciiz "\nEnter number of live cells for colony A: "
prompt_b_alive:
        .asciiz "\nEnter number of live cells for colony B: "
prompt_locations:
        .asciiz "\nStart entering locations\n"

        .align 2

#
# ERROR Messages
#
error_size:
        .asciiz "\nWARNING: illegal board size, try again: "
error_generations:
        .asciiz "\nWARNING: illegal number of generations, try again: "
error_alive:
        .asciiz "\nWARNING: illegal number of live cells, try again: "
error_locations:
        .asciiz "\nERROR: illegal point location\n"

        .align 2

#
# OUTPUT Text
#
colony_banner:
        .ascii "\n**********************\n"
        .ascii "****    Colony    ****\n"
        .asciiz "**********************\n"

        .align 2

#
# Global Variables
# 
        .globl colony_change_cell
        .globl colony_game
        .globl colony_clear

param_block:
        .word 0, 1, 2, 3

        .align 2

#
# Linker Replacements
#
PRINT_INT=1
PRINT_STRING=4
PRINT_CHAR=11

READ_INTEGER=5
READ_CHARACTER=12

FRAMESIZE_40=40

COLONY_A=65
COLONY_B=66

# ************************** BEGIN MAIN PROGRAM *******************************

    .text
#
# Function:        main
# ---------------------------------------------------------
# Description:     Take input and start game of life
#
main:
        #
        # Save S registers
        #
        addi    $sp, $sp, -FRAMESIZE_40
        sw      $ra, -4+FRAMESIZE_40($sp)
        sw      $s0, -8+FRAMESIZE_40($sp)
        sw      $s1, -12+FRAMESIZE_40($sp)
        sw      $s2, -16+FRAMESIZE_40($sp)
        sw      $s3, -20+FRAMESIZE_40($sp)
        sw      $s4, -24+FRAMESIZE_40($sp)
        sw      $s5, -28+FRAMESIZE_40($sp)
        sw      $s6, -32+FRAMESIZE_40($sp)
        sw      $s7, -36+FRAMESIZE_40($sp)

print_banner:
        addi    $v0, $zero, PRINT_STRING     # Print the Colony Banner
        la      $a0, colony_banner
        syscall

input:
        la      $a0, prompt_size       # Print size prompt

input_size:
        addi    $v0, $zero, PRINT_STRING
        syscall

        addi    $v0, $zero, READ_INTEGER     # Enter size of colony
        syscall

        la      $a0, error_size

        slti    $t0, $v0, 31           # Set t0 = 1 if input <= 30
        slti    $t1, $v0, 4            # Set t1 = 0 if input >= 4
        not     $t1                    # Flip t1
        and     $t0, $t0, $t1          # t0 = 1 if 4 <= input <= 30
        beq     $t0, $zero, input_size # Redo input if invalid

        addi    $s0, $v0, 0            # s0 = colony size
        la      $t0, param_block
        sw      $s0, 8($t0)            # put size on the param block

        mul     $s7, $s0, $s0          # Calculate size of colony array
        mul     $s7, $s7, 4
        
        sub     $sp, $sp, $s7          # Allocate colony a on stack

        la      $t0, param_block
        sw      $sp, 0($t0)            # Put address of colony on p block

        addi    $a0, $sp, 0
        addi    $a1, $s0, 0
        jal     colony_clear
        
        sub     $sp, $sp, $s7          # Allocate colony b on stack

        la      $t0, param_block            
        sw      $sp, 4($t0)            # Put address of colony on p block

        addi    $a0, $sp, 0
        addi    $a1, $s0, 0
        jal     colony_clear
        
        la      $a0, prompt_generations

input_generations:
        addi    $v0, $zero, PRINT_STRING
        syscall

        addi    $v0, $zero, READ_INTEGER
        syscall

        la      $a0, error_generations

        slti    $t0, $v0, 21           # Set t0 = 1 if input <= 20
        slti    $t1, $v0, 0            # Set t1 = 0 if input >= 0
        not     $t1                    # Flip t1
        and     $t0, $t0, $t1          # t0 = 1 if 0 <= input <= 20
        beq     $t0, $zero, input_generations

        addi    $s3, $v0, 0            # Save generations

        la      $a0, prompt_a_alive

input_a_alive:
        addi    $v0, $zero, PRINT_STRING
        syscall

        addi    $v0, $zero, READ_INTEGER
        syscall

        la      $a0, error_alive

        mul     $t0, $s0, $s0
        slt     $t0, $v0, $t0          # Set t0 = 1 if input < cells
        slti    $t1, $v0, 0            # Set t1 = 0 if input >= 0
        not     $t1                    # Flip t1
        and     $t0, $t0, $t1          # t0 = 1 if 0 <= input < cells
        beq     $t0, $zero, input_a_alive

        addi    $s1, $v0, 0            # s1 = Number of a to place

        la      $a0, prompt_locations

input_a_locations:
        addi    $v0, $zero, PRINT_STRING
        syscall

input_a_locations_loop:
        slti    $t0, $s1, 1            # Next when no more a need placing
        bne     $t0, $zero, input_b_alive

        addi    $v0, $zero, READ_INTEGER
        syscall
    
        la      $a0, error_alive

        slt     $t0, $v0, $s0          # Set t0 = 1 if input < boardsize
        slti    $t1, $v0, 0            # Set t1 = 0 if input >= 0
        not     $t1                    # Flip t1
        and     $t0, $t0, $t1          # Exit if 0 <= input < boardsize
        beq     $t0, $zero, input_locations_error

        addi    $s2, $v0, 0            # s2 = row for a

        addi    $v0, $zero, READ_INTEGER
        syscall

        la      $a0, error_alive

        slt     $t0, $v0, $s0          # Set t0 = 1 if input < boardsize
        slti    $t1, $v0, 0            # Set t1 = 0 if input >= 0
        not     $t1                    # Flip t1
        and     $t0, $t0, $t1          # Exit if 0 <= input < boardsize
        beq     $t0, $zero, input_locations_error

        la      $a0, param_block
        addi    $a1, $s2, 0            # Change value of requested cell
        addi    $a2, $v0, 0
        li      $a3, COLONY_A
        jal     colony_change_cell

        addi    $s1, $s1, -1

        la      $a0, prompt_b_alive

        j       input_a_locations_loop

input_b_alive:
        addi    $v0, $zero, PRINT_STRING
        syscall

        addi    $v0, $zero, READ_INTEGER
        syscall

        la      $a0, error_alive

        mul     $t0, $s0, $s0
        slt     $t0, $v0, $t0          # Set t0 = 1 if input < cells
        slti    $t1, $v0, 0            # Set t1 = 0 if input >= 0
        not     $t1                    # Flip t1
        and     $t0, $t0, $t1          # t0 = 1 if 0 <= input < cells
        beq     $t0, $zero, input_b_alive

        addi    $s1, $v0, 0            # s1 = Number of b to place

        la      $a0, prompt_locations

input_b_locations:
        addi    $v0, $zero, PRINT_STRING
        syscall

input_b_locations_loop:
        slti    $t0, $s1, 1            # Next when no more a need placing
        bne     $t0, $zero, colony_run

        addi    $v0, $zero, READ_INTEGER
        syscall

        la      $a0, error_alive

        slt     $t0, $v0, $s0          # Set t0 = 1 if input < boardsize
        slti    $t1, $v0, 0            # Set t1 = 0 if input >= 0
        not     $t1                    # Flip t1
        and     $t0, $t0, $t1          # Exit if 0 <= input < boardsize
        beq     $t0, $zero, input_locations_error

        addi    $s2, $v0, 0            # s2 = row for b

        addi    $v0, $zero, READ_INTEGER
        syscall

        la      $a0, error_alive

        slt     $t0, $v0, $s0          # Set t0 = 1 if input < boardsize
        slti    $t1, $v0, 0            # Set t1 = 0 if input >= 0
        not     $t1                    # Flip t1
        and     $t0, $t0, $t1          # Exit if 0 <= input < boardsize
        beq     $t0, $zero, input_locations_error

        la      $a0, param_block       # Change value of requested cell
        addi    $a1, $s2, 0
        addi    $a2, $v0, 0
        li      $a3, COLONY_B
        jal     colony_change_cell

        addi    $s1, $s1, -1

        j       input_b_locations_loop

input_locations_error:
        addi    $v0, $zero, PRINT_STRING
        la      $a0, error_locations
        syscall

        j       done

colony_run:
        la      $a0, param_block
        addi    $a1, $s3, 0
        jal     colony_game            # Start running colony game

done:
        add     $sp, $sp, $s7
        add     $sp, $sp, $s7

        #
        # Restore S registers
        #
        lw      $ra, -4+FRAMESIZE_40($sp)
        lw      $s0, -8+FRAMESIZE_40($sp)
        lw      $s1, -12+FRAMESIZE_40($sp)
        lw      $s2, -16+FRAMESIZE_40($sp)
        lw      $s3, -20+FRAMESIZE_40($sp)
        lw      $s4, -24+FRAMESIZE_40($sp)
        lw      $s5, -28+FRAMESIZE_40($sp)
        lw      $s6, -32+FRAMESIZE_40($sp)
        lw      $s7, -36+FRAMESIZE_40($sp)       
        lw      $sp, -40+FRAMESIZE_40($sp)
        addi    $sp, $sp, FRAMESIZE_40

        jr      $ra

