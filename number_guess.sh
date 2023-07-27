#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# generate random number between 1 and 1000
RANDOM_NUMBER=$(( $RANDOM % 1000 + 1 ))

# ask for username
echo "Enter your username:"
read USERNAME

GET_USER_DATA=$($PSQL "
    SELECT * 
    FROM users 
    WHERE username = '$USERNAME'
")

# if username is new
if [[ -z $GET_USER_DATA ]]
then
    # save into DB
    SAVE_NEW_USER=$($PSQL "
        INSERT INTO users(username, games_played, best_game) 
        VALUES('$USERNAME', 0, 1000)
    ")
    echo "Welcome, $USERNAME! It looks like this is your first time here."

# if username has been used before
else
    echo "$GET_USER_DATA" | while IFS=" |" read USERNAME GAMES_PLAYED BEST_GAME
    do
        echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
    done
fi

GUESS_COUNT=0

echo "Guess the secret number between 1 and 1000:"

# ask user to guess number
GUESS_NUMBER() {
    let GUESS_COUNT++
    read USER_GUESS

    # if user input is not an integer
    if ! [[ $USER_GUESS =~ ^[0-9]+$ ]]
    then
        echo "That is not an integer, guess again:"
        GUESS_NUMBER
    fi

    # if user input is lower
    if [[ $USER_GUESS -lt $RANDOM_NUMBER ]]
    then
        echo "It's higher than that, guess again:"
        GUESS_NUMBER
    fi

    # if user input is higher 
    if [[ $USER_GUESS -gt $RANDOM_NUMBER ]]
    then
        echo "It's lower than that, guess again:"
        GUESS_NUMBER
    fi
}

GUESS_NUMBER

# if user input is correct
if [[ $USER_GUESS -eq $RANDOM_NUMBER ]]
then
    GET_USER_DATA=$($PSQL "
        SELECT best_game 
        FROM users 
        WHERE username = '$USERNAME'
    ")
    echo "$GET_USER_DATA" | while IFS=" |" read BEST_GAME
    do
        # if number of guesses is lower than the best game
        if [[ $GUESS_COUNT -lt $BEST_GAME ]]
        then
            # save new best game and game count
            NEW_BEST_GAME=$($PSQL "
                UPDATE users 
                SET best_game=$GUESS_COUNT, 
                    games_played=games_played + 1 
                WHERE username = '$USERNAME'")
        else
            SAVE_GAME=$($PSQL "
                UPDATE users 
                SET games_played=games_played + 1 
                WHERE username='$USERNAME'
            ")
        fi
    done
    echo "You guessed it in $GUESS_COUNT tries. The secret number was $RANDOM_NUMBER. Nice job!"
fi
