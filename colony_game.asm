#
# File:            colony_game.asm
#
# Title:           Colony Game
# ------------------------------------------------------------------
# Description:     Runs the colony game, and provides external functions
#
# Author:          Elijah Bendinsky
#
# Date Modified:   03/22/2018
#

#
# Global Definitions
#
        .globl colony_copy
        .globl colony_clear
        .globl colony_print
        .globl colony_get_cell
        .globl scrap_change_cell
        
#
# Linker Replacement
#
FRAMESIZE_8=8
FRAMESIZE_16=16
FRAMESIZE_40=40

COLONY_A=65
COLONY_B=66

COLONY_CLEAR=32

        .text

#
# Function:        colony_game
# ---------------------------------------------------------
# Description:     Runs the colony game
#
# Aurguments:      a0 - parameter block
#                      - address of colony array
#                      - address of scrap array
#                      - size of colony
#                  a1 - generations to run
#
colony_game:
        #
        # Save S registers
        #
        addi    $sp, $sp, -FRAMESIZE_40
        sw      $s0, -4+FRAMESIZE_40($sp)
        sw      $s1, -8+FRAMESIZE_40($sp)
        sw      $s2, -12+FRAMESIZE_40($sp)
        sw      $s3, -16+FRAMESIZE_40($sp)
        sw      $s4, -20+FRAMESIZE_40($sp)
        sw      $s5, -24+FRAMESIZE_40($sp)
        sw      $s6, -28+FRAMESIZE_40($sp)
        sw      $s7, -32+FRAMESIZE_40($sp)
        sw      $ra, -36+FRAMESIZE_40($sp)
    
        addi    $s7, $a0, 0            # save parameters
        addi    $s6, $a1, 1

        li      $s0, 0                 # generation counter

colony_game_loop:
        slt     $t0, $s0, $s6
        beq     $t0, $zero, colony_game_done

        addi    $a0, $s7, 0            # print colony
        addi    $a1, $s0, 0
        jal     colony_print

        lw      $t0, 8($s7)            # initialize vars to run generation
        mul     $s1, $t0, $t0
        lw      $s2, 4($s7)
        addi    $s3, $zero, 0
        addi    $s4, $zero, 0        

colony_game_colony_loop:
        slti    $t0, $s1, 1
        bne     $t0, $zero, colony_game_colony_loop_done

        lw      $a0, 0($s7)            # calculate neighbors
        lw      $a1, 8($s7)
        addi    $a2, $s3, 0
        addi    $a3, $s4, 0
        jal     colony_neighbors

        lw      $t0, 0($s7)            # get current cell address
        lw      $t1, 8($s7)
        mul     $t1, $s3, $t1
        add     $t1, $t1, $s4
        mul     $t1, $t1, 4
        add     $t0, $t0, $t1

        addi    $a0, $s7, 0            # ready parameters for change_cell
        addi    $a1, $s3, 0
        addi    $a2, $s4, 0
        
        lw      $t0, 0($t0)            # get cell value

        li      $a3, COLONY_A          # if cell == A value
        beq     $t0, $a3, a_cell

        li      $a3, COLONY_B          # if cell == B value
        beq     $t0, $a3, b_cell

        li      $a3, COLONY_CLEAR      # if cell == dead
        beq     $t0, $a3, dead_cell

        j       done_cell              # catch-all (shouldn't occur)

a_cell:
        sub     $t0, $v0, $v1          # num a neighbors - num b neighbors

        slti    $t1, $t0, 2            # kill cell if 4 <= neighbors <= 1
        li      $a3, COLONY_CLEAR
        bne     $t1, $zero, change_cell
        slti    $t1, $t0, 4
        beq     $t1, $zero, change_cell

        li      $a3, COLONY_A          # otherwise cell survives
        j       change_cell

b_cell:
        sub     $t0, $v1, $v0          # num b neighbors - num a neighbors

        slti    $t1, $t0, 2            # kill cell if 4 <= neighbors <= 1
        li      $a3, COLONY_CLEAR
        bne     $t1, $zero, change_cell
        slti    $t1, $t0, 4
        beq     $t1, $zero, change_cell

        li      $a3, COLONY_B          # otherwise cell survives
        j       change_cell

