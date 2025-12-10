import json
import random
import string

# Weighted letters
LETTERS = 'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee' \
          'tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt' \
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' \
          'ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo' \
          'iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii' \
          'nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn' \
          'sssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss' \
          'rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr' \
          'hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh' \
          'llllllllllllllllllllllllllllllllllllllll' \
          'dddddddddddddddddddddddddddddddddd' \
          'cccccccccccccccccccccccccccc' \
          'uuuuuuuuuuuuuuuuuuuuuuuuuu' \
          'mmmmmmmmmmmmmmmmmmmmmmmm' \
          'ffffffffffffffffffffff' \
          'pppppppppppppppppp' \
          'ggggggggggggggggg' \
          'yyyyyyyyyyyyyyy' \
          'wwwwwwwwwwwww' \
          'bbbbbbbbbbbb' \
          'vvvvvvvvvv' \
          'kkkkkkkk' \
          'xxxx' \
          'jjj' \
          'qq' \
          'zz'

def get_random_char():
    return random.choice(LETTERS)

def generate_grid_for_word(word):
    # 6x6 grid
    grid = [['' for _ in range(6)] for _ in range(6)]
    word = word.lower()
    length = len(word)
    
    placed = False
    attempts = 0
    placement = {}
    
    directions = [
        (0, 1),  # Right
        (0, -1), # Left
        (1, 0),  # Down
        (-1, 0), # Up
        (1, 1),  # Down-Right
        (1, -1), # Down-Left
        (-1, 1), # Up-Right
        (-1, -1) # Up-Left
    ]
    
    while not placed and attempts < 200:
        dr, dc = random.choice(directions)
        
        valid_starts = []
        for r in range(6):
            for c in range(6):
                last_r = r + (length - 1) * dr
                last_c = c + (length - 1) * dc
                if 0 <= last_r < 6 and 0 <= last_c < 6:
                    valid_starts.append((r, c))
                    
        if not valid_starts:
            attempts += 1
            continue
            
        row, col = random.choice(valid_starts)
        
        # Place word
        path = []
        for k in range(length):
            r = row + k * dr
            c = col + k * dc
            grid[r][c] = word[k]
            path.append({'row': r, 'col': c})
            
        placement = {
            'path': path
        }
        placed = True
        attempts += 1
        
    # Fill rest
    for r in range(6):
        for c in range(6):
            if grid[r][c] == '':
                grid[r][c] = get_random_char()
                
    return grid, placement

def main():
    try:
        with open('assets/levels.json', 'r', encoding='utf-8') as f:
            old_levels = json.load(f)
            
        new_levels = []
        for lvl in old_levels:
            new_qs = []
            for q in lvl['questions']:
                ans = q['answer'].strip()
                if len(ans) > 6:
                    continue
                    
                grid, placement = generate_grid_for_word(ans)
                
                new_q = {
                    'q_id': q['q_id'],
                    'coins': q['coins'],
                    'grid': grid,
                    'answerPlacement': placement,
                    'question': q['question'],
                    'answer': ans
                }
                new_qs.append(new_q)
            
            if new_qs:
                new_lvl = {
                    'id': lvl['id'],
                    'title': lvl['title'],
                    'timeLimit': lvl['timeLimit'],
                    'orientation': '6x6',
                    'gridSize': 36,
                    'questions': new_qs
                }
                new_levels.append(new_lvl)
                
        with open('assets/levels.json', 'w', encoding='utf-8') as f:
            json.dump(new_levels, f, indent=2)
            
        print(f"Regenerated {len(new_levels)} levels with 8-way paths.")
        
    except Exception as e:
        print(f"Error: {e}")

if __name__ == '__main__':
    main()
