import re

file_path = r'C:\Ngam\lib\screens\runner\stats_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace colors
content = content.replace('0xFF00E676', '0xFF2196F3')
content = content.replace('0xFF00BCD4', '0xFF42A5F5')

# Strings to replace
strings = [
    'Today', 'This Week', 'This Month', 'Custom Range', 
    'Performance', 'Total Earnings', 'Active Jobs', 'Completed Jobs',
    'No earnings data available', 'Recent Transactions', 'No transactions in this timeframe',
    'Earnings by Category', 'Job Status', 'COMPLETED', 'CANCELLED', 'IN-PROGRESS', 'OTHER',
    'Completed', 'Cancelled', 'In-Progress', 'Other', 'General',
    'Start Date', 'End Date', 'Select Dates', 'Apply', 'Transactions', 'Active Gigs'
]

for s in strings:
    content = re.sub(r"Text\(\s*'" + s + r"'\s*(,[^\)]*)?\)", r"Text('" + s + r"'.tr()\1)", content)
    content = re.sub(r'Text\(\s*"' + s + r'"\s*(,[^\)]*)?\)', r'Text("' + s + r'".tr()\1)', content)

content = content.replace("const map = ['Today', 'This Week', 'This Month', 'Custom Range'];", "final map = ['Today'.tr(), 'This Week'.tr(), 'This Month'.tr(), 'Custom Range'.tr()];")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print('Done')
