import random


def generate_minesweeper_board(rows, cols, num_mines):
    # Initialize an empty grid
    board = [['0' for _ in range(cols)] for _ in range(rows)]

    # Place mines randomly
    mines_placed = 0
    while mines_placed < num_mines:
        row = random.randint(0, rows - 1)
        col = random.randint(0, cols - 1)
        if board[row][col] != '-1':  # -1 represents a mine
            board[row][col] = '-1'
            mines_placed += 1

    # Calculate the numbers on the board based on surrounding mines
    for row in range(rows):
        for col in range(cols):
            if board[row][col] == '-1':
                continue  # Skip mines
            # Count mines in the neighboring cells
            mine_count = 0
            for dr in [-1, 0, 1]:
                for dc in [-1, 0, 1]:
                    nr, nc = row + dr, col + dc
                    if 0 <= nr < rows and 0 <= nc < cols and board[nr][nc] == '-1':
                        mine_count += 1
            # Set the number if there are any mines around
            board[row][col] = str(mine_count) if mine_count > 0 else '0'

    return board


def hide_board(board, rows, cols):
    # Copy the board for hiding the numbers
    hidden_board = [['-' for _ in range(cols)] for _ in range(rows)]

    # We will leave some numbers visible to make the board solvable
    for row in range(rows):
        for col in range(cols):
            # Leave numbers visible if they are important to solving
            if board[row][col] != '0' and board[row][col] != '-1':
                if random.random() < 0.3:  # 30% chance to reveal a clue
                    hidden_board[row][col] = board[row][col]

    return hidden_board


def print_board(board):
    for row in board:
        print(" ".join(row))


def write_board_to_file(filename, rows, cols, num_mines, board, print_mines):
    # Open the file for writing (this will overwrite any existing content)
    with open(filename, 'w') as file:
        # Write the first line with NUM_ROWS NUM_COLS -1
        file.write(f"{rows} {cols} {num_mines if print_mines else -1}\n")

        # Write the board matrix
        for row in board:
            file.write(" ".join(row) + "\n")


# Parameters for the board
rows = 200  # Number of rows
cols = 200  # Number of columns
num_mines = 10000  # Number of mines

# Generate the Minesweeper board
board = generate_minesweeper_board(rows, cols, num_mines)

# Hide the clues and bombs (while making the board solvable)
hidden_board = hide_board(board, rows, cols)

# Output the hidden board to the console (optional)
print_board(hidden_board)

# Write the board to the output.txt file
write_board_to_file("output.txt", rows, cols, num_mines, hidden_board, print_mines=False)