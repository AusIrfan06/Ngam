import sys

with open(sys.argv[1], 'r', encoding='utf-8') as f:
    lines = f.readlines()

# The original function started at line 2041 and ended at 2476 (inclusive).
# But wait, my previous tool call deleted 6 lines.
# So the current file has 6 fewer lines. Let's find where it starts and ends dynamically.
start_idx = -1
end_idx = -1

for i, line in enumerate(lines):
    if "bool isAIPopupOpen = true;" in line:
        # Check if previous lines have method signature. 
        if i-1 >= 0 and "void _showAIPopup" not in lines[i-1] and start_idx == -1:
            start_idx = i
    if "void _showVoiceSearchPopup" in line:
        end_idx = i - 1
        break

if start_idx != -1 and end_idx != -1:
    del lines[start_idx:end_idx+1]
    with open(sys.argv[1], 'w', encoding='utf-8') as f:
        f.writelines(lines)
    print(f"Deleted from index {start_idx} to {end_idx}")
else:
    print("Could not find boundaries")
