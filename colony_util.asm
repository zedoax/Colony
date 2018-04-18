#
# File:            colony_util.asm
#
# Title:           Colony Util
#

        .data
#
# OUTPUT Text
#
generation_banner_start:
        .asciiz "\n====    GENERATION "
generation_banner_end:
        .asciiz "    ====\n"

        .align 2

#
# Global Definitions
#
        .globl colony_copy
        .globl colony_print
        .globl colony_clear
        .globl colony_get_cell
        .globl colony_change_cell
        .globl scrap_change_cell
        
#
# Linker Replacement
#
PRINT_INT=1
PRINT_STRING=4
PRINT_CHAR=11

FRAMESIZE_8=8
FRAMESIZE_12=12
FRAMESIZE_16=16

COLONY_CLEAR=32

        .text
#
# Function:        colony_get_cell
# ---------------------------------------------------------
# Description:     Retrive the value of a cell
#
# Arguments:       a0 - address of array
#                  a1 - size of colony
#                  a2 - row to grab
#                  a3 - col to grab
#
# Returns:         v0 - value of cell
#
colony_get_cell:
        #
        # Save S registers
        #
        addi      $sp, $sp, -FRAMESIZE_8
        sw        $s0, -4+FRAMESIZE_8($sp)
    
        mul       $s0, $a1, $a2
        add       $s0, $s0, $a3
        mul       $s0, $s0, 4          # Get the offset from colony address

        add       $s0, $s0, $a0        # Address of cell

        lw        $v0, 0($s0)

        #
        # Restore S registers
        #
        lw        $s0, -4+FRAMESIZE_8($sp)
        addi      $sp, $sp, FRAMESIZE_8       

        jr        $ra

#
# Function:        colony_change_cell
# ---------------------------------------------------------
# Description:     Changes the value of a cell
#
# Arguments:       a0 - parameter block
#                      - address of colony array
#                      - address of scrap array
#                      - size of colony
#                  a1 - row to change
#                  a2 - col to change
#                  a3 - character to change to
#
colony_change_cell:
        #
        # Save S registers
        #
        addi      $sp, $sp, -FRAMESIZE_8
        sw        $s0, -4+FRAMESIZE_8($sp)
        
        lw        $t0, 8($a0)                
        mul       $s0, $a1, $t0
        add       $s0, $s0, $a2
        mul       $s0, $s0, 4          # Get offset from colony address

        lw        $t0, 0($a0)
        add       $s0, $s0, $t0        # s0 = address that needs changed

        sw        $a3, 0($s0)

        #
        # Restore S registers
        #
        lw        $s0, -4+FRAMESIZE_8($sp)
        addi      $sp, $sp, FRAMESIZE_8

        jr        $ra

#
# Function:        scrap_change_cell
# ---------------------------------------------------------
# Description:     Changes the value of a cell in scrap arr
#
# Arguments:       a0 - parameter block
#                      - address of colony array
#                      - address of scrap array
#                      - size of colony
#                  a1 - row to change
#                  a2 - col to change
#                  a3 - character to change to
#
scrap_change_cell:
        #
        # Save S registers
        #
        addi      $sp, $sp, -FRAMESIZE_8
        sw        $s0, -4+FRAMESIZE_8($sp)
        
        lw        $t0, 8($a0)                
        mul       $s0, $a1, $t0
        add       $s0, $s0, $a2
        mul       $s0, $s0, 4                # Get offset from colony address

        lw        $t0, 4($a0)
        add       $s0, $s0, $t0              # s0 = address that needs changed

        sw        $a3, 0($s0)

        #
        # Restore S registers
        #
        lw        $s0, -4+FRAMESIZE_8($sp)
        addi      $sp, $sp, FRAMESIZE_8

        jr        $ra

#
# Function:        colony_clear
# ---------------------------------------------------------
# Description:     Commit's mass genocide or initializes
#                  the colony
#
# Arguments:       a0 - address of colony array
#                  a1 - size of colony
#
colony_clear:
        #
        # Save S registers
        #
        addi      $sp, $sp, -FRAMESIZE_8
        sw        $s0, -4+FRAMESIZE_8($sp)
        sw        $s1, -8+FRAMESIZE_8($sp)

        addi      $s0, $a0, 0
        addi      $s1, $a1, 0
        mul       $s1, $s1, $s1        # s1 = number of cells to clear
        
colony_clear_loop:
        slti     $t0, $s1, 1           
        bne      $t0, $zero, colony_clear_done
        
        li       $t0, COLONY_CLEAR     # clear cell
        sw       $t0, 0($s0)

        addi     $s0, $s0, 4
        addiu    $s1, $s1, -1          # s1--

        j        colony_clear_loop
        
colony_clear_done:
        #
        # Restore S registers
        #
        lw       $s0, -4+FRAMESIZE_8($sp)
        lw       $s1, -8+FRAMESIZE_8($sp)
        addi     $sp, $sp, FRAMESIZE_8

        jr       $ra


