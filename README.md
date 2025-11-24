Anggota Kelompok :
- Aaron Nathanael Suhaendi / 2406437073
- Arya Novalino Pratama / 2406495590
- Naomi Kyla Zahra Siregar / 2406434102
- Rizky Antariksa / 2406495552
- Samuel Indriano / 2406400524
- Wildan Anshari Hidayat / 2406396590


Deskripsi Aplikasi : GetFitToday adalah aplikasi mobile yang berfungsi sebagai platform pencarian dan reservasi fasilitas olahraga berbasis peta interaktif. Aplikasi ini memudahkan pengguna menemukan lokasi olahraga (gym, lapangan, dll) di sekitar mereka, melakukan booking tempat, berbelanja perlengkapan olahraga, hingga bergabung dengan komunitas olahraga. Aplikasi ini bertujuan untuk menciptakan ekosistem olahraga yang terintegrasi dan mudah diakses oleh user.



Daftar modul serta penjelasannya:

- Location Discovery --> Wildan Anshari Hidayat

Modul utama yang menampilkan halaman utama dan peta interaktif yang akan menampilkan lokasi dan informasi dari tempat olahraga terdekat dari user.

- Booking & Reservation --> Samuel Indriano

Modul yang memiliki fitur dimana user dapat melakukan booking atau reservasi tempat olahraga secara langsung melalui aplikasi. Komponen modul ini akan terdiri dari pengecekan ketersediaan waktu tempat olahraga, proses konfirmasi booking atau reservasi, dan halaman riwayat dan daftar booking user.

- Event Management --> Rizky Antariksa

Modul yang berfungsi untuk melakukan pembuatan, penemuan, dan partisipasi dalam acara komunitas.

- Blog & Events --> Arya Novalino Pratama

Modul yang fungsinya sebagai pusat informasi dan artikel seputar olahraga ataupun kegiatan komunitas.

- Community & Social --> Naomi Kyla Zahra Siregar

Modul ini membangun social network di dalam platform. User dapat melihat informasi komunitas dan bisa bergabung dalam komunitas olahraga tersebut. Informasi komunitas terdiri dari deskripsi komunitas, jadwal bermain rutin komunitas (jika ada), dan nama-nama dari setiap anggota komunitas.

- Online Shop / Store --> Aaron Nathanael Suhaendi

Modul yang bertindak sebagai store di mana user yang sudah login bisa melakukan pembelian perlengkapan olahraga seperti bola, pakaian, alat gym, dll.



Role beserta Deskripsi :

- Guest

Hanya dapat melihat peta, informasi komunitas, blog, dan online shop/store. User tidak punya wewenang untuk melakukan modifikasi blog, bergabung dalam komunitas, mendaftar untuk partisipasi dalam acara komunitas, melakukan reservasi tempat olahraga, dan berbelanja di online shop/store.

- Signed In User

User bisa berinteraksi dengan peta dan punya wewenang untuk melakukan modifikasi entry blog, bergabung dalam komunitas, berpartisipasi dalam acara komunitas, melakukan reservasi tempat olahraga, dan dapat berbelanja di online shop/store.

- Admin

Admin aplikasi memiliki wewenang untuk menghapus dan memodifikasi informasi setiap komunitas, blog, dan produk yang tersedia di online shop/store.

- Admin komunitas

Admin komunitas memiliki wewenang untuk menghapus dan memodifikasi informasi komunitas yang dipegang, juga dapat membuat dan mengatur acara olahraga yang akan diadakan komunitas.


Alur Integrasi:
Langkah-langkah/Alur Pengintegrasian

1. Sisi Backend (Django) - Penyediaan Endpoints :

Membuat View JSON: Membuat views baru yang mengembalikan data dalam format JSON.

Routing URL: Menambahkan path baru di urls.py yang mengarah ke views tersebut.

Konfigurasi Keamanan: Mengatur CORS (Cross-Origin Resource Sharing) atau allowed hosts agar Flutter diizinkan mengakses data dari server.

2. Sisi Frontend (Flutter) - Pengambilan Data :
Aplikasi Flutter bertindak sebagai client yang meminta data.

Dependency: Menambahkan package seperti http atau pbp_django_auth untuk melakukan permintaan HTTP.

Model Data: Membuat kelas model Dart dengan QuickType untuk memetakan struktur JSON dari Django menjadi objek Dart.

Asynchronous Fetching: Membuat fungsi async untuk melakukan request ke URL Django dan menunggu responsnya.

3. Alur Eksekusi : 
Request (Permintaan): Pengguna melakukan aksi di Flutter (misal: membuka halaman atau menekan tombol). Flutter mengirimkan HTTP Request (seperti GET atau POST) ke URL endpoint Django.

Processing (Pemrosesan): Server Django menerima request tersebut. URL Routing mengarahkan request ke View yang sesuai. View kemudian mengambil data dari Database atau memproses data inputan.

Response (Tanggapan): Django mengonversi data (dari database/objek Python) menjadi format JSON (Serialisasi). Data JSON ini dikirim kembali ke Flutter sebagai HTTP Response.

Decoding & Rendering: Flutter menerima respons JSON tersebut. Flutter melakukan decode (mengubah JSON menjadi objek Dart). Terakhir, widget di Flutter diperbarui (biasanya menggunakan FutureBuilder) untuk menampilkan data tersebut ke layar pengguna.

Link Figma: 
