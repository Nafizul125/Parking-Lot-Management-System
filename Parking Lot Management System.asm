.MODEL SMALL
.STACK 100H

.DATA
    parking      DW 10 DUP(0)    
    start_hours  DB 10 DUP(0)   
    
    
    menu         DB 13,10,'===== PARKING LOT MENU =====',13,10
                 DB '1. Vehicle Entry',13,10
                 DB '2. Slot Status Display',13,10
                 DB '3. Vehicle Exit (Fee Calc)',13,10
                 DB '4. Exit Program',13,10
                 DB 'Choose Option (1-4): $'
    
    prompt_veh   DB 13,10,'Enter vehicle number (max 3 digits): $'
    prompt_hour  DB 13,10,'Enter start hour (0-23): $'
    prompt_slot  DB 13,10,'Enter slot number (0-9): $'
    prompt_exit_h DB 13,10,'Enter exit hour (0-23): $'
    
   
    msg_invalid_veh  DB 13,10,'Invalid vehicle number!$'
    msg_invalid_hour DB 13,10,'Invalid hour! Must be 0-23.$'
    msg_invalid_slot_input DB 13,10,'Invalid slot (0-9).$'
    msg_already_parked DB 13,10,'Vehicle already in another slot!$'
    msg_slot_occupied DB 13,10,'Slot already occupied!$'
    msg_success  DB 13,10,'Vehicle parked successfully in slot $'
    msg_no_veh   DB 13,10,'No Vehicle found in this slot!$'
    msg_mismatch DB 13,10,'Vehicle number not matched!$'
    msg_time_err DB 13,10,'False: Exit time must be > entry time!$'
    
    
    msg_duration DB 13,10,'Total Occupied Time: $'
    msg_fee      DB ' hours.',13,10,'Total Parking Fee (50 TK/hr): $'
    msg_tk       DB ' TK.$'
    
    slot_header  DB 13,10,'Slot Status (1=Full, 0=Empty):',13,10,'$'
    zero_char    DB '0 $'
    one_char     DB '1 $'
    newline      DB 13,10,'$'
    msg_exit     DB 13,10,'Program Ended.$'
    msg_invalid_choice DB 13,10,'Invalid choice.$'
    msg_dot      DB '.$'
    
    
    buffer       DB 6 DUP('$')
    vehicle_no   DW 0
    slot_no      DB 0
    start_hour   DB 0
    exit_hour    DB 0
    duration     DW 0
    total_fee    DW 0

.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX

main_loop:
    LEA DX, menu
    MOV AH, 09H
    INT 21H
    
    MOV AH, 01H
    INT 21H
    
    CMP AL, '1'
    JE choice1
    CMP AL, '2'
    JE choice2
    CMP AL, '3'
    JE choice3
    CMP AL, '4'
    JE choice4
    
    LEA DX, msg_invalid_choice
    MOV AH, 09H
    INT 21H
    JMP main_loop

choice1:
    CALL vehicle_entry
    JMP main_loop

choice2:
    CALL slot_status
    JMP main_loop

choice3:
    CALL vehicle_exit
    JMP main_loop

choice4:
    LEA DX, msg_exit
    MOV AH, 09H
    INT 21H
    MOV AX, 4C00H
    INT 21H

MAIN ENDP

;Vehicle Entry
vehicle_entry PROC
    LEA DX, prompt_veh
    MOV AH, 09H
    INT 21H
    CALL read_number
    MOV vehicle_no, AX
    
    CMP vehicle_no, 0
    JE invalid_vehicle
    
    MOV CX, 10
    MOV SI, 0
check_existing:
    MOV AX, parking[SI]
    CMP AX, vehicle_no
    JE already_parked
    ADD SI, 2
    LOOP check_existing
    
    LEA DX, prompt_hour
    MOV AH, 09H
    INT 21H
    CALL read_two_digit_number
    CMP AX, 23
    JA invalid_hour_input
    MOV start_hour, AL
    
    LEA DX, prompt_slot
    MOV AH, 09H
    INT 21H
    CALL read_one_digit_number
    CMP AX, 9
    JA invalid_slot_input
    MOV slot_no, AL
    
    ;Slot allocation
    MOV BL, slot_no
    MOV BH, 0
    MOV SI, BX
    SHL SI, 1
    MOV AX, parking[SI]
    CMP AX, 0
    JNE slot_occupied
    
    MOV AX, vehicle_no
    MOV parking[SI], AX
    MOV SI, BX
    MOV AL, start_hour
    MOV start_hours[SI], AL
    
    LEA DX, msg_success
    MOV AH, 09H
    INT 21H
    MOV DL, slot_no
    ADD DL, '0'
    MOV AH, 02H
    INT 21H
    LEA DX, msg_dot
    MOV AH, 09H
    INT 21H
    RET
    
invalid_vehicle:
    LEA DX, msg_invalid_veh
    MOV AH, 09H
    INT 21H
    RET
already_parked:
    LEA DX, msg_already_parked
    MOV AH, 09H
    INT 21H
    RET
