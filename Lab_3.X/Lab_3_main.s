# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# * Programmer:	    Jerome Santos			                     *
# * SID:	    011555815						     *
# * Date:	    02/2/17						     *
# * OS Used:	    Windows 7						     *
# * Language:       Assembly MIPS32					     *
# * Course:	    EE234--Microprocessor Systems			     *
# * Term:	    Spring 2017						     *
# * Assignment:	    Lab 3--Calculator					     *
# * Description:    Program designed to mimic a simple calculator utilizing  *
# *		    the ChipKIT Pro MX4 board, PmodSWT, and PmodKYPD. The    *
# *		    keypad and switches are used as inputs. The keypad is    *
# *		    used to enter the operands, and the different switch     *
# *		    states represent the different operators (+,-,*,/,etc...)*
# *		    The results are displayed on the LEDs in binary.	     *
# * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ------------------------------ GLOBAL main ------------------------------- #
.GLOBAL main
    
# ---------------------------------- DATA ---------------------------------- #
.DATA
operator:   .word   0	# Operator based on the switch configuration
operand1:   .word   0	# First operand from the keypad
operand2:   .word   0	# Second operand from the keypad (if binary operation)
result:	    .word   0	# Result of the operation performed on operand 1 & 2
    
# ---------------------------------- TEXT ---------------------------------- #
.TEXT
    
# ---------------------------------- main ---------------------------------- #
.ENT main
main:
    
    JAL setupSwitches   # Setup the switches as inputs
    JAL setupKYPD	# Setup the KYPD as input
    JAL setupLEDs	# Setup the LEDs as outputs
    
    loop:
    
	# Read the switches to determine which operation is being used
	JAL readSwitches    # Reads the state the switches are in
	JAL delayTime	    # Delay small amount of time
	
	# Reads the first operand from the user
	JAL readKYPD	    # Reads the state the keypad is in
	MOVE $a0, $v1	    # Sets operand 1 to $a0
	JAL writeLEDs	    # Writes to the LEDs the keypad that is pressed
	JAL delayTime	    # Delay small amount of time
	JAL clearLEDs	    # Sets LEDs to off
	
	# Checking if switches are unary or binary operations
	LI $v1, 0b1001
	BEQ $v0, $v1, performCalc
	LI $v1, 0b1010
	BEQ $v0, $v1, performCalc
	LI $v1, 0b1011
	BEQ $v0, $v1, performCalc
	LI $v1, 0b1100
	BEQ $v0, $v1, performCalc
	LI $v1, 0b1101
	BEQ $v0, $v1, performCalc
	
	# Reads the second operand from the user if binary operation
	JAL readKYPD	    # Reads the state the keypad is in
	MOVE $a1, $v1	    # Sets operand 2 to $a1
	JAL writeLEDs	    # Writes to the LEDs the keypad that is pressed
	JAL delayTime	    # Delay small amount of time
	JAL clearLEDs	    # Sets LEDs to off
	
	performCalc:
    
	    JAL delayTime   # Delay small amount of time
	    JAL calculate   # Performs calculation based on switch state
	    JAL writeLEDs   # Writes to the LEDs the result of the operation
	    JAL delayTime   # Delay small amount of time
	    JAL clearLEDs   # Sets LEDs to off
	
    J loop  # Embedded systems run forever. Jumps back to beginning of loop
    
.END main   # End of main function

# -------------------------------- Functions ------------------------------- #
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# * Function:	    setupSwitches                                            *
# * Description:    Function designed to setup the PmodSWT as an input for   *
# *		    different operators.                                     *
# * Inputs:	    None                                                     *
# * Outputs:	    None						     *
# * Computations:   None                                                     *
# * Reg used:	    $t0				                             *
# * Reg Preserved:  None				                     *
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.ENT setupSwitches
setupSwitches:
    
    LI $t0, 0x0080
    SW $t0, TRISESET	# Set as inputs
    LI $t0, 0x1081
    SW $t0, TRISDSET	# Set as inputs
    
    JR $ra
    
.END setupSwitches    
    
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# * Function:	    setupKYPD						     *
# * Description:    Function designed to setup the PmodKYPD as an input for  *
# *		    operands 1 & 2.					     *
# * Inputs:	    None                                                     *
# * Outputs:	    None						     *
# * Computations:   None                                                     *
# * Reg used:	    $t0				                             *
# * Reg Preserved:  None				                     *
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.ENT setupKYPD
setupKYPD:
    
    LI $t0, 0x00F0
    SW $t0, TRISESET	# Rows 1 - 4
    LI $t0, 0x000F
    SW $t0, TRISECLR	# Columns 1 - 4
    SW $t0, LATESET
	
    JR $ra
	
