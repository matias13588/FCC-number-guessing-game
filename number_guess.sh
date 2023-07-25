#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# generate random number between 1 and 1000
RANDOM_NUMBER=$(( $RANDOM % 1000 + 1 ))

# ask for username
echo -e "\nEnter your username:\n"
read USERNAME

GET_USER_DATA=$($PSQL "SELECT * FROM users WHERE username = '$USERNAME'")

# if username is new
if [[ -z $GET_USER_DATA ]]
then
    # save into DB
    SAVE_NEW_USER=$($PSQL "INSERT INTO users(username, games_played, best_game) VALUES('$USERNAME', 1, 1000)")
    echo -e "\nWelcome, $USERNAME! It looks like this is your first time here.\n"

# if username has been used before
else
    echo "$GET_USER_DATA" | while IFS=" |" read USERNAME GAMES_PLAYED BEST_GAME
    do
        echo -e "\nWelcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses.\n"
    done
fi

GUESS_COUNT=0

# ask user to guess number
GUESS_NUMBER() {
    echo -e "\nGuess the secret number between 1 and 1000:\n"
    let GUESS_COUNT++
    read USER_GUESS

    # if user input is not an integer
    if ! [[ $USER_GUESS =~ ^[0-9]+$ ]]
    then
        echo -e "\nThat is not an integer, guess again:\n"
        GUESS_NUMBER
    fi

    # if user input is lower
    if [[ $USER_GUESS -lt $RANDOM_NUMBER ]]
    then
        echo -e "\nIt's higher than that, guess again:\n"
        GUESS_NUMBER
    fi

    # if user input is higher 
    if [[ $USER_GUESS -gt $RANDOM_NUMBER ]]
    then
        echo -e "\nIt's lower than that, guess again:\n"
        GUESS_NUMBER
    fi
}

GUESS_NUMBER

# if user input is correct
if [[ $USER_GUESS -eq $RANDOM_NUMBER ]]
then
    GET_USER_DATA=$($PSQL "SELECT * FROM users WHERE username = '$USERNAME'")
    echo "$GET_USER_DATA" | while IFS=" |" read USERNAME GAMES_PLAYED BEST_GAME
    do
        # if number of guesses is lower than the best game
        if [[ $GUESS_COUNT -lt $BEST_GAME ]]
        then
        # save new best game and game count
        NEW_BEST_GAME=$($PSQL "UPDATE users SET best_game=$GUESS_COUNT, games_played=$GAMES_PLAYED + 1 WHERE username = '$USERNAME'")
        fi
    done
    echo -e "\nYou guessed it in $GUESS_COUNT tries. The secret number was $RANDOM_NUMBER. Nice job!\n"
fi
