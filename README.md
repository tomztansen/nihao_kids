# 🐼 NiHao Kids - Aplikasi Belajar Bahasa Mandarin Anak (TK & SD)

Aplikasi Android interaktif yang dirancang khusus untuk anak-anak belajar bahasa Mandarin secara ceria (*gamified learning*), terbagi berdasarkan tingkatan sekolah (Grade), dan dilengkapi integrasi iklan Google AdMob yang mematuhi **Google Play Families Policy** (COPPA Compliant).

---

## 🚀 1. Coba Prototipe Interaktif Langsung (Tanpa Setup)

Anda bisa langsung melihat tampilan aplikasi, animasi maskot Panda Bao Bao, suara pengucapan bahasa Mandarin asli, dan mini game kuis saat ini juga:
1. Buka folder: D:\PROJECT GMN\nihao\preview\
2. Klik dua kali berkas **index.html** untuk membukanya di browser (Google Chrome / Microsoft Edge).
3. Anda dapat langsung:
   - Memilih Grade (TK, SD 1-3, SD 4-6).
   - Menjelajahi Peta Petualangan.
   - Memutar pengucapan suara Mandarin dengan pelafalan asli (*Speech Synthesis*).
   - Memainkan Kuis Bintang.
   - Menguji simulasi **AdMob Rewarded Video** untuk klaim Bambu & Bintang.

---

## 📂 2. Struktur Proyek Flutter

`
D:\PROJECT GMN\nihao\
├── pubspec.yaml                     # Konfigurasi package Flutter & AdMob
├── android/
│   └── app/src/main/
│       └── AndroidManifest.xml      # Konfigurasi AdMob App ID & Internet Permission
├── lib/
│   ├── main.dart                    # Titik masuk utama aplikasi (Inisialisasi AdMob COPPA)
│   ├── theme/
│   │   └── app_theme.dart           # Palet warna ceria, font ramah anak, pedagogi warna nada
│   ├── models/
│   │   └── models.dart              # Model Grade, Lesson, Vocab, dan Kuis
│   ├── data/
│   │   └── curriculum_data.dart     # Kurikulum YCT Mandarin berjenjang (TK, SD 1-3, SD 4-6)
│   ├── services/
│   │   ├── admob_service.dart       # Pengelola AdMob Test IDs (COPPA & Families Compliant)
│   │   └── audio_service.dart       # Pengelola suara & pelafalan Mandarin
│   ├── widgets/
│   │   ├── panda_avatar.dart        # Komponen Maskot Panda (Bao Bao)
│   │   └── kid_button.dart          # Tombol 3D empuk yang disukai anak
│   └── screens/
│       ├── grade_selection_screen.dart # Layar utama pilih tingkat sekolah
│       ├── lesson_map_screen.dart      # Peta petualangan berlevel (Candy Crush style)
│       ├── flashcard_screen.dart       # Kartu belajar Hanzi, Pinyin bernada, & Suara
│       └── quiz_screen.dart            # Kuis tebak arti & nada dengan hadiah bintang
└── preview/
    └── index.html                   # Simulator web interaktif mandiri
`

---

## 🛡️ 3. Kepatuhan Iklan Anak (Google Play Families Policy & COPPA)

Sesuai aturan ketat Google Play Store untuk aplikasi anak di bawah 13 tahun, berkas lib/services/admob_service.dart telah menerapkan konfigurasi wajib:
- 	agForChildDirectedTreatment: TagForChildDirectedTreatment.yes (Menandai bahwa penonton adalah anak-anak).
- maxAdContentRating: MaxAdContentRating.g (Hanya iklan kategori umum ramah keluarga).
- **Format Iklan Rewarded:** Pemain hanya menonton video singkat secara sukarela saat ingin mengklaim bonus koin bambu atau membuka kostum maskot panda.

### Unit ID AdMob Test yang Terpasang:
- **Sample App ID:** ca-app-pub-3940256099942544~3347511713
- **Rewarded Video Test:** ca-app-pub-3940256099942544/5224354917
- **Banner Test:** ca-app-pub-3940256099942544/6300978111

> **Catatan Sebelum Rilis ke Play Store:** Ganti ID di atas dengan ID asli dari dasbor Google AdMob Anda, lalu pastikan mencentang program **Designed for Families** di Google Play Console.

---

## 🛠️ 4. Cara Menjalankan dengan Flutter CLI / Android Studio

Jika Anda sudah menginstal Flutter SDK dan Android Studio:
1. Buka terminal di folder ini:
   `ash
   cd D:\PROJECT GMN\nihao
   `
2. Unduh paket dependensi:
   `ash
   flutter pub get
   `
3. Hubungkan ponsel Android atau jalankan Android Emulator, lalu:
   `ash
   flutter run
   `
