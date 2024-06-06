.global main
main:
/*
//////////////////////////////////////////////////////
//////////////////// Startup Menu ////////////////////
//////////////////////////////////////////////////////
*/

ldr r1, =welcome_string
mov r2, #welcome_string_len
bl sub_print_stdout			@ Print welcome_string to stdout
ldr r1, =welcome2_string
mov r2, #welcome2_string_len		
bl sub_print_stdout			@ Print welcome2_string to stdout
menu1_yn:
ldr r1, =confirm
mov r2, #99
bl sub_read_stdin			@ Read from stdin into confirm.
ldr r3, =menu1_toolong_string
ldr r4, =menu1_toolong_string_len
bl sub_verify_length			@ Use a subroutine to verify the input is only 1 character
cmp r5, #1				@ r5 is the output of the subroutine, 1 for success, 0 for failure
beq menu1_verify_char
bne menu1_yn
menu1_verify_char:			@ Verify the character in our input is correct.
ldrb r0, [r1]				@ Load the data stored at the address in r1 into r0
bl sub_to_uppercase			@ Convert to uppercase
cmp r0, #'Y'				@ If r0 is equal to 'Y', go to gamestart
beq parse_file
cmp r0, #'N'				@ If r0 is equal to 'N', go to exit
beq exit
cmp r0, #10				@ If r0 is newline, show an error message
beq menu1_nochar
cmp r0, #' '				@ If r0 is equal to ' ' (space), check the next character
addeq r1, r1, #1
beq menu1_verify_char
ldr r1, =menu1_tryagain_string		@ If not...
mov r2, #menu1_tryagain_string_len
bl sub_print_stdout			@ Print menu1_tryagain_string to stdout
b menu1_yn				@ Do the y/n input again
menu1_nochar:
ldr r1, =nochar_string
mov r2, #nochar_string_len
bl sub_print_stdout
b menu1_yn

/*
///////////////////////////////////////////////////////////////
//////////////////// Parsing the text file ////////////////////
///////////////////////////////////////////////////////////////
*/

parse_file:				@ Reads hangman words from the words file. Words are separated by newlines.
ldr r0, =parse_strings_file
mov r1, #0x42
mov r2, #640
mov r7, #5
svc #0					@ Make the "open file" system call on "./words"
cmp r0, #-1				@ If file was opened successfully
bne parse_file_noerr			@ Continue
ldr r1, =parse_error
mov r2, #parse_error_len
bl sub_print_stdout			@ Otherwise, print an error message
b exit					@ And end the program
parse_file_noerr:
ldr r1, =parse_all_strings
mov r2, #1023
mov r7, #3
svc #0					@ Read from th efile into parse_all_strings. The file descriptor is already stored in r0
ldr r1, =parse_all_strings_len
str r0, [r1]				@ Store the number of characters read (which is automatically stored in r0 by the read system call) into parse_all_strings_len
b gamestart				@ Start the game

/*
//////////////////////////////////////////////////////////
//////////////////// The hangman game ////////////////////
//////////////////////////////////////////////////////////
*/

