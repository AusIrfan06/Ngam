import sys

with open(sys.argv[1], 'r', encoding='utf-8') as f:
    text = f.read()

balance = 0
for i, char in enumerate(text):
    if char == '{':
        balance += 1
    elif char == '}':
        balance -= 1
    if balance < 0:
        print(f"Unbalanced at index {i}")
        break

print(f"Final balance: {balance}")
