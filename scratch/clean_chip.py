import sys

with open(sys.argv[1], 'r', encoding='utf-8') as f:
    lines = f.readlines()

start_idx = -1
end_idx = -1

for i, line in enumerate(lines):
    if "Widget _buildCollapsedAIChip" in line:
        start_idx = i
    if "Widget _buildExpandedAIPanel" in line and start_idx != -1:
        end_idx = i - 1
        break

if start_idx != -1 and end_idx != -1:
    del lines[start_idx:end_idx+1]
    with open(sys.argv[1], 'w', encoding='utf-8') as f:
        f.writelines(lines)
    print(f"Deleted from index {start_idx} to {end_idx}")
else:
    print("Could not find boundaries")