gamestart:
ldr r1, =gamestart_string
mov r2, #gamestart_string_len
bl sub_print_stdout			@ Print gamestart_string to stdout
count_newlines:				@ Count the number of newlines in parse_all_strings
ldr r1, =parse_all_strings		@ Store the starting address in r1
ldr r2, =parse_all_strings_len
ldr r2, [r2]
sub r2, r2, #1
add r2, r2, r1				@ Store the finishing address in r2
mov r5, #0				@ Store the number of newlines read in r5
count_newlines_loop:
cmp r1, r2				@ If the loop is finished
beq start_hangman_string		@ Move on
ldrb r4, [r1]				@ Load the character from r1 into r4
cmp r4, #10				@ If that character is a newline
addeq r5, r5, #1			@ Increment r5
add r1, r1, #1				@ Move on to the next address
b count_newlines_loop
start_hangman_string:			@ Choose the word that we are going to use
mov r0, #0				@ Arguments for time
mov r1, #1
bl time
bl srand
bl rand
and r0, r0, r5				@ Generate a random number between 0 and the number of newlines in parse_all_strings
ldr r1, =parse_all_strings		@ Store the starting address in r1
ldr r2, =parse_all_strings_len
ldr r2, [r2]
add r2, r2, r1				@ Store the finishing address in r2
mov r4, #0				@ Store the number of newlines read
start_hangman_string_loop:
cmp r1, r2				@ If the loop is finished
beq count_newlines			@ Start over, as this should not happen
cmp r4, r0				@ If the next word is the one that was chosen
beq store_hangman_string		@ Move on
ldrb r3, [r1]				@ Load the character from r1 into r3
cmp r3, #10				@ If that character is a newline
addeq r4, r4, #1			@ Increment r4
add r1, r1, #1				@ Move on to the next address
b start_hangman_string_loop
store_hangman_string:			@ Take the chosen word from parse_all_strings and move it to hangman_string
ldr r2, =hangman_string
mov r3, #0				@ Store the number of characters read in r3
store_hangman_string_loop:
add r3, r3, #1				@ Increment r3
ldrb r4, [r1]				@ Load the character from r1 into r4
cmp r4, #10				@ If r4 is a newline
beq populate_mysterystring		@ Move on
cmp r4, #0				@ If r4 is null
beq populate_mysterystring		@ Move on
strb r4, [r2]				@ Store the character from r1 in r2
add r1, r1, #1
add r2, r2, #1				@ Increment both addresses
b store_hangman_string_loop
populate_mysterystring:
ldr r1, =hangman_string_len
str r3, [r1]				@ Store the number of characters read in the last part in hangman_string_len
mov r0, r3
ldr r1, =mystery_string
mov r2, #1
mov r3, #95
populate_mysterystring_loop:		@ Initialises the mystery string with "_"s
strb r3, [r1]
add r2, r2, #1
add r1, r1, #1
cmp r2, r0
blt populate_mysterystring_loop

game_loop:
ldr r1, =newline
mov r2, #1
bl sub_print_stdout
ldr r0, =guesses_remaining		@ Prints the correct hangman frame to stdout depending on number of guesses remaining.
ldr r0, [r0]
cmp r0, #6
ldreq r1, =hangman_state_0
moveq r2, #hangman_state_0_len
beq print_frame
cmp r0, #5
ldreq r1, =hangman_state_1
moveq r2, #hangman_state_1_len
beq print_frame
cmp r0, #4
ldreq r1, =hangman_state_2
moveq r2, #hangman_state_2_len
beq print_frame
cmp r0, #3
ldreq r1, =hangman_state_3
moveq r2, #hangman_state_3_len
beq print_frame
cmp r0, #2
ldreq r1, =hangman_state_4
moveq r2, #hangman_state_4_len
beq print_frame
cmp r0, #1
ldreq r1, =hangman_state_5
moveq r2, #hangman_state_5_len
beq print_frame
cmp r0, #0
ldreq r1, =hangman_state_6
moveq r2, #hangman_state_6_len
beq print_frame
print_frame:
bl sub_print_stdout
ldr r1, =mystery_string
ldr r2, =hangman_string_len
ldr r2, [r2]
bl sub_print_stdout			@ Print mystery_string to stdout. It does not have a length value associated with it, but it should always have the same length as hangman_string
ldr r1, =newline
mov r2, #1
bl sub_print_stdout			@ Print a newline to stdout
ldr r1, =guesses_remaining_string
mov r2, #guesses_remaining_string_len
bl sub_print_stdout
ldr r0, =guesses_remaining
ldrb r0, [r0]
add r0, r0, #48				@ Convert guesses_remaining to ascii character (ascii 48 = "0")
ldr r1, =num_format_string		@ num_format_string stores the character form of an integer
strb r0, [r1]				
mov r2, #1
bl sub_print_stdout
ldr r1, =newline
mov r2, #1
bl sub_print_stdout
ldr r1, =incorrect_guesses_string
mov r2, #incorrect_guesses_string_len
bl sub_print_stdout			@ Print incorrect_guesses_string to stdout
ldr r0, =incorrect_guesses
mov r3, #1
print_incorrect_guesses_loop:
ldrb r4, [r0]				@ Load the character stored at r0 into r4
cmp r4, #0				@ If it is null,
beq print_incorrect_guesses_end		@ End the loop
cmp r3, #1				@ If it is the first character
moveq r3, #0
beq print_incorrect_guesses_1		@ Do not print the comma separator
ldr r1, =incorrect_guesses_separator
mov r2, #incorrect_guesses_separator_len
bl sub_print_stdout			@ Print incorrect_guesses_separator to stdout
print_incorrect_guesses_1:
mov r1, r0
mov r2, #1
bl sub_print_stdout			@ Print the character currently stored in r0 to stdout 
add r0, #1
b print_incorrect_guesses_loop

