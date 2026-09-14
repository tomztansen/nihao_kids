# Panduan Lengkap: Integrasi Unity Ads (Sistem Hybrid Fallback) - NiHao Kids

Panduan ini memandu Anda langkah-demi-langkah dari membuat akun hingga menerima pembayaran pendapatan iklan dari **Unity Ads**.

Aplikasi **NiHao Kids** telah dilengkapi sistem **Hybrid Ads Waterfall**:
* 🥇 **Prioritas 1 (Google AdMob):** Ditayangkan pertama kali untuk memaksimalkan pendapatan eCPM.
* 🥈 **Prioritas 2 (Unity Ads Fallback):** Jika Google AdMob gagal memuat (*no fill* / kuota habis / offline / error), sistem otomatis beralih menayangkan video iklan **Unity Ads**!
* 👶 **Kepatuhan Anak (COPPA):** Kedua jaringan iklan telah dikunci agar hanya menayangkan iklan ramah keluarga (Rating G).

---

## 🛠️ Langkah 1: Mendaftar Akun Unity Gaming Services (Gratis)

1. Buka situs resmi Unity Gaming Services di browser:  
   👉 **[https://cloud.unity.com](https://cloud.unity.com)**
2. Klik tombol **Sign in** atau **Create a Unity ID**.
3. Anda bisa langsung memilih **Continue with Google** (gunakan akun Gmail Anda) untuk pendaftaran 1-klik.

---

## 📱 Langkah 2: Membuat Proyek & Mengaktifkan Monetisasi

1. Di halaman utama Unity Dashboard, klik tombol **Create Project** (di pojok kanan atas).
2. Beri nama proyek: `NiHao Kids` lalu klik **Create**.
3. Di bilah navigasi sebelah kiri, cari menu **Monetization** lalu klik **Ads**.
4. Klik tombol **Get Started** atau **Set up Unity Ads**.
5. Muncul pertanyaan mediasi:
   * Pilih opsi: **"I am only using Unity Ads"** (atau "Third-party mediation").
6. ⚠️ **PENTING - Kepatuhan COPPA (Wajib untuk Aplikasi Anak):**
   * Saat ditanya *"Is this app directed to children under 13?"*, **PILIH "YES"**.
   * Opsi ini memastikan Unity Ads memfilter seluruh iklan dewasa dan hanya menampilkan iklan yang 100% aman untuk anak-anak (kategori Rating G / Google Play Families).

---

## 🔑 Langkah 3: Mengambil Android Game ID & Placement
1. Di menu Monetization Unity Dashboard, klik submenu **Ad Units** / **Placements**.
2. Anda akan melihat informasi proyek **NiHao Kids**:
   * **Android Game ID:** `800372977`
   * **Rewarded Placement:** `BP_Rewarded_Android` (Status: *Active*)
   * **Interstitial Placement:** `BP_Interstitial_Android` (Status: *Active*)
   * **Banner Placement:** `BP_Banner_Android` (Status: *Active*)

---

## ✏️ Langkah 4: Memasang Game ID ke Kode Aplikasi (SUDAH TERPASANG)
Game ID resmi Anda telah langsung dipasang ke dalam berkas kode:
📂 **[`D:\PROJECT GMN\nihao\lib\services\admob_service.dart`](file:///D:/PROJECT%20GMN/nihao/lib/services/admob_service.dart)**:
```dart
static const String unityGameId = '800372977';
static const String unityRewardedPlacementId = 'BP_Rewarded_Android';
```
*(Anda tidak perlu mengedit apa-apa lagi, kode sudah 100% tersambung ke akun Unity Ads Anda!)*

---

## 💳 Langkah 5: Pengaturan Rekening Pencairan Pendapatan (Payout)

Pendapatan dari penayangan iklan Unity Ads bisa langsung ditransfer ke rekening bank lokal Anda:
1. Di Unity Dashboard, klik menu profil Anda di pojok kiri bawah lalu pilih **Finances** > **Payout Profile**.
2. Masukkan identitas pemilik akun (nama sesuai KTP).
3. Pilih metode pencairan dana:
   * **Bank Transfer (Wire Transfer):** Mendukung bank di Indonesia (BCA, Mandiri, BRI, BNI, CIMB Niaga, dll. Cukup masukkan kode SWIFT bank Anda dan nomor rekening).
   * **PayPal:** Masukkan alamat email akun PayPal Anda.
4. Pembayaran akan ditransfer otomatis setiap bulan saat saldo mencapai batas minimum pembayaran.

---

## 🚀 Langkah 6: Build Ulang & Rilis Otomatis

Setelah Anda mengubah Game ID, cukup simpan dan kirim ke GitHub dengan perintah berikut:
```bash
git commit -am "chore: update live unity ads game id"
git push origin main
```
Server cloud GitHub Actions akan **otomatis meng-compile ulang file `.apk` dan `.aab` terbaru dalam 3 menit**!