invalid_hour_input:
    LEA DX, msg_invalid_hour
    MOV AH, 09H
    INT 21H
    RET
invalid_slot_input:
    LEA DX, msg_invalid_slot_input
    MOV AH, 09H
    INT 21H
    RET
slot_occupied:
    LEA DX, msg_slot_occupied
    MOV AH, 09H
    INT 21H
    RET
vehicle_entry ENDP

;Slot display
slot_status PROC
    LEA DX, slot_header
    MOV AH, 09H
    INT 21H
    MOV CX, 10
    MOV SI, 0
slot_loop:
    MOV AX, parking[SI]
    CMP AX, 0
    JE print_zero
    LEA DX, one_char
    MOV AH, 09H
    INT 21H
    JMP next_slot
print_zero:
    LEA DX, zero_char
    MOV AH, 09H
    INT 21H
next_slot:
    ADD SI, 2
    LOOP slot_loop
    LEA DX, newline
    MOV AH, 09H
    INT 21H
    RET
slot_status ENDP


vehicle_exit PROC
    LEA DX, prompt_slot
    MOV AH, 09H
    INT 21H
    CALL read_one_digit_number
    MOV slot_no, AL
    
    
    MOV BL, slot_no
    MOV BH, 0
    MOV SI, BX
    SHL SI, 1
    MOV AX, parking[SI]
    CMP AX, 0
    JE no_vehicle
    
    
    LEA DX, prompt_veh
    MOV AH, 09H
    INT 21H
    CALL read_number
    MOV DX, parking[SI]
    CMP AX, DX
    JNE mismatch
    
    
    LEA DX, prompt_exit_h
    MOV AH, 09H
    INT 21H
    CALL read_two_digit_number
    MOV exit_hour, AL
    
    
    MOV SI, BX
    MOV AL, exit_hour
    SUB AL, start_hours[SI]
    JS time_error 
    
    MOV AH, 0
    MOV duration, AX
    
    ;Fee calc
    MOV DX, 50
    MUL DX
    MOV total_fee, AX
    
    
    LEA DX, msg_duration
    MOV AH, 09H
    INT 21H
    MOV AX, duration
    CALL print_number
    
    LEA DX, msg_fee
    MOV AH, 09H
    INT 21H
    MOV AX, total_fee
    CALL print_number
    
    LEA DX, msg_tk
    MOV AH, 09H
    INT 21H
    
    
    MOV SI, BX
    SHL SI, 1
    MOV parking[SI], 0
    RET

no_vehicle:
    LEA DX, msg_no_veh
    MOV AH, 09H
    INT 21H
    RET
mismatch:
    LEA DX, msg_mismatch
    MOV AH, 09H
    INT 21H
    RET
time_error:
    LEA DX, msg_time_err
    MOV AH, 09H
    INT 21H
    RET
vehicle_exit ENDP


print_number PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    MOV CX, 0
    MOV BX, 10
p_loop1:
    MOV DX, 0
    DIV BX
    PUSH DX
    INC CX
    CMP AX, 0
    JNE p_loop1
p_loop2:
    POP DX
    ADD DL, '0'
    MOV AH, 02H
    INT 21H
    LOOP p_loop2
    POP DX
    POP CX
    POP BX
    POP AX
    RET
print_number ENDP

read_number PROC
    PUSH BX
    PUSH CX
    PUSH DX
    MOV CX, 0
    MOV BX, 0
r_digit:
    MOV AH, 01H
    INT 21H
    CMP AL, 13
    JE r_done
    CMP AL, '0'
    JB r_done
    CMP AL, '9'
    JA r_done
    SUB AL, '0'
    MOV AH, 0
    PUSH AX
    MOV AX, BX
    MOV DX, 10
    MUL DX
    MOV BX, AX
    POP AX
    ADD BX, AX
    INC CX
    CMP CX, 3
    JB r_digit
r_done:
    MOV AX, BX
    POP DX
    POP CX
    POP BX
    RET
read_number ENDP

read_two_digit_number PROC
    PUSH BX
    PUSH CX
    PUSH DX
    MOV CX, 0
    MOV BX, 0
rt_digit:
    MOV AH, 01H
    INT 21H
    CMP AL, 13
    JE rt_done
    CMP AL, '0'
    JB rt_done
    CMP AL, '9'
    JA rt_done
    SUB AL, '0'
    MOV AH, 0
    PUSH AX
    MOV AX, BX
    MOV DX, 10
    MUL DX
    MOV BX, AX
    POP AX
    ADD BX, AX
    INC CX
    CMP CX, 2
    JB rt_digit
rt_done:
    MOV AX, BX
    POP DX
    POP CX
    POP BX
    RET
read_two_digit_number ENDP

read_one_digit_number PROC
    MOV AH, 01H
    INT 21H
    CMP AL, '0'
    JB r1_done
    CMP AL, '9'
    JA r1_done
    SUB AL, '0'
    MOV AH, 0
    RET
r1_done:
    MOV AX, 0
    RET
read_one_digit_number ENDP

END MAIN