check_for_win:				@ Check if the game has been won
ldr r0, =mystery_string
ldr r2, =hangman_string_len
ldr r2, [r2]
add r1, r0, r2				@ Store the finishing address in r1
check_win_loop:
cmp r0, r1				@ If the loop is finished
beq game_won				@ The game has been won
ldrb r2, [r0]
cmp r2, #'_'				@ If the current character is _
bxeq lr					@ End the loop and return
add r0, r0, #1
b check_win_loop
check_for_loss:				@ Check if the game has been lost
ldr r0, =guesses_remaining
ldr r1, [r0]
cmp r1, #0				@ If there are no guesses remaining
beq game_lost				@ The game has been lost
bx lr					@ If not, return
game_won:
ldr r1, =game_won_string
mov r2, #game_won_string_len
bl sub_print_stdout
ldr r1, =hangman_string
ldr r2, =hangman_string_len
ldr r2, [r2]
bl sub_print_stdout			
ldr r1, =newline
mov r2, #1
bl sub_print_stdout			@ Print a message, hangman_string, and then a newline
b gameend
game_lost:
ldr r1, =game_lost_string
mov r2, #game_lost_string_len
bl sub_print_stdout
ldr r1, =hangman_string
ldr r2, =hangman_string_len
ldr r2, [r2]
bl sub_print_stdout
ldr r1, =newline
mov r2, #1
bl sub_print_stdout
b gameend

