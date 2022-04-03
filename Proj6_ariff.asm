TITLE Low Level I/O Procedures     (Proj6_ariff.asm)

; Author: Faihaan Arif
; Last Modified: 12/6/21
; OSU email address: ONID_ID@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number:  6               Due Date: 12/6/21
; Description: Prompts user for 10 integers. Performs validation to ensure they are 32 bit integers. Then, numbers are displayed
;	as well as the sum and average

INCLUDE Irvine32.inc

; MACROS

; -- Name: mDisplayString --
; Displays string that is passed as an argument
; Receives: str = string variable
mDisplayString	MACRO	str
	PUSH	EDX
	MOV		EDX, str
	CALL	WriteString
	POP		EDX
ENDM

; -- Name: mGetString --
; Prompts user for input. Saves input in memory
; Receives: prompt = string variable, strinput = memory location, strmaxlength = max characters allowed, strilength = memory location
; Returns: strinput, strilength
mGetString		MACRO	prompt, strinput, strmaxlength, strilength
	mDisplayString	prompt
	PUSH			ECX
	PUSH			EDX
	PUSH			EAX
	MOV				EDX, strinput
	MOV				ECX, strmaxlength
	CALL			ReadString
	MOV				strilength, EAX
	POP				EAX
	POP				EDX
	POP				ECX

ENDM

.data

greeting	BYTE	"PROGRAMMING ASSIGNMENT 6: Designing low-level I/O procedures",13,10,0
author		BYTE	"Written by: Faihaan Arif",13,10,13,10,0
prompt		BYTE	"Please provide 10 signed decimal integers.",13,10,0
prompt2		BYTE	"Each number needs to be small enough to fit inside a 32 bit register. After you have finished inputting the raw numbers I will display a list of the ",0
prompt3		BYTE	"integers, their sum, and their average value.",13,10,13,10,0
prompt4		BYTE	"Please enter an signed number: ",0
error		BYTE	"ERROR: You did not enter a signed number or your number was too big.",13,10,0
prompt5		BYTE	"You entered the following numbers: ",13,10,0
comspace	BYTE	", ",0
prompt6		BYTE	"The sum of these numbers is: ",0
prompt7		BYTE	"The rounded average is: ",0
bye			BYTE	13,10,"Thanks for playing!",0

StrInput	BYTE	21 DUP(?)
StLength	DWORD	?
StOutput	BYTE	11 DUP(?)

Array		SDWORD	10 DUP(0)

.code
main PROC

	; introduction
	PUSH	OFFSET	greeting
	PUSH	OFFSET	author
	PUSH	OFFSET	prompt
	PUSH	OFFSET	prompt2
	PUSH	OFFSET	prompt3
	CALL	Introduction

	; prompt user for 10 integers and save in array
	MOV		ECX, LENGTHOF Array
	MOV		EDI, OFFSET Array
_fillArray:
	PUSH	OFFSET error
	PUSH	OFFSET Prompt4
	PUSH	OFFSET StrInput
	PUSH	SIZEOF StrInput
	PUSH	OFFSET StLength
	CALL	ReadVal
	MOV		[EDI], EBX
	ADD		EDI, 4
	LOOP	_fillArray

	CALL	Crlf
	mDisplayString	OFFSET prompt5

	; display list of integers
	SUB		EDI, SIZEOF Array
	MOV		ECX, 10
	MOV		EBX, 0				; sum counter
	_testloop:
	MOV		EAX, [EDI]
	ADD		EBX, EAX
	PUSH	OFFSET StOutput
	PUSH	EAX
	CALL	WriteVal
	ADD		EDI, 4
	CMP		ECX, 1
	JE		_last
	mDisplayString	OFFSET comspace
	_last:
	LOOP	_testloop

	; display sum
	PUSH	EBX
	CALL	Crlf
	mDisplayString	OFFSET prompt6
	PUSH	OFFSET StOutput
	PUSH	EBX
	CALL	WriteVal

	CALL	Crlf

	; calculate and display truncated average
	mDisplayString	OFFSET prompt7
	POP		EAX
	MOV		EBX, 10
	CDQ
	IDIV	EBX
	PUSH	OFFSET StOutput
	PUSH	EAX
	CALL	WriteVal

	;farewell
	CALL	Crlf
	mDisplayString	OFFSET bye

	Invoke ExitProcess,0	; exit to operating system