.END setupKYPD
	
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# * Function:	    setupLEDs						     *
# * Description:    Function designed to setup the on board LEDs as outputs. *
# * Inputs:	    None                                                     *
# * Outputs:	    None						     *
# * Computations:   None                                                     *
# * Reg used:	    $t0				                             *
# * Reg Preserved:  None				                     *
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.ENT setupLEDs
setupLEDs:
    
    LI $t0, 0x3C00
    SW $t0, TRISBCLR	# Set as output
    SW $t0, LATBCLR	# Set as output
    
    JR $ra
    
.END setupLEDs
    
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# * Function:	    readSwitches					     *
# * Description:    Function designed to capture the value of the switches   *
# *		    (on = 1, off = 0), shift them appropriately and bitwise  *
# *		    ORs them to produce a 4 bit long integer.		     *
# * Inputs:	    PORTE, PORTD                                             *
# * Outputs:	    Binary number					     *
# * Computations:   None                                                     *
# * Reg used:	    $t0, $v0				                     *
# * Reg Preserved:  $v0					                     *
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.ENT readSwitches
readSwitches:
    
    # Let's use $v0 as switch_state
    MOVE $v0, $zero
    
    # Read switch 1
    LW $t0, PORTE
    SRL $t0, $t0, 8
    ANDI $t0, $t0, 0x1
    OR $v0, $v0, $t0
    
    # Read switch 2
    LW $t0, PORTD
    SLL $t0, $t0, 1
    ANDI $t0, $t0, 0x2
    OR $v0, $v0, $t0
    
    # Read switch 3
    LW $t0, PORTD
    SRL $t0, $t0, 6
    ANDI $t0, $t0, 0x4
    OR $v0, $v0, $t0
    
    # Read switch 4
    LW $t0, PORTD
    SRL $t0, $t0, 10
    ANDI $t0, $t0, 0x8
    OR $v0, $v0, $t0
    
    JR $ra
    