print_incorrect_guesses_end:
ldr r1, =newline
mov r2, #1
bl sub_print_stdout			@ Print a newline to stdout
bl check_for_win
bl check_for_loss
ldr r1, =guess_prompt_string
mov r2, #guess_prompt_string_len
bl sub_print_stdout			@ Print guess_prompt_string to stdout
guess_prompt:
ldr r1, =confirm			@ Reusing the input buffer from the start menu
mov r2, #99
bl sub_read_stdin			@ Read into confirm from stdin
ldr r3, =game_toolong_string
mov r4, #game_toolong_string_len
bl sub_verify_length			@ Verify length of the input
cmp r5, #0				@ If verification fails
beq guess_prompt			@ Print an error message (done in the subroutine) and prompt a guess again
guess_prompt_verify:
ldrb r0, [r1]
cmp r0, #10				@ If the character from r1 is a newline
beq guess_prompt_nochar			@ There are no characters in the input
cmp r0, #' '				@ If it is a space
addle r1, r1, #1
ble guess_prompt_verify			@ Ignore it and continue
bl sub_to_uppercase			@ Convert the character to uppercase
cmp r0, #'0'				@ If the character is 0
beq exit				@ Close the game
cmp r0, #'1'				@ If it is 1
beq reveal_letter			@ Reveal a letter
cmp r0, #'2'				@ If it is 2
beq restart				@ Restart the game
cmp r0, #'A'				@ If it is less than A
blt guess_prompt_fail			@ Verification failed
cmp r0, #'Z'				@ If it is greater than Z
bgt guess_prompt_fail			@ Ditto
b check_already_guessed			@ If verification succeeds, check if the character has already been guessed
guess_prompt_fail:
ldr r1, =game_tryagain_string
mov r2, #game_tryagain_string_len
bl sub_print_stdout			@ Print an error message
b guess_prompt				@ Prompt for another guess
guess_prompt_nochar:
ldr r1, =nochar_string
mov r2, #nochar_string_len
bl sub_print_stdout			@ Ditto
b guess_prompt
check_already_guessed:
ldr r1, =mystery_string
ldr r2, =incorrect_guesses
mov r3, #0				@ Number of characters read
ldr r4, =num_incorrect_guesses
ldr r4, [r4]
ldr r7, =hangman_string_len
ldr r7, [r7]
check_already_guessed_loop:
cmp r3, r7				@ If the loop is finished
beq check_guess				@ Move on
add r3, r3, #1
ldrb r5, [r1]				@ Load a character from mystery_string
ldrb r6, [r2]				@ Load a character from incorrect_guesses
cmp r5, r0				@ If the character in r5 is the same as the guess
beq already_guessed			@ It has already been guessed
add r1, r1, #1				@ Increment the address in r1
cmp r3, r4				@ If we have read all of the incorrect guesses
bgt check_already_guessed_loop		@ This is where the loop ends
cmp r6, r0				@ If not, then if the character in r6 is the same as the guess
beq already_guessed			@ It has already been guessed
add r2, r2, #1				@ Increment the addresss in r2
b check_already_guessed_loop
already_guessed:
ldr r1, =game_alreadyguessed_string
mov r2, #game_alreadyguessed_string_len
bl sub_print_stdout			@ Print an error message
b guess_prompt				@ Prompt for another guess

check_guess:
mov r3, #0				@ Store the number of characters read in r3
ldr r1, =hangman_string			
ldr r6, =hangman_string_len
ldr r6, [r6]
check_guess_loop:
cmp r3, r6				@ If the loop is finished
beq check_guess_incorrect		@ Move on
ldrb r2, [r1]				@ Load the character from hangman_string into r2
cmp r2, r0				@ If it is the same as the guess
beq check_guess_correct			@ The guess is correct, move on
add r3, r3, #1				@ Increment r3
add r1, r1, #1				@ Increment the address in r1
b check_guess_loop
check_guess_correct:
ldr r4, =mystery_string			
add r4, r4, r3				@ Go to the address in mystery_string where check_guess_loop stopped
strb r2, [r4]				@ Store the character at r2 in r4
check_guess_correct_loop:
cmp r3, r6				@ If the loop is finished
beq game_loop				@ Move on
add r4, r4, #1				@ Increment the address in r4
add r1, r1, #1				@ Increment the address in r1
add r3, r3, #1				@ Increment r3
ldrb r5, [r1]				@ Load the character from r1 in r5
cmp r5, r2				@ If it is not the same as the character from the same index in mystery_string
bne check_guess_correct_loop		@ End the loop here
strb r2, [r4]				@ If they are the same, store the character at r2 in r4
b check_guess_correct_loop
check_guess_incorrect:
ldr r1, =incorrect_guesses
ldr r2, =num_incorrect_guesses
ldr r3, [r2]
add r4, r3, #1				@ Add 1 to num_incorrect_guesses and store in r4
add r3, r3, r1				@ Store the address of the next incorrect guess in r3
strb r0, [r3]				@ Store the guess at the address in r3
str r4, [r2]				@ Store r4 at num_incorrect_guesses
ldr r3, =guesses_remaining
ldr r4, [r3]
sub r4, #1
str r4, [r3]				@ Decrease guesses_remaining by 1
b game_loop