#
# Function:        colony_copy
# ---------------------------------------------------------
# Description:     Copies one colony to another
# 
# Arguments:       a0 - address of colony to copy to
#                  a1 - address of colony to copy from
#                  a2 - size of colony
#
colony_copy:
        #
        # Save S registers
        #
        addi    $sp, $sp, -FRAMESIZE_12
        sw      $s0, -4+FRAMESIZE_12($sp)
        sw      $s1, -8+FRAMESIZE_12($sp)
        sw      $s2, -12+FRAMESIZE_12($sp)

        addi    $s0, $a0, 0
        addi    $s1, $a1, 0
        mul     $s2, $a2, $a2          # s1 = number of cells to copy

colony_loop:
        slti    $t0, $s2, 1
        bne     $t0, $zero, colony_copy_done

        lw      $t0, 0($s1)
        sw      $t0, 0($s0)            # copy cell

        addi    $s0, $s0, 4
        addi    $s1, $s1, 4
        addiu   $s2, $s2, -1

        j       colony_loop

colony_copy_done:
        #
        # Restore S registers
        #
        lw      $s0, -4+FRAMESIZE_12($sp)
        lw      $s1, -8+FRAMESIZE_12($sp)
        lw      $s2, -12+FRAMESIZE_12($sp)
        addi    $sp, $sp, FRAMESIZE_12

        jr      $ra

#
# Function:        colony_print
# ---------------------------------------------------------
# Description:     Prints out the grid
#
# Arguments:       a0 - parameter block
#                      - address of colony array
#                      - address of scrap array
#                      - size of colony
#                  a1 - current generation
#
colony_print:
        #
        # Save S registers
        #
        addi       $sp, $sp, -FRAMESIZE_16
        sw         $s0, -4+FRAMESIZE_16($sp)
        sw         $s1, -8+FRAMESIZE_16($sp)
        sw         $s7, -12+FRAMESIZE_16($sp)
        sw         $a0, -16+FRAMESIZE_16($sp)
        
        addi       $s0, $a0, 0

        #
        # Print generation banner
        #
        la         $a0, generation_banner_start
        addi       $v0, $zero, PRINT_STRING
        syscall

        addi       $a0, $a1, 0
        addi       $v0, $zero, PRINT_INT
        syscall

        la         $a0, generation_banner_end
        addi       $v0, $zero, PRINT_STRING
        syscall

        la         $s7, colony_print_array

        #
        # Print border
        #
colony_print_border:
        lw         $s1, 8($s0)
        
        li         $a0, 43                   # a0 = '+'
        addi       $v0, $zero, PRINT_CHAR
        syscall

colony_print_border_loop:
        slti       $t0, $s1, 1
        bne        $t0, $zero, colony_print_border_done
        
        li         $a0, 45                   # a0 = '-'
        addi       $v0, $zero, PRINT_CHAR
        syscall

        addi       $s1, $s1, -1

        j          colony_print_border_loop

colony_print_border_done:
        li         $a0, 43                   # a0 = '+'
        addi       $v0, $zero, PRINT_CHAR
        syscall

        li         $a0, 10                   # a0 = '\n'
        addi       $v0, $zero, PRINT_CHAR
        syscall

        jr         $s7

        #
        # Print array with | separators
        #
colony_print_array:
        lw         $s2, 8($s0)
        lw         $s7, 0($s0)

colony_print_array_start:
        slti       $t0, $s2, 1
        bne        $t0, $zero, colony_print_array_loop_done

        lw         $s1, 8($s0)
        
        li         $a0, 124                  # a0 = '|'
        addi       $v0, $zero, PRINT_CHAR
        syscall

colony_print_array_loop:
        slti       $t0, $s1, 1
        bne        $t0, $zero, colony_print_array_loop_break

        lw         $a0, 0($s7)
        addi       $v0, $zero, PRINT_CHAR
        syscall

        addi       $s7, $s7, 4
        addiu      $s1, $s1, -1

        j          colony_print_array_loop

colony_print_array_loop_break:
        li         $a0, 124                  # a0 = '|'
        addi       $v0, $zero, PRINT_CHAR
        syscall

        li         $a0, 10                   # a0 = '\n'
        addi       $v0, $zero, PRINT_CHAR
        syscall

        addiu      $s2, $s2, -1

        j          colony_print_array_start

colony_print_array_loop_done:
        la         $s7, colony_print_done
        j          colony_print_border # Print lower border

colony_print_done:
        #
        # Restore S registers
        #
        lw         $s0, -4+FRAMESIZE_16($sp)
        lw         $s1, -8+FRAMESIZE_16($sp)
        lw         $s7, -12+FRAMESIZE_16($sp)
        lw         $a0, -16+FRAMESIZE_16($sp)
        addi       $sp, $sp, FRAMESIZE_16
        
        jr         $ra