main ENDP


; --Name: Introduction--
; Displays welcome prompts
; Preconditions: prompts pushed to stack 
; Postconditions: EDX changed
; Receives: [EBP + 24], [EBP + 20], [EBP + 16], [EBP + 12], [EBP + 8] = strings
Introduction	PROC
	PUSH	EBP
	MOV		EBP, ESP
	mDisplayString	[EBP + 24]
	mDisplayString	[EBP + 20]
	mDisplayString	[EBP + 16]
	mDisplayString	[EBP + 12]
	mDisplayString	[EBP + 8]
	POP		EBP
	RET		20
Introduction ENDP

; -- Name: ReadVal --
; Converts string to numeric value representation
; Precondition: prompts, string input, string length locations pushed to stack
; Postconditions: EAX, EBX, EDX, ESI changed
; Receives: [EBP+20] = string prompt, [EBP+16] = StrInpui reference, [EBP+12] = sizeof StrInput, [EBP+8] = Length of string read
; Returns: EBX = signed integer
ReadVal	PROC
	PUSH	EBP
	MOV		EBP, ESP
	PUSH	ECX			; save outer loop counter
_begin:
	mGetString	[EBP+20], [EBP+16], [EBP+12], [EBP+8] 
	MOV		ESI, [EBP+16]
	MOV		ECX, [EBP+8]
	CMP		ECX, 11		; if greater than 11 characters, raise error
	MOV		EAX, 0
	MOV		EBX, 0
	JG		_error
	CLD
	; check if there is '-' or '+' sign in front of number
_signCheck:
	LODSB
	CMP		AL, 0		;if empty, raise error
	JE		_error
	CMP		AL, 45
	JE		_negSign
	MOV		EDX, 0
	PUSH	EDX
	CMP		AL, 43
	JE		_posSign
	JMP		_valid
	; EDX used as negative flag
_negSign:
	MOV		EDX, 1
	PUSH	EDX
_posSign:
	DEC		ECX
_continue:		
	LODSB
	; iterate through string input and validate/convert each character to integer
_valid:
	DEC		ECX
	CMP		AL, 0
	JE		_finish
	CMP		AL, 48
	JB		_error
	CMP		AL, 57
	JA		_error		
	SUB		AL, 48
	PUSH	ECX
	PUSH	EAX
	PUSH	EBX
	CMP		ECX, 0
	JE		_lastDigit
	; abc = a * 10^2 + b*10 + c
	_convert:
	MOV		EBX, 10
	MUL		EBX
	LOOP	_convert
_lastDigit:
	POP		EBX
	ADD		EBX, EAX
	POP		EAX
	POP		ECX
	JMP		_continue
_error:
	mDisplayString	[EBP+24]
	JMP		_begin
_finish:
	POP		EDX
	CMP		EDX, 1			; check negative 
	JNE		_cont
	NEG		EBX
_cont:
	POP		ECX
	POP		EBP
	RET		20
ReadVal ENDP

; -- Name: WriteVal --
; Converts signed integer to string and displays it
; Preconditions: integer and string location pushed to stack
; Receives: [EBP + 12] = string output reference, [EBP+8] = integer
WriteVal	PROC
	PUSH	EBP
	MOV		EBP, ESP
	PUSHAD

	MOV		EDI, [EBP + 12]		; string reference
	CLD
	MOV		EAX, [EBP+8]		; integer
	MOV		ECX, 1				; counter
	CMP		EAX, 0
	JG		_div
	; if negative, add '-' as first character
	NEG		EAX
	PUSH	EAX
	MOV		EAX, 45
	STOSB
	POP		EAX
	; divide by 10 to get digits starting from ones place and push all to stack
_div:
	MOV		EBX, 10
	CDQ
	IDIV	EBX
	CMP		EAX, 0
	JE		_done
	ADD		EDX, 48
	PUSH	EDX
	INC		ECX
	JMP		_div
_done:
	ADD		EDX, 48
	PUSH	EDX
	; fill string from stack
_fillString:
	POP		EAX
	STOSB
	LOOP	_fillString

	mDisplayString [EBP+12]

	; clear string for next use
	MOV		EDI, [EBP + 12]
	MOV		ECX, 10
	MOV		EAX, 0
_clearStr:
	STOSB
	LOOP	_clearStr

	POPAD
	POP		EBP
	RET		8
WriteVal ENDP
END main
