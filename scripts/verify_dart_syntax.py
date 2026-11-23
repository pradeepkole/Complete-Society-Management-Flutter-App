import os
import sys

def check_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Track brackets
    stack = []
    pairs = {'{': '}', '(': ')', '[': ']'}
    line_no = 1
    col_no = 1
    
    in_single_quote = False
    in_double_quote = False
    in_multi_line_comment = False
    in_single_line_comment = False
    i = 0
    n = len(content)
    
    while i < n:
        c = content[i]
        
        if c == '\n':
            line_no += 1
            col_no = 1
            in_single_line_comment = False
            i += 1
            continue
        
        col_no += 1
        
        if in_single_line_comment:
            i += 1
            continue
            
        if in_multi_line_comment:
            if c == '*' and i + 1 < n and content[i+1] == '/':
                in_multi_line_comment = False
                i += 2
                continue
            i += 1
            continue
            
        if in_single_quote:
            if c == '\\':
                i += 2
                continue
            if c == "'":
                in_single_quote = False
            i += 1
            continue
            
        if in_double_quote:
            if c == '\\':
                i += 2
                continue
            if c == '"':
                in_double_quote = False
            i += 1
            continue
            
        # Comments
        if c == '/' and i + 1 < n and content[i+1] == '/':
            in_single_line_comment = True
            i += 2
            continue
            
        if c == '/' and i + 1 < n and content[i+1] == '*':
            in_multi_line_comment = True
            i += 2
            continue
            
        # Quotes
        if c == "'":
            in_single_quote = True
            i += 1
            continue
            
        if c == '"':
            in_double_quote = True
            i += 1
            continue
            
        if c in pairs:
            stack.append((c, line_no, col_no))
        elif c in pairs.values():
            if not stack:
                print(f"Error in {filepath}:{line_no}:{col_no}: Unmatched closing '{c}'")
                return False
            top, t_line, t_col = stack.pop()
            if pairs[top] != c:
                print(f"Error in {filepath}:{line_no}:{col_no}: Mismatched '{c}', expected '{pairs[top]}' for '{top}' opened at line {t_line}")
                return False
                
        i += 1
        
    if stack:
        top, t_line, t_col = stack[-1]
        print(f"Error in {filepath}: Unclosed '{top}' opened at line {t_line}:{t_col}")
        return False
        
    return True

def main():
    errors = 0
    total = 0
    for root, _, files in os.walk('lib'):
        for file in files:
            if file.endswith('.dart'):
                total += 1
                fp = os.path.join(root, file)
                if not check_file(fp):
                    errors += 1
                    
    print(f"\nChecked {total} Dart files. Errors: {errors}")
    sys.exit(1 if errors > 0 else 0)

if __name__ == '__main__':
    main()