reveal_letter:				@ Reveals a random letter at the cost of 2 guesses
ldr r0, =guesses_remaining
ldr r1, [r0]
cmp r1, #2				@ If there aren't enough guesses, print an error message and go back to the beginning
bgt reveal_continue
ldr r1, =game_revealletter_noguesses_string
mov r2, #game_revealletter_noguesses_string_len
bl sub_print_stdout
b game_loop
reveal_continue:
sub r1, r1, #2
str r1, [r0]				@ Decrease guesses_remaining by 2
reveal_random:
mov r0, #0				@ Arguments for time
mov r1, #0
bl time
bl srand
bl rand
ldr r1, =hangman_string_len
ldr r1, [r1]
sub r1, r1, #1
and r0, r0, r1				@ Generate a random number between 0 and (hangman_string_len - 1)
ldr r1, =hangman_string
add r0, r1, r0				@ Get the address of a random character in hangman_string
ldrb r0, [r0]				@ Load that character into r0
ldr r1, =mystery_string
mov r2, #0				@ Store number of characters read in r2
ldr r4, =hangman_string_len
ldr r4, [r4]
reveal_loop:
cmp r2, r4				@ If the loop is finished
beq check_guess				@ Move on
ldrb r3, [r1]				@ Load the character at r1 into r3
cmp r3, r0				@ If it is the same as the randomly selected character
beq reveal_random			@ Try again, as this letter has already been guessed
add r1, r1, #1				@ Increment the address in r1
add r2, r2, #1				@ Increment r2
b reveal_loop

/*
////////////////////////////////////////////////////////
//////////////////// After the game ////////////////////
////////////////////////////////////////////////////////
*/

gameend:
ldr r1, =gameend_string
mov r2, #gameend_string_len
bl sub_print_stdout			@ Print gameend_string to stdout
menu2_yn:
ldr r1, =confirm
mov r2, #99
bl sub_read_stdin			@ Read from stdin into confirm.
ldr r3, =menu1_toolong_string
ldr r4, =menu1_toolong_string_len
bl sub_verify_length			@ Use a subroutine to verify the input is only 1 character
cmp r5, #1				@ r5 is the output of the subroutine, 1 for success, 0 for failure
beq menu2_verify_char
bne menu2_yn
menu2_verify_char:			@ Verify the character in our input is correct.
ldrb r0, [r1]				@ Load the data stored at the address in r1 into r0
bl sub_to_uppercase			@ Convert to uppercase
cmp r0, #'Y'				@ If r0 is equal to 'Y', go to gamestart
beq restart
cmp r0, #'N'				@ If r0 is equal to 'N', go to exit
beq exit
cmp r0, #10				@ If r0 is newline, show an error message
beq menu2_nochar
cmp r0, #' '				@ If r0 is equal to ' ' (space), check the next character
addeq r1, r1, #1
beq menu2_verify_char
ldr r1, =menu1_tryagain_string		@ If not...
mov r2, #menu1_tryagain_string_len
bl sub_print_stdout			@ Print menu1_tryagain_string to stdout
b menu2_yn				@ Do the y/n input again
menu2_nochar:
ldr r1, =nochar_string
mov r2, #nochar_string_len
bl sub_print_stdout
b menu2_yn

