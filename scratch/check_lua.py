import sys

def check_lua_nesting(filepath):
    with open(filepath, 'r') as f:
        lines = f.readlines()
    
    depth = 0
    stack = []
    
    for idx, line in enumerate(lines, 1):
        clean = line.strip()
        # Remove comments
        if clean.startswith('--'):
            continue
        
        # Split tokens roughly
        tokens = clean.split()
        
        # Track block creators
        starts = 0
        ends = 0
        
        for t in tokens:
            t_clean = t.split('(')[0].split(')')[0].split('{')[0].split('}')[0]
            if t_clean in ['function', 'if', 'while', 'for', 'then', 'do', 'repeat']:
                starts += 1
                stack.append((idx, t_clean))
            elif t_clean == 'end':
                ends += 1
                if stack:
                    stack.pop()
        
        depth += (starts - ends)
        # print(f"Line {idx}: depth={depth}, starts={starts}, ends={ends} | {clean[:30]}")
        
    print(f"Final depth: {len(stack)}")
    if stack:
        print("Unclosed blocks:")
        for idx, block in stack:
            print(f"Line {idx}: {block}")

if __name__ == '__main__':
    check_lua_nesting(sys.argv[1])