dead_cell:
        li      $a3, COLONY_A          # revive a cell if neighbors == 3
        sub     $t0, $v0, $v1
        
        slti    $t1, $t0, 3
        slti    $t2, $t0, 4
        xor     $t0, $t1, $t2 
        
        bne     $t0, $zero, change_cell

        li      $a3, COLONY_B          # revive b cell if neighbors == 3
        sub     $t0, $v1, $v0
        
        slti    $t1, $t0, 3
        slti    $t2, $t0, 4
        xor     $t0, $t1, $t2 
        
        bne     $t0, $zero, change_cell
        
        li      $a3, COLONY_CLEAR      # otherwise, remain dead
        j       change_cell            # (doing it this way to clean scrap arr)

change_cell:
        jal     scrap_change_cell      # change the scrap array cell
        
        j       done_cell

done_cell:
        addi    $s4, $s4, 1            # adjust values for next round and loop

        lw      $t0, 8($s7)
        slt     $t1, $s4, $t0
        bne     $t1, $zero, not_next_row

next_row:
        addi    $s4, $zero, 0          # reset col and increment row
        addi    $s3, $s3, 1
        
not_next_row:
        addi    $s2, $s2, 4            # increment array pointer
        addiu   $s1, $s1, -1           # decrement num cells to check

        j       colony_game_colony_loop

colony_game_colony_loop_done:
        lw      $a0, 0($s7)            # copy scrap colony to colony
        lw      $a1, 4($s7)
        lw      $a2, 8($s7)
        jal     colony_copy

        addi    $s0, $s0, 1            # increment generation

        j       colony_game_loop

colony_game_done:
        #
        # Restore S registers
        #
        lw      $s0, -4+FRAMESIZE_40($sp)
        lw      $s1, -8+FRAMESIZE_40($sp)
        lw      $s2, -12+FRAMESIZE_40($sp)
        lw      $s3, -16+FRAMESIZE_40($sp)
        lw      $s4, -20+FRAMESIZE_40($sp)
        lw      $s5, -24+FRAMESIZE_40($sp)
        lw      $s6, -28+FRAMESIZE_40($sp)
        lw      $s7, -32+FRAMESIZE_40($sp)
        lw      $ra, -36+FRAMESIZE_40($sp)
        addi    $sp, $sp, FRAMESIZE_40

        jr      $ra