restart:
ldr r0, =guesses_remaining
mov r1, #6
str r1, [r0]				@ Sets guesses_remaining back to default value (6)
ldr r0, =num_incorrect_guesses
mov r1, #0
str r1, [r0]				@ Sets num_incorrect_guesses back to default value (0)
ldr r0, =incorrect_guesses
ldr r2, =mystery_string
ldr r4, =hangman_string
mov r5, #0				@ Stores whether or not we are finished with incorrect_guesses
mov r6, #0				@ Stores whether or not we are finished with mystery_string and hangman_string
restart_loop:
ldrb r1, [r0]				@ Load the character from incorrect_guesses into r1
ldrb r3, [r2]				@ Load the character from mystery_string into r3
cmp r1, #0				@ If r1 is null
moveq r5, #1				@ We are done with incorrect_guesses
cmp r3, #0				@ If r3 is null
moveq r6, #1				@ We are done with mystery_string and hangman_string
mov r1, #0
cmp r5, #0
streqb r1, [r0]				@ Otherwise, replace character in incorrect_guesses with 0
addeq r0, r0, #1
cmp r6, #0
streqb r1, [r2]				@ Otherwise, replace character in mystery_string with 0
streqb r1, [r4]
addeq r2, r2, #1
addeq r4, r4, #1
and r7, r5, r6
cmp r7, #1
beq gamestart				@ If both r5 and r6 are 1, restart
b restart_loop

exit:
ldr r1, =exit_string
mov r2, #exit_string_len
bl sub_print_stdout			@ Print exit_string to stdout
mov r7, #1
svc #0					@ Exit the program

/*
/////////////////////////////////////////////////////
//////////////////// Subroutines ////////////////////
/////////////////////////////////////////////////////
*/

/* subroutine sub_print_stdout: takes address in r1 and number of bytes in r2, prints that many bytes starting from the address to stdout. Returns nothing. */
sub_print_stdout:
push {r0, r7}
mov r0, #1
mov r7, #4
svc #0
pop {r0, r7}
bx lr

/* subroutine sub_read_stdin: takes address in r1 and number of bytes in r2, reads values into memory starting from the address from stdin. Returns number of characters read as integer in r0. */
sub_read_stdin:
push {r7}
mov r0, #0
mov r7, #3
svc #0
pop {r7}
bx lr

/* subroutine sub_to_uppercase: takes a character in r0 and, if it is not already, converts it to uppercase. Assumes that the character input is alphabetic. Returns uppercase character as char in r0. */
sub_to_uppercase:
cmp r0, #'Z'
subgt r0, #32
bx lr

/* subroutine sub_verify_length: takes a character in r1 (as this is executed after a read call) and verifies that it consists of only one non-special character. Takes address in r3 and length in r4 of an error message if it fails. Returns result of verification as boolean in r5. */
sub_verify_length: 
push {r0-r4, lr}
mov r2, #1
verify_length_loop:
ldrb r0, [r1], #1
cmp r0, #10				@ If the current character is a newline
beq verify_length_success		@ Then we are done
cmp r0, #' '				@ If not, then if the current character is a space or a special character (ascii code <= 32)
ble verify_length_loop			@ Then move on to the next character
cmp r2, #1				@ If not, then if r2 (used to verify that a non-special character hasn't been found yet) is 1
moveq r2, #0				@ Then set r2 to 0
beq verify_length_loop			@ And continue
bne verify_length_fail			@ If not, then fail.
verify_length_success:
mov r5, #1
pop {r0-r4, lr}
bx lr
verify_length_fail:
mov r5, #0
mov r1, r3
mov r2, r4
bl sub_print_stdout			@ If not, print the string from r3 and r4 to stdout
pop {r0-r4, lr}
bx lr

