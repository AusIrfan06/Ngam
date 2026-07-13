import uuid
import random
from datetime import datetime, timedelta

def main():
    target_user_id = '157016e9-0c9e-4e1a-a2dd-55157a271d3c'
    
    first_names = ["Zul", "Farah", "Aisyah", "Kamal", "Sarah", "Jason", "Kumar", "Mei", "Ali", "Faizal", "Aminah", "Chong", "Abu", "Siti"]
    last_names = ["Othman", "Ismail", "Tan", "Abdullah", "Singh", "Lee", "Bakar", "Wong", "Raju", "Samad", "Hassan"]
    
    messages_set = [
        [
            ("customer", "Salam bang, jadi tak order ni?"),
            ("runner", "Waalaikumussalam, ya jadi bos."),
            ("customer", "Sorry lambat sikit jalan jem."),
            ("runner", "Dah sampai lobby, turun la."),
            ("customer", "Terima kasih bos, servis mantap!")
        ],
        [
            ("customer", "Berapa harga semua?"),
            ("runner", "Harga RM 50 je bos."),
            ("customer", "Duit saya dah transfer ye."),
            ("runner", "Duit dah masuk, tq bos."),
            ("customer", "Nanti sampai call saya tau.")
        ],
        [
            ("customer", "Awak kat mana tu?"),
            ("runner", "Dah on the way ni."),
            ("customer", "Dah nak sampai ke?"),
            ("runner", "Okay nanti sampai saya call.")
        ],
        [
            ("customer", "Tolong beli extra satu boleh?"),
            ("runner", "Boleh bos."),
            ("customer", "Boleh kurang sikit tak?"),
            ("runner", "Sorry bos harga dah fix.")
        ],
        [
            ("customer", "Esok pukul berapa boleh mula?"),
            ("runner", "Pukul 10 pagi esok saya start.")
        ],
        [
            ("customer", "Barang dah sampai belum?"),
            ("runner", "Belum bos, lagi 10 minit.")
        ],
        [
            ("customer", "Tolong berhati-hati jalan licin."),
            ("runner", "Baik, saya hati-hati."),
            ("customer", "Saya tunggu kat lobby.")
        ],
        [
            ("runner", "Saya dah kat luar ni."),
            ("customer", "Kejap saya pakai tudung.")
        ],
        [
            ("customer", "Macam mana nak bayar?"),
            ("runner", "Boleh bank in atau cash."),
            ("customer", "Okay saya bayar cash je nanti.")
        ],
        [
            ("customer", "Maaf saya lambat sikit."),
            ("runner", "Takpe bos, take your time.")
        ],
        [
            ("customer", "Boleh tolong angkat barang masuk dalam?"),
            ("runner", "Boleh, takde masalah.")
        ],
        [
            ("runner", "Bos, barang dah habis kat kedai ni."),
            ("customer", "Alamak. Beli kedai sebelah boleh?")
        ],
        [
            ("customer", "Terima kasih ya!"),
            ("runner", "Sama-sama bos.")
        ],
        [
            ("runner", "Nak resit tak?"),
            ("customer", "Takpe takyah resit.")
        ],
        [
            ("customer", "Minta tolong cepat sikit boleh?"),
            ("runner", "Baik, saya cuba cepat.")
        ]
    ]
    
    now = datetime.now()
    
    with open('seed_chats_extended.sql', 'w', encoding='utf-8') as f:
        f.write("-- Seed extended random users, conversations and multiple messages (Fixed auth.users FK)\\n\\n")
        
        for i in range(40):
            random_user_id = str(uuid.uuid4())
            name = f"{random.choice(first_names)} {random.choice(last_names)}"
            email = f"{name.lower().replace(' ', '')}{random.randint(100, 999)}@email.com"
            phone = f"01{random.randint(10000000, 99999999)}"
            
            user_created_at = now.strftime('%Y-%m-%d %H:%M:%S+00')
            
            # INSERT INTO auth.users to satisfy foreign key constraints
            f.write(f"INSERT INTO auth.users (id, aud, role, email, created_at, updated_at, encrypted_password, confirmation_token, email_change, email_change_token_new, recovery_token) VALUES ('{random_user_id}', 'authenticated', 'authenticated', '{email}', '{user_created_at}', '{user_created_at}', '', '', '', '', '');\\n")
            
            # INSERT INTO public.users
            f.write(f"INSERT INTO \\\"public\\\".\\\"users\\\" (\\\"id\\\", \\\"name\\\", \\\"email\\\", \\\"phone\\\", \\\"role\\\", \\\"created_at\\\") VALUES ('{random_user_id}', '{name}', '{email}', '{phone}', 'customer', '{user_created_at}');\\n")
            
            conv_id = str(uuid.uuid4())
            
            chat_sequence = random.choice(messages_set)
            
            # Create base time for conversation, a few days ago up to now
            days_ago = random.randint(0, 5)
            hours_ago = random.randint(0, 23)
            conv_time = now - timedelta(days=days_ago, hours=hours_ago)
            
            # Process messages
            messages_sql = []
            
            last_msg_text = ""
            last_sender = ""
            last_time_str = ""
            
            for j, (role, text) in enumerate(chat_sequence):
                msg_id = str(uuid.uuid4())
                sender_id = random_user_id if role == "customer" else target_user_id
                
                # add a few minutes between each message
                msg_time = conv_time + timedelta(minutes=j*random.randint(1, 5))
                msg_time_str = msg_time.strftime('%Y-%m-%d %H:%M:%S+00')
                
                # mostly read except the last one randomly
                is_read = "true"
                if j == len(chat_sequence) - 1 and role == "customer":
                    is_read = "false" if random.random() < 0.5 else "true"
                
                messages_sql.append(
                    f"INSERT INTO \\\"public\\\".\\\"messages\\\" (\\\"id\\\", \\\"conversation_id\\\", \\\"sender_id\\\", \\\"content\\\", \\\"is_read\\\", \\\"created_at\\\", \\\"message_type\\\", \\\"status\\\") VALUES ('{msg_id}', '{conv_id}', '{sender_id}', '{text}', {is_read}, '{msg_time_str}', 'text', 'sent');\\n"
                )
                
                last_msg_text = text
                last_sender = sender_id
                last_time_str = msg_time_str
                last_is_read = is_read
            
            unread_count = 1 if last_is_read == "false" and last_sender == random_user_id else 0
            
            f.write(f"INSERT INTO \\\"public\\\".\\\"conversations\\\" (\\\"id\\\", \\\"user1_id\\\", \\\"user2_id\\\", \\\"last_message\\\", \\\"last_message_sender_id\\\", \\\"last_message_is_read\\\", \\\"updated_at\\\", \\\"unread_count\\\") VALUES ('{conv_id}', '{random_user_id}', '{target_user_id}', '{last_msg_text}', '{last_sender}', {last_is_read}, '{last_time_str}', {unread_count});\\n")
            
            for m_sql in messages_sql:
                f.write(m_sql)
            
            f.write("\\n")

    print("Generated seed_chats_extended.sql")

if __name__ == "__main__":
    main()