.END readSwitches

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# * Function:	    readKYPD						     *
# * Description:    Function designed to capture the value of the keypad     *
# *		    based on the key pressed, and saves that value in binary.*
# * Inputs:	    PORTE, PORTD                                             *
# * Outputs:	    Binary number					     *
# * Computations:   None                                                     *
# * Reg used:	    $t0, $t1, $t2, $v1				             *
# * Reg Preserved:  $v1					                     *
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.ENT readKYPD
readKYPD:
    
    # Let's use $t0 as keypad_state
    # Let's use $t1 as keypad_temp
	
    # Reading Column 4
    MOVE $t0, $zero	    # Zero out the register
    
    LI $t2, 0b1110
    SW $t2, LATESET
    LI $t2, 0b0001
    SW $t2, LATECLR
	
    LW $t1, PORTE
    ANDI $t1, $t1, 0x00F0   # keypad_temp = (PORTE & 0xF0)
	
    # Checking KYPD for button A press
    ANDI $t2, $t1, 0x0080
    BEQZ $t2, APressed
    J ANotPressed
	
    APressed:
	ORI $t0, $t0, 0x000A
	    
    ANotPressed:
    
    # Checking KYPD for button B press
    ANDI $t2, $t1, 0x0040
    BEQZ $t2, BPressed
    J BNotPressed
	
    BPressed:
	ORI $t0, $t0, 0x000B
	    
    BNotPressed:
    
    # Checking KYPD for button C press
    ANDI $t2, $t1, 0x0020
    BEQZ $t2, CPressed
    J CNotPressed
	
    CPressed:
	ORI $t0, $t0, 0x000C
	    
    CNotPressed:
    
    # Checking KYPD for button D press
    ANDI $t2, $t1, 0x0010
    BEQZ $t2, DPressed
    J DNotPressed
	
    DPressed:
	ORI $t0, $t0, 0x000D
	    
    DNotPressed:
    
    # Reading Column 3
    LI $t2, 0b1101
    SW $t2, LATESET
    LI $t2, 0b0010
    SW $t2, LATECLR
	
    LW $t1, PORTE
    ANDI $t1, $t1, 0x00F0
	
    # Checking KYPD for button 3 press
    ANDI $t2, $t1, 0x0080
    BEQZ $t2, ThreePressed
    J ThreeNotPressed
	
    ThreePressed:
	ORI $t0, $t0, 0x0003
	    
    ThreeNotPressed:
    
    # Checking KYPD for button 6 press
    ANDI $t2, $t1, 0x0040
    BEQZ $t2, SixPressed
    J SixNotPressed
	
    SixPressed:
	ORI $t0, $t0, 0x0006
	    
    SixNotPressed:
    
    # Checking KYPD for button 9 press
    ANDI $t2, $t1, 0x0020
    BEQZ $t2, NinePressed
    J NineNotPressed
	
    NinePressed:
	ORI $t0, $t0, 0x0009
	    
    NineNotPressed:
    
    # Checking KYPD for button E press
    ANDI $t2, $t1, 0x0010
    BEQZ $t2, EPressed
    J ENotPressed
	
    EPressed:
	ORI $t0, $t0, 0x000E
	    
    ENotPressed:
    
    # Reading Column 2
    LI $t2, 0b1011
    SW $t2, LATESET
    LI $t2, 0b0100
    SW $t2, LATECLR
	
    LW $t1, PORTE
    ANDI $t1, $t1, 0x00F0
	
    # Checking KYPD for button 2 press
    ANDI $t2, $t1, 0x0080
    BEQZ $t2, TwoPressed
    J TwoNotPressed
	
    TwoPressed:
	ORI $t0, $t0, 0x0002
	    
    TwoNotPressed:
    
    # Checking KYPD for button 5 press
    ANDI $t2, $t1, 0x0040
    BEQZ $t2, FivePressed
    J FiveNotPressed
	
    FivePressed:
	ORI $t0, $t0, 0x0005
	    
    FiveNotPressed:
    
    # Checking KYPD for button 8 press
    ANDI $t2, $t1, 0x0020
    BEQZ $t2, EightPressed
    J EightNotPressed
	
    EightPressed:
	ORI $t0, $t0, 0x0008
	    
    EightNotPressed:
    
    # Checking KYPD for button F press
    ANDI $t2, $t1, 0x0010
    BEQZ $t2, FPressed
    J FNotPressed
	
    FPressed:
	ORI $t0, $t0, 0x000F
	    
    FNotPressed:
    
    # Reading Column 1
    LI $t2, 0b0111
    SW $t2, LATESET
    LI $t2, 0b1000
    SW $t2, LATECLR
	
    LW $t1, PORTE
    ANDI $t1, $t1, 0x00F0
	
    # Checking KYPD for button 1 press
    ANDI $t2, $t1, 0x0080
    BEQZ $t2, OnePressed
    J OneNotPressed
	
    OnePressed:
	ORI $t0, $t0, 0x0001
	    
    OneNotPressed:
    
    # Checking KYPD for button 4 press
    ANDI $t2, $t1, 0x0040
    BEQZ $t2, FourPressed
    J FourNotPressed
	
    FourPressed:
	ORI $t0, $t0, 0x0004
	    
    FourNotPressed:
    
    # Checking KYPD for button 7 press
    ANDI $t2, $t1, 0x0020
    BEQZ $t2, SevenPressed
    J SevenNotPressed
	
    SevenPressed:
	ORI $t0, $t0, 0x0007
	    
    SevenNotPressed:
    
    # Checking KYPD for button 0 press
    ANDI $t2, $t1, 0x0010
    BEQZ $t2, ZeroPressed
    J ZeroNotPressed
	
    ZeroPressed:
	ORI $t0, $t0, 0x0000
	    
    ZeroNotPressed:
    
    BEQZ $t0, readKYPD
    MOVE $v1, $t0
    
    JAL $ra
    
