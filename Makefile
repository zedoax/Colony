#
# Makefile for Project 1
#

#
# Location of the processing programs
#
RASM  = /home/fac/wrc/bin/rasm
RLINK = /home/fac/wrc/bin/rlink
RSIM  = /home/fac/wrc/bin/rsim

#
# Suffixes to be used or created
#
.SUFFIXES:	.asm .obj .lst .out

#
# Transformation rule: .asm into .obj
#
.asm.obj:
	$(RASM) -l $*.asm > $*.lst

#
# Transformation rule: .obj into .out
#
.obj.out:
	$(RLINK) -m -o $*.out $*.obj >$*.map

#
# Main target
#
colony.out:	colony.obj


run:	colony.obj
	- $(RSIM) colony.out

debug:	colony.obj
	- $(RSIM) -d colony.out
	
clean:
	rm *.obj *.lst *.out