.data
newline: .asciz "\n"
num_format_string: .asciz "n"	@ Stores the character form of an integer
welcome_string: .asciz "Hangman by Maxine Collins ()\n"
welcome_string_len = .-welcome_string
welcome2_string: .asciz "Please type \"Y\" to start or \"N\" to exit: "
welcome2_string_len = .-welcome2_string
confirm: .space 100 @ Used to store input strings.
menu1_tryagain_string: .asciz "Please type either \"Y\" or \"N\": "
menu1_tryagain_string_len = .-menu1_tryagain_string
menu1_toolong_string: .asciz "Please only type 1 character, \"Y\" or \"N\": "
menu1_toolong_string_len = .-menu1_toolong_string
nochar_string: .asciz "Please enter a character: "
nochar_string_len = .-nochar_string
gamestart_string: .asciz "Welcome to Hangman!\n"
gamestart_string_len = .-gamestart_string
hangman_state_0: .asciz "______\n|/  |\n|\n|\n|\n|\n|_______\n\n"
hangman_state_0_len = .-hangman_state_0
hangman_state_1: .asciz "______\n|/  |\n|   O\n|\n|\n|\n|_______\n\n"
hangman_state_1_len = .-hangman_state_1
hangman_state_2: .asciz "______\n|/  |\n|   O\n|   |\n|   |\n|\n|_______\n\n"
hangman_state_2_len = .-hangman_state_2
hangman_state_3: .asciz "______\n|/  |\n|   O\n|  \\|\n|   |\n|\n|_______\n\n"
hangman_state_3_len = .-hangman_state_3
hangman_state_4: .asciz "______\n|/  |\n|   O\n|  \\|/\n|   |\n|\n|_______\n\n"
hangman_state_4_len = .-hangman_state_4
hangman_state_5: .asciz "______\n|/  |\n|   O\n|  \\|/\n|   |\n|  /\n|_______\n\n"
hangman_state_5_len = .-hangman_state_5
hangman_state_6: .asciz "______\n|/  |\n|   x\n|  \\|/\n|   |\n|  / \\\n|_______\n\n"
hangman_state_6_len = .-hangman_state_6
parse_strings_file: .asciz "./words.txt" @ The word parse_file reads from
parse_all_strings: .space 1024 @ The string containing all of the words that can be used in the game. It is read into by parse_file
parse_all_strings_len: .word 0
parse_error: .asciz "Error reading words file: File not found\n"
parse_error_len = .-parse_error
hangman_string: .space 100 @ The string that will be used in the game
hangman_string_len: .word 0
mystery_string: .space 20 @ Used to store the output of characters that have been correctly guessed, e.g.: "CH_LL_NG_"
incorrect_guesses: .space 24 @ Used to store the incorrect guesses.
num_incorrect_guesses: .word 0
guesses_remaining: .word 6
guesses_remaining_string: .asciz "Guesses remaining: "
guesses_remaining_string_len = .-guesses_remaining_string
incorrect_guesses_string: .asciz "Incorrect guesses: "
incorrect_guesses_string_len = .-incorrect_guesses_string
incorrect_guesses_separator: .asciz ", "
incorrect_guesses_separator_len = .-incorrect_guesses_separator
guess_prompt_string: .asciz "Enter \"0\" to exit, \"1\" to reveal a letter at the cost of 2 guesses, or \"2\" to restart.\nEnter your guess (A-Z, 0, 1, 2): "
guess_prompt_string_len = .-guess_prompt_string
game_toolong_string: .asciz "Please only type 1 character (A-Z, 0, 1, 2): "
game_toolong_string_len = .-game_toolong_string
game_tryagain_string: .asciz "Please enter a character between \"A\" and \"Z\", \"0\", \"1\" or \"2\": "
game_tryagain_string_len = .-game_tryagain_string
game_alreadyguessed_string: .asciz "You already guessed this character. Please try again: "
game_alreadyguessed_string_len = .-game_alreadyguessed_string
game_won_string: .asciz "Congratulations! You guessed the word!\nThe word was: "
game_won_string_len = .-game_won_string
game_lost_string: .asciz "You were unable to guess the word.\nThe word was: "
game_lost_string_len = .-game_lost_string
game_revealletter_noguesses_string: .asciz "You do not have enough guesses remaining to reveal a letter.\n"
game_revealletter_noguesses_string_len = .-game_revealletter_noguesses_string
gameend_string: .asciz "Game over!\nThanks for playing Hangman by Maxine Collins ()\nPlease type \"Y\" to restart or \"N\" to exit: "
gameend_string_len = .-gameend_string
exit_string: .asciz "Thanks for playing Hangman by Maxine Collins ()\n"
exit_string_len = .-exit_string

.end