.END readKYPD

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# * Function:	    calculate						     *
# * Description:    Function designed to calculate a result based on the     *
# *		    operator chosen. (+, -, *, /, etc...)		     *
# * Inputs:	    operand 1 ($a0), operand 2 ($a1), operator ($v0)         *
# * Outputs:	    Binary number					     *
# * Computations:   None                                                     *
# * Reg used:	    $v0, $v1, $a0, $a1, $t0				     *
# * Reg Preserved:  None					             *
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.ENT calculate
calculate:
    
    LI $v1, 0b0000	# switch state 0b0000 = addition
    BEQ $v0, $v1, addition
    
    LI $v1, 0b0001	# switch state 0b0001 = subtraction
    BEQ $v0, $v1, subtraction
    
    LI $v1, 0b0010	# switch state 0b0010 = multiplication
    BEQ $v0, $v1, multiplication
    
    LI $v1, 0b0011	# switch state 0b0011 = division
    BEQ $v0, $v1, division
    
    LI $v1, 0b0100	# switch state 0b0100 = modulus
    BEQ $v0, $v1, modulus
    
    LI $v1, 0b0101	# switch state 0b0101 = bitwise AND
    BEQ $v0, $v1, bitwiseAND
    
    LI $v1, 0b0110    # switch state 0b0110 = bitwise OR
    BEQ $v0, $v1, bitwiseOR
    
    LI $v1, 0b0111    # switch state 0b0111 = bitwise NOR
    BEQ $v0, $v1, bitwiseNOR
    
    LI $v1, 0b1000    # switch state 0b1000 = bitwiseXOR
    BEQ $v0, $v1, bitwiseXOR
    
    LI $v1, 0b1001    # switch state 0b1001 = bitwiseNOT
    BEQ $v0, $v1, bitwiseNOT
    
    LI $v1, 0b1010    # switch state 0b1010 = shiftLeft
    BEQ $v0, $v1, shiftLeft
    
    LI $v1, 0b1011    # switch state 0b1011 = shiftRight
    BEQ $v0, $v1, shiftRight
    
    LI $v1, 0b1100    # switch state 0b1100 = rotateLeft
    BEQ $v0, $v1, rotateLeft
    
    LI $v1, 0b1101    # switch state 0b1101 = rotateRight
    BEQ $v0, $v1, rotateRight
    
    addition:
	ADD $t0, $a0, $a1
	J endCalculate
	
    subtraction:
	SUB $t0, $a0, $a1
	J endCalculate
	
    multiplication:
	MUL $t0, $a0, $a1
	J endCalculate
	
    division:
	DIV $a0, $a1
	MFLO $t0
	J endCalculate
	
    modulus:
	DIV $a0, $a1
	MFHI $t0
	J endCalculate
	
    bitwiseAND:
	AND $t0, $a0, $a1
	J endCalculate
	
    bitwiseOR:
	OR $t0, $a0, $a1
	J endCalculate
    
    bitwiseNOR:
	NOR $t0, $a0, $a1
	J endCalculate

    bitwiseXOR:
	XOR $t0, $a0, $a1
	J endCalculate
	
    bitwiseNOT:
	NOT $t0, $a0
	J endCalculate
	
    shiftLeft:
	SLL $t0, $a0, 1
	J endCalculate
	
    shiftRight:
	SRL $t0, $a0, 1
	J endCalculate
	
    rotateLeft:
	ROTR $t0, $a0, 1
	J endCalculate
	
    rotateRight:
	ROTL $t0, $a0, 1
	J endCalculate
	
    endCalculate:
    
    JAL $ra
    
.END calculate

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# * Function:	    writeLEDs	    					     *
# * Description:    Function designed to display the binary representation   *
# *		    of operands 1 & 2, and the results of the calculate      *
# *		    function.						     *
# * Inputs:	    result ($t0)                                             *
# * Outputs:	    PORTB						     *
# * Computations:   None                                                     *
# * Reg used:	    $t0					                     *
# * Reg Preserved:  None					             *
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.ENT writeLEDs
writeLEDs:

    # Shifting and displaying to the LEDs
    SLL $t0, $t0, 10
    SW $t0, LATBSET
    
    JR $ra

.END writeLEDs

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# * Function:	    delayTime						     *
# * Description:    Function designed to loop through a specified number to  *
# *		    pass time. This function is used to allow time for the   *
# *		    user to see the LEDs being displayed.		     *
# * Inputs:	    Integer	                                             *
# * Outputs:	    None						     *
# * Computations:   decrement by 1                                           *
# * Reg used:	    $t0					                     *
# * Reg Preserved:  None					             *
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.ENT delayTime
delayTime:
    
    MOVE $t0, $zero
    LI $t0, 75000
    delayTimeLoop:
    
	ADDI $t0, $t0, -1	# Decrement by 1
	BNEZ $t0, delayTimeLoop	# Loop until count = 0
    
    JR $ra
    
.END delayTime
    
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# * Function:	    clearLEDs						     *
# * Description:    Function designed to set the LEDs back to 0 to clear it  *
# *		    for the next read					     *
# * Inputs:	    None	                                             *
# * Outputs:	    PORTB						     *
# * Computations:   None                                                     *
# * Reg used:	    $t0	    				                     *
# * Reg Preserved:  None					             *
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.ENT clearLEDs
clearLEDs:
    
    MOVE $t0, $zero
    LI $t0,0x3C00
    SW $t0, TRISBCLR
    SW $t0, LATBCLR	# Set LEDs to off
    
    JR $ra
    
.END clearLEDs