#
# Function:        colony_neighbors
# ---------------------------------------------------------
# Description:     Calculates the number of neighbors
# 
# Arguments:       a0 - address of colony
#                  a1 - size of colony
#                  a2 - row of cell to calculate
#                  a3 - col of cell to calculate
#
# Returns:         v0 - number of friends
#                  v1 - number of enemies
#
colony_neighbors:
        #
        # Save S registers
        #
        addi       $sp, $sp, -FRAMESIZE_40
        sw         $s0, -4+FRAMESIZE_40($sp)
        sw         $s1, -8+FRAMESIZE_40($sp)
        sw         $s2, -12+FRAMESIZE_40($sp)
        sw         $s3, -16+FRAMESIZE_40($sp)
        sw         $s4, -20+FRAMESIZE_40($sp)
        sw         $s5, -24+FRAMESIZE_40($sp)
        sw         $s6, -28+FRAMESIZE_40($sp)
        sw         $s7, -32+FRAMESIZE_40($sp)
        sw         $ra, -36+FRAMESIZE_40($sp)

        addi       $s7, $a0, 0         # save parameters
        addi       $s6, $a1, 0

        addi       $s0, $zero, 0       # init neighbor counts
        addi       $s1, $zero, 0

        addi       $s2, $a2, 0         # get row and col index
        addi       $s3, $a3, 0

        # Check cell (row-1, col-1)
        addiu      $a2, $s2, -1
        slti       $t0, $a2, 0
        mul        $t0, $t0, $s6
        add        $a2, $a2, $t0       # row - 1

        addiu      $a3, $s3, -1
        slti       $t0, $a3, 0
        mul        $t0, $t0, $s6
        add        $a3, $a3, $t0       # col - 1

        jal        colony_get_cell

        li         $t1, COLONY_A
        
        slt        $t6, $v0, $t1
        slt        $t7, $t1, $v0

        li         $t1, 1
        sub        $t1, $t1, $t6
        sub        $t1, $t1, $t7

        add        $s0, $s0, $t1

        li         $t1, COLONY_B
        
        slt        $t6, $v0, $t1
        slt        $t7, $t1, $v0

        li         $t1, 1
        sub        $t1, $t1, $t6
        sub        $t1, $t1, $t7

        add        $s1, $s1, $t1

        # Check cell (row-1, col)
        addiu      $a2, $s2, -1
        slti       $t0, $a2, 0
        mul        $t0, $t0, $s6
        add        $a2, $a2, $t0       # row - 1

        addiu      $a3, $s3, 0         # col + 0

        jal        colony_get_cell

        li         $t1, COLONY_A
        
        slt        $t6, $v0, $t1
        slt        $t7, $t1, $v0

        li         $t1, 1
        sub        $t1, $t1, $t6
        sub        $t1, $t1, $t7

        add        $s0, $s0, $t1

        li         $t1, COLONY_B
        
        slt        $t6, $v0, $t1
        slt        $t7, $t1, $v0

        li         $t1, 1
        sub        $t1, $t1, $t6
        sub        $t1, $t1, $t7

        add        $s1, $s1, $t1

        # Check cell (row-1, col+1)
        addiu      $a2, $s2, -1
        slti       $t0, $a2, 0
        mul        $t0, $t0, $s6
        add        $a2, $a2, $t0       # row - 1

        addiu      $a3, $s3, 1
        addiu      $t0, $s6, -1
        slt        $t0, $t0, $a3
        mul        $t0, $t0, $s6
        sub        $a3, $a3, $t0       # col + 1

        jal        colony_get_cell

        li         $t1, COLONY_A       # s0++ if cell == a
        
        slt        $t6, $v0, $t1
        slt        $t7, $t1, $v0

        li         $t1, 1
        sub        $t1, $t1, $t6
        sub        $t1, $t1, $t7

        add        $s0, $s0, $t1

        li         $t1, COLONY_B       # s1++ if cell == b
        
        slt        $t6, $v0, $t1
        slt        $t7, $t1, $v0

        li         $t1, 1
        sub        $t1, $t1, $t6
        sub        $t1, $t1, $t7

        add        $s1, $s1, $t1

        # Check cell (row, col-1)
        addiu      $a2, $s2, 0         # row + 0

        addiu      $a3, $s3, -1
        slti       $t0, $a3, 0
        mul        $t0, $t0, $s6
        add        $a3, $a3, $t0       # col - 1

        jal        colony_get_cell

        li         $t1, COLONY_A       # s0++ if cell == a
        
        slt        $t6, $v0, $t1
        slt        $t7, $t1, $v0

        li         $t1, 1
        sub        $t1, $t1, $t6
        sub        $t1, $t1, $t7

        add        $s0, $s0, $t1

        li         $t1, COLONY_B       # s1++ if cell == b
        
        slt        $t6, $v0, $t1
        slt        $t7, $t1, $v0

        li         $t1, 1
        sub        $t1, $t1, $t6
        sub        $t1, $t1, $t7

        add        $s1, $s1, $t1

        # Check cell (row, col+1)
        addiu      $a2, $s2, 0         # row + 0

        addiu      $a3, $s3, 1
        addiu      $t0, $s6, -1
        slt        $t0, $t0, $a3
        mul        $t0, $t0, $s6
        sub        $a3, $a3, $t0       # col + 1

        jal        colony_get_cell

        li         $t1, COLONY_A       # s0++ if cell == a
        
        slt        $t6, $v0, $t1
        slt        $t7, $t1, $v0

        li         $t1, 1
        sub        $t1, $t1, $t6
        sub        $t1, $t1, $t7

        add        $s0, $s0, $t1

        li         $t1, COLONY_B       # s1++ if cell == b
        
        slt        $t6, $v0, $t1
        slt        $t7, $t1, $v0

        li         $t1, 1
        sub        $t1, $t1, $t6
        sub        $t1, $t1, $t7

        add        $s1, $s1, $t1

        # Check cell (row+1, col-1)
        addiu      $a2, $s2, 1
        addiu      $t0, $s6, -1
        slt        $t0, $t0, $a2
        mul        $t0, $t0, $s6
        sub        $a2, $a2, $t0       # row + 1

        addiu      $a3, $s3, -1
        slti       $t0, $a3, 0
        mul        $t0, $t0, $s6
        add        $a3, $a3, $t0       # col - 1

        jal        colony_get_cell

        li         $t1, COLONY_A       # s0++ if cell == a
        
        slt        $t6, $v0, $t1
        slt        $t7, $t1, $v0

        li         $t1, 1
        sub        $t1, $t1, $t6
        sub        $t1, $t1, $t7

        add        $s0, $s0, $t1

        li         $t1, COLONY_B       # s1++ if cell == b
        
        slt        $t6, $v0, $t1
        slt        $t7, $t1, $v0

        li         $t1, 1
        sub        $t1, $t1, $t6
        sub        $t1, $t1, $t7

        add        $s1, $s1, $t1

        # Check cell (row+1, col)
        addiu      $a2, $s2, 1
        addiu      $t0, $s6, -1
        slt        $t0, $t0, $a2
        mul        $t0, $t0, $s6
        sub        $a2, $a2, $t0       # row + 1

        addiu      $a3, $s3, 0         # col + 0

        jal        colony_get_cell

        li         $t1, COLONY_A       # s0++ if cell == a
        
        slt        $t6, $v0, $t1
        slt        $t7, $t1, $v0

        li         $t1, 1
        sub        $t1, $t1, $t6
        sub        $t1, $t1, $t7

        add        $s0, $s0, $t1

        li         $t1, COLONY_B       # s1++ if cell == b
        
        slt        $t6, $v0, $t1
        slt        $t7, $t1, $v0

        li         $t1, 1
        sub        $t1, $t1, $t6
        sub        $t1, $t1, $t7

        add        $s1, $s1, $t1

        # Check cell (row+1, col+1)
        addiu      $a2, $s2, 1
        addiu      $t0, $s6, -1
        slt        $t0, $t0, $a2
        mul        $t0, $t0, $s6
        sub        $a2, $a2, $t0       # row + 1

        addiu      $a3, $s3, 1
        addiu      $t0, $s6, -1
        slt        $t0, $t0, $a3
        mul        $t0, $t0, $s6
        sub        $a3, $a3, $t0       # col + 1

        jal        colony_get_cell

        li         $t1, COLONY_A       # s0++ if cell == a
        
        slt        $t6, $v0, $t1
        slt        $t7, $t1, $v0

        li         $t1, 1
        sub        $t1, $t1, $t6
        sub        $t1, $t1, $t7

        add        $s0, $s0, $t1

        li         $t1, COLONY_B       # s1++ if cell == b
        
        slt        $t6, $v0, $t1
        slt        $t7, $t1, $v0

        li         $t1, 1
        sub        $t1, $t1, $t6
        sub        $t1, $t1, $t7

        add        $s1, $s1, $t1

        addi       $v0, $s0, 0
        addi       $v1, $s1, 0

        #
        # Restore S registers
        #
        lw         $s0, -4+FRAMESIZE_40($sp)
        lw         $s1, -8+FRAMESIZE_40($sp)
        lw         $s2, -12+FRAMESIZE_40($sp)
        lw         $s3, -16+FRAMESIZE_40($sp)
        lw         $s4, -20+FRAMESIZE_40($sp)
        lw         $s5, -24+FRAMESIZE_40($sp)
        lw         $s6, -28+FRAMESIZE_40($sp)
        lw         $s7, -32+FRAMESIZE_40($sp)
        lw         $ra, -36+FRAMESIZE_40($sp)
        addi       $sp, $sp, FRAMESIZE_40

        jr         $ra

