import re

with open('c:/Ngam/lib/services/chat_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(\"select('customer_id, gig_worker_id, title')\", \"select('customer_id, gig_worker_id, title, status')\")

with open('c:/Ngam/lib/services/chat_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)
