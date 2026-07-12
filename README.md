# Ngam - Roger Anything, Kautim Instantly

[![Download APK](https://img.shields.io/badge/Download-Android_APK-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://github.com/AusIrfan06/Ngam/releases/latest/download/app-release.apk)

[Atau klik sini untuk ke halaman Releases](https://github.com/AusIrfan06/Ngam/releases)


Ngam is a community-driven Flutter application that connects people who need help with local errands (Customers) and people willing to do them (Runners). Whether it's buying food, doing a quick grocery run, printing documents, or heavy lifting, Ngam provides a seamless platform to get tasks done.

## Features

- **Dual-Role System:** Users can easily switch or register as a Customer (to request tasks) or a Runner (to earn money by completing tasks).
- **Real-Time Task Feed:** Runners can browse a live feed of open tasks and accept jobs instantly.
- **In-App Chat:** Real-time communication between Customers and Runners to coordinate tasks seamlessly.
- **DuitNow QR Integration:** Runners can upload their DuitNow QR codes for easy, direct payments from Customers upon task completion. 
- **Optimized Splash Screen:** The app uses a native splash screen that stays visible while initial data loads in the background, ensuring users land directly on a fully populated home screen.
- **Supabase Backend:** Powered by Supabase for fast, secure authentication, database management, and real-time features.

## Tech Stack

- **Frontend:** Flutter & Dart
- **Backend/Database:** Supabase (PostgreSQL, Realtime, Auth)
- **State Management:** Provider
- **Localization:** Easy Localization (Supports English and Malay)
- **UI Design:** Custom glassmorphism, animated backgrounds, and rich modern aesthetics (`liquid_glass_widgets`).

## Getting Started

### Prerequisites
- Flutter SDK (`>=3.0.0`)
- Dart SDK
- A Supabase project (for backend services)

### Installation
1. Clone the repository.
2. Run `flutter pub get` to install dependencies.
3. Configure your Supabase environment variables.
4. Run the app using `flutter run`.

## Payment Verification
Ngam emphasizes trust. When a Runner uploads their DuitNow QR for payment, the app displays the original, uncropped screenshot so Customers can visually verify the registered name provided directly by the bank before making any transfers.

---

# Buku Panduan Pengguna (User Manual) Aplikasi Ngam

Selamat datang ke **Ngam - Roger Anything, Kautim Instantly**. Ngam adalah aplikasi komunitari yang menghubungkan orang yang perlukan bantuan untuk tugasan harian (Customer) dengan mereka yang sedia membantu (Runner). 

Panduan ini merangkumi semua fungsi utama dan ciri-ciri unik (advanced features) aplikasi, daripada pendaftaran sehinggalah proses penyiapan tugasan.

---

## 1. Permulaan (Getting Started)

### 1.1 Pendaftaran & Log Masuk
- **Pendaftaran Emel Biasa**: Semasa mendaftar dengan emel dan kata laluan, anda boleh terus memilih peranan anda sama ada sebagai **Customer** atau **Runner**. Jika anda memilih Runner, borang *Runner Details* (IC & Kenderaan) akan terpapar untuk dilengkapkan terus semasa pendaftaran.
- **Log Masuk Google**: Untuk proses yang pantas, anda boleh menggunakan Akaun Google. Secara lalai (default), log masuk melalui Google akan mendaftarkan anda sebagai **Customer**.
- Selepas pendaftaran, pastikan anda mengemaskini profil asas anda (Nama Penuh, Gambar Profil, Nombor Telefon) untuk memudahkan pengguna lain menghubungi anda.

### 1.2 Dwi-Peranan (Dual-Role System) & Pengesahan Runner
- **Satu Akaun, Dua Fungsi**: Anda tidak perlu mendaftar akaun berasingan untuk menjadi pengguna atau penghantar.
- **Dari Customer ke Runner**: Jika anda mendaftar menggunakan akaun Google (atau mendaftar sebagai Customer pada mulanya), anda sentiasa boleh memohon menjadi Runner di dalam aplikasi.
- **Langkah Menjadi Runner (Bila Sudah Ada Akaun)**: Jika anda cuba mendaftar sekali lagi di halaman *Register* sebagai Runner menggunakan e-mel Customer yang sama, sistem tidak akan membenarkan pertindihan akaun. Sebaliknya, anda hanya perlu **Log Masuk** seperti biasa, pergi ke menu **Profil** dan tekan butang *Toggle* ke Runner. Borang *Runner Verification* (IC, Nombor Plat, Jenis Kenderaan) akan terpapar secara automatik untuk diisi.
- **Bertukar Peranan**: Setelah pengesahan berjaya, anda kini seorang Runner berdaftar. Selepas ini, anda bebas bertukar peranan antara Customer <-> Runner pada bila-bila masa dengan sekelip mata!

### 1.3 Tetapan Bahasa & Tema (Language & Theme)
- **Dwi-Bahasa**: Aplikasi Ngam menyokong **Bahasa Inggeris (English)** dan **Bahasa Melayu**.
- **Mod Gelap (Dark Mode)**: Anda juga boleh menukar paparan kepada *Light* atau *Dark Mode*.
- **Cara Menukar**: Anda boleh membuat tetapan Bahasa & Tema ini secara terus di:
  1. **Halaman Log Masuk (Sign In / Register)**: Tekan butang di bahagian atas kanan skrin sebelum mendaftar.
  2. **Halaman Profil (Profile)**: Terdapat butang togol yang dikhususkan untuk menukar tema dan bahasa bila-bila masa. Sistem akan menyimpan pilihan anda secara automatik.

---

## 2. Ngam Pay (Sistem Dompet Digital)

Ngam dilengkapi dengan dompet digital terbina dalam iaitu **Ngam Pay** bagi memastikan setiap transaksi berjalan lancar, selamat, dan bebas penipuan.

### 2.1 Top Up (Tambah Nilai)
1. Pergi ke halaman **Wallet**.
2. Anda boleh tambah kaedah pembayaran (Payment Method) seperti Kad Kredit/Debit atau guna Perbankan Dalam Talian.
3. Tekan butang **Top Up**, masukkan jumlah yang dikehendaki, dan sahkan. Baki dompet akan dikemaskini secara serta-merta (real-time).

### 2.2 Tambah Kaedah Pembayaran (Kad / Akaun Bank / DuitNow QR)
Sistem membolehkan anda menyimpan maklumat kad, akaun bank, atau DuitNow QR dengan selamat di dalam dompet.
1. Di halaman **Wallet**, tatal (scroll) ke bawah sehingga anda jumpa bahagian **Payment Methods**.
2. Tekan kotak kad bertanda **+ Add New**.
3. Pilih jenis kaedah yang ingin ditambah:
   - **Bank Account**: Pilih bank anda (cth: Maybank, CIMB) dan masukkan nombor akaun. Ini sangat penting untuk membolehkan anda membuat pengeluaran (Withdraw).
   - **Credit / Debit Card**: Masukkan nombor kad, tarikh luput, dan CVV (disulitkan secara selamat).
   - **DuitNow QR**: Khusus untuk Runner menerima bayaran, muat naik gambar QR yang disahkan (tiada suntingan).
4. Maklumat ini akan disimpan sebagai "Kad" yang boleh diselak (swipe) di ruangan Payment Methods.

### 2.3 Withdraw (Pengeluaran Wang)
- Fungsi pengeluaran (*Withdraw*) membenarkan wang dari dompet dipindahkan terus ke akaun bank anda.
- **Penting**: Anda WAJIB mendaftarkan Maklumat Akaun Bank (Rujuk 2.2) di dalam sistem terlebih dahulu sebelum fungsi pengeluaran boleh digunakan.
- Proses pengeluaran adalah selamat dan baki dompet akan ditolak mengikut jumlah pengeluaran secara automatik.

### 2.4 Sistem DuitNow QR & Anti-Penipuan
- Runner boleh memuat naik gambar **DuitNow QR** mereka.
- Apabila tiba masa pembayaran, Ngam akan memaparkan QR code asli (tanpa di-crop atau disunting) supaya Customer boleh menyemak nama penuh pendaftar secara visual di aplikasi bank mereka. Ini untuk mengelakkan kes penipuan profil palsu.

---

## 3. Mod Customer (Bila Anda Perlukan Bantuan)

Gunakan mod ini apabila anda memerlukan Runner untuk selesaikan tugas harian seperti beli makanan, beli barang runcit, atau hantar bungkusan.

### 3.1 Post Task (Buat Permintaan Tugas)
1. Pergi ke tab **Post Task** (ikon '+' di tengah menu bawah).
2. Isi maklumat tugasan:
   - **Tajuk Tugas** & **Penerangan Lengkap**.
   - **Kategori** (Makanan, Barangan Runcit, Penghantaran, Baiki, dsb).
   - **Bounty (Upah)**: Bayaran yang anda tawarkan. Sistem akan menolak jumlah ini dari Ngam Pay anda ke dalam sistem *Escrow* (pegangan selamat) sementara tugas dijalankan.
   - **Lokasi**: Gunakan *Map Picker* pintar untuk set koordinat GPS (pin merah) dengan tepat.
3. Tekan **Submit**. Tugas anda kini disiarkan secara *live* pada peta Runner.

### 3.2 Discover (Cari Runner & Servis Paling Hampir)
Skrin **Home** menyediakan **Peta Interaktif** yang menunjukkan tawaran servis dari pelbagai Runner yang berdekatan. Terdapat 2 cara utama untuk menempah servis dari halaman ini:
1. **Tekan pada Pin di Peta**: Jika anda nampak pin servis berdekatan (contoh: "Baiki Paip Bocor - RM50"), anda boleh terus tekan pada pin tersebut. Satu kotak info akan keluar, tekan kotak tersebut dan tekan **Book Service**. Peringatan kejayaan tempahan akan terpapar sebagai notifikasi kaca (*Glass Toast*) yang elegan.
2. **Gunakan Fungsi Carousel (Leret Kad)**: Di bahagian bawah peta, terdapat **Carousel** (senarai kad yang boleh dileret ke kiri/kanan). Apabila anda meleret (*swipe*) kad tersebut, peta secara automatik akan bergerak (*auto-focus*) dan menunjukkan lokasi sebenar servis tersebut. Ini membolehkan anda membuat tinjauan pantas tanpa perlu menekan pin di peta satu persatu.

### 3.3 Menguruskan Tugasan (My Tasks)
Anda boleh memantau semua tugas anda di ruangan **My Tasks**.
- **Fungsi Sort (Susun)**: Gunakan butang anak panah di sebelah tajuk "My Tasks" untuk menyusun senarai tugas dari **Paling Baru (Newest)** ke **Paling Lama (Oldest)**.
- **Open**: Tugas masih mencari Runner. Anda boleh **Cancel/Delete** tugas di peringkat ini, dan wang akan dipulangkan 100% ke dompet anda.
- **Locked**: Ada Runner berminat mengambil tugas anda. Anda perlu meluluskan / menerima Runner tersebut sebelum tugasan bermula.
- **In-Progress**: Runner sedang melaksanakan tugas. Ruangan **Chat** peribadi akan dibuka.
- **Delivered**: Runner memaklumkan tugas selesai.
- **Completed**: Anda sahkan kerja selesai, dan sistem melepaskan wang *Bounty* ke dompet Runner.

---

## 4. Mod Runner (Buat Duit Sampingan)

Gunakan mod ini untuk mencari tugasan, membantu komuniti, dan menjana pendapatan fleksibel.

### 4.1 Cari Tugas di Halaman Discover (Peta & Carousel)
Sama seperti Customer, Runner juga menggunakan Peta **Home** untuk mencari tugasan pelanggan (*Job Requests*) yang berdekatan:
- **Tekan Terus pada Pin**: Anda boleh terus tekan mana-mana pin tugas di atas peta, baca butiran (Bounty, jarak, penerangan), dan tekan **Accept Job** untuk mengambil kerja tersebut.
- **Carousel (Senarai Kad)**: Leret kad-kad tugas di ruangan *Carousel* bawah skrin. Setiap kali anda leret ke kad baru, peta akan memfokus (*zoom in*) kepada lokasi pelanggan tersebut. Ini memudahkan anda membandingkan jarak tugasan tanpa membuka halaman baru.

### 4.2 Menawarkan Servis (Service Listing)
- Anda juga boleh menawarkan kepakaran anda sebagai pakej servis. Tekan butang **Post Service** di ruangan *My Jobs*.
- Isikan maklumat servis yang anda sediakan seperti "Servis format laptop (RM50)" atau "Personal Shopper IKEA (RM30)". Gunakan peta untuk menetapkan lokasi di mana anda menawarkan perkhidmatan tersebut.
- **100% Percuma**: Menyiarkan iklan servis adalah percuma dan tidak menolak sebarang jumlah dari baki *Ngam Pay* anda. Servis ini akan kekal di peta (halaman Discover) dan Customers boleh menempah perkhidmatan anda pada bila-bila masa. Tempahan yang masuk akan terpapar di ruangan "Customer Bookings" di profil anda.

### 4.3 Aliran Kerja (Workflow)
1. Selepas tekan *Accept Job*, tugas berpindah ke tab **My Jobs** di bawah kategori **In-Progress** atau **Locked**.
2. **Fungsi Sort**: Anda boleh menyusun senarai kerja anda mengikut kronologi masa (Baru/Lama).
3. Anda boleh berkomunikasi dan kemaskini status terus menerusi ruangan **Chat**. 
4. Setelah anda siapkan tugas, tekan butang **Mark as Delivered**. 
5. Apabila Customer sahkan, tugas menjadi **Completed** dan *bounty* (upah) akan terus masuk ke dalam Wallet Ngam Pay anda.

### 4.4 Pengurusan Servis Sendiri (My Services)
Sebagai Runner, anda boleh memantau iklan servis yang anda tawarkan di ruangan **My Jobs > My Services**:
1. **Details**: Lihat butiran penuh iklan servis anda.
2. **Pause / Resume**: Anda boleh *Pause* (Hentikan sementara) iklan servis anda jika anda sibuk, dan *Resume* (Teruskan) apabila anda sedia menerima tempahan semula.
3. **Delete**: Memadam iklan servis secara kekal.
4. **Customer Bookings**: Jika ada pelanggan yang membuat tempahan terhadap servis anda, ia akan disenaraikan terus di bawah iklan tersebut untuk anda uruskan.

---

## 5. Fungsi Canggih (Advanced AI & Fitur Unik)

Ngam bukan sekadar aplikasi biasa, ia dilengkapi teknologi masa depan untuk memudahkan hidup anda:

### 5.1 AI Voice Assistant (Ngam AI)
- Di skrin utama, terdapat pembantu pintar AI. Anda boleh menaip atau **bercakap terus** (Speech-to-Text)!
- **Contoh Arahan**:
  - *"Tolong cari job paling mahal dekat sini."*
  - *"Ada orang perlukan khidmat hantar makanan tak?"*
- AI akan mengimbas (scan) secara *live* semua kerja berhampiran dan memberitahu anda hasilnya. 
- AI Ngam menyokong bahasa santai/rojak (Manglish/Malay).
- **Text-to-Speech (TTS)**: AI akan menjawab anda dengan suara supaya anda tak perlu baca teks ketika memandu atau berjalan.

### 5.2 Real-time Chat & Suara
- Setiap tugas menyediakan bilik perbualan khas.
- Anda boleh menghantar mesej teks biasa.
- **Voice Dictation**: Malas menaip? Gunakan ikon mikrofon terbina dalam chat untuk menukar percakapan anda menjadi teks secara automatik!

### 5.3 Antara Muka "Liquid Glass" (Glassmorphism)
- Aplikasi ini dibangunkan dengan tema rekabentuk moden yang dipanggil *Liquid Glass*. Anda akan perasan elemen-elemen telus (transparent blur), efek cahaya mikro, animasi licin yang memberikan rasa premium ala iOS, serta notifikasi **Glass Toast** yang elegan (seperti ketika anda berjaya tempah servis).
- **Dark Mode / Light Mode**: Disokong secara automatik mengikut tetapan telefon pintar anda.

---

## 6. Ciri-ciri Keselamatan Ngam (Security & Privacy)

Aplikasi Ngam direka dengan pelbagai lapisan keselamatan untuk melindungi pengguna, wang, dan data peribadi anda:

### 6.1 Keselamatan Data & Akses (Supabase & RLS)
- **Log Masuk Selamat**: Sokongan pengesahan identiti (Authentication) bertaraf dunia menggunakan sistem Supabase Auth.
- **Row Level Security (RLS)**: Ngam menggunakan dasar pangkalan data (Database Policies) yang ketat. Ini bermaksud data peribadi, mesej sembang (chat), dan baki dompet anda dikunci pada tahap pelayan (server) dan **hanya anda sahaja** yang boleh melihat/mengubahnya. Pihak ketiga tidak boleh menggodam data anda.

### 6.2 Sistem Pembayaran "Escrow"
- **Jaminan Kewangan**: Pihak Customer tidak perlu risau Runner lari tanpa buat kerja, dan Runner tidak perlu risau tidak dibayar setelah penat bekerja. 
- Apabila tugas dipersetujui, wang akan ditarik ke dalam sistem *Escrow* (pegangan selamat Ngam). Wang ini hanya akan dilepaskan kepada Runner *selepas* Customer menekan butang sahkan kerja diselesaikan (Completed).

### 6.3 Anti-Penipuan (Anti-Scam) DuitNow QR
- Sistem kami mewajibkan Runner memuat naik gambar DuitNow QR asli (uncropped).
- Apabila Customer ingin membayar/menyemak melalui aplikasi perbankan, mereka boleh melihat nama pemilik akaun berdaftar secara langsung untuk memastikan ia berpadanan dengan profil Runner. Ini menghalang penyamaran identiti.

### 6.4 Privasi Lokasi Peta (Location Privacy)
- Peta hanya memaparkan lokasi di mana tugasan (Task) itu perlu dilakukan. 
- **Lokasi GPS sebenar anda sentiasa selamat dan disembunyikan** dari paparan awam demi mengelakkan sebarang pencerobohan privasi.

### 6.5 Kawalan Privasi Peranti (App Lock & App Switcher)
Anda boleh mengetatkan lagi keselamatan aplikasi Ngam di dalam telefon anda melalui menu **Profile > Privacy & Security**:
1. **App Lock (Kunci Aplikasi)**: Anda boleh mengaktifkan App Lock menggunakan cap jari (Biometrics) atau PIN telefon. Anda boleh tetapkan masa (Immediately, 1 min, 15 min, 1 jam) supaya aplikasi terkunci secara automatik apabila anda keluar (minimize).
2. **Hide in App Switcher (Skrin Kabur)**: Aktifkan ciri ini untuk mengaburkan (blur) paparan aplikasi Ngam apabila anda membuka fungsi *Recent Apps* atau *App Switcher* di telefon anda. Ini menghalang orang di sebelah anda dari mengintai baki Ngam Pay atau chat peribadi anda dari jauh.

---

## 7. Sistem Sembang (In-App Chat)

Ngam mempunyai fungsi mesej/sembang (chat) terbina dalam yang sangat interaktif bagi memudahkan komunikasi antara Customer dan Runner:
1. **Mesej Masa Nyata (Real-time)**: Mesej dihantar dan diterima serta-merta tanpa perlu *refresh*.
2. **Status Kehadiran (Online/Offline)**: Anda boleh melihat jika pihak sana sedang 'Online'.
3. **Petunjuk Penaipan (Typing Indicator)**: Anda akan nampak animasi kecil apabila pihak sana sedang menaip mesej.
4. **Carian Mesej**: Anda boleh menggunakan fungsi *Search* (Cari) untuk mencari mesej-mesej lama.
5. **Autoskrol Bawah**: Memastikan mesej baru yang tiba sentiasa muncul serta-merta di paparan.

*(Nota Penting: Fungsi meleret / Carousel hanya wujud di halaman Peta/Discover. Jika anda mahu membuka Chat untuk tugas berlainan, anda perlu ke halaman My Tasks/My Jobs dan menekan butang Chat pada kad tugas berkenaan.)*

---

## 8. Bantuan & Sokongan (Support)

- Jika ada sebarang pertikaian atau masalah teknikal (contoh: Runner tidak siapkan kerja, atau refund tidak masuk), gunakan butang **Help & Support** di ruang Profil. 
- Pasukan Ngam (Ngam Team) sentiasa bersedia membantu anda menyemak log sembang (chat) dan memulangkan wang dengan adil jika berlaku penipuan.

> [!TIP]
> Sentiasa semak notifikasi *push* di telefon bimbit anda dan aktifkan kebenaran lokasi (GPS Permission - Always/While In Use) untuk merasai pengalaman optimum aplikasi Ngam.

Terima kasih menggunakan Ngam. Teruskan **"Roger Anything, Kautim Instantly"**!
