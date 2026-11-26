# Panduan Publish UBnetwork ke Google Play Store

Semua kebutuhan teknis build & signing untuk Google Play Store sudah disiapkan otomatis melalui GitHub Actions.

## 1. Identitas Aplikasi
- **App Name:** `UBnetwork`
- **Package / Application ID:** `com.ubnetwork.apps`
- **Format Rilis Play Store:** `.aab` (Android App Bundle) — otomatis dihasilkan oleh GitHub Actions di setiap push ke `main` dan diunggah ke **GitHub Releases**.
- **Signing:** Sudah ditandatangani dengan Upload Keystore (`alias: ubnetwork`) melalui GitHub Secrets:
  - `ANDROID_KEYSTORE_BASE64`
  - `ANDROID_KEYSTORE_PASSWORD`
  - `ANDROID_KEY_ALIAS`
  - `ANDROID_KEY_PASSWORD`
- **Backup Keystore Lokal:** Tersimpan aman di `~/.android/ubnetwork-upload-keystore.jks` dan `~/.android/ubnetwork-keystore-info.txt` (jangan pernah di-commit ke Git).

## 2. Aset Grafis Play Console (Siap Upload)
- **App Icon (512×512 px):** `assets/playstore/icon_512.png`
- **Feature Graphic (1024×500 px):** `assets/playstore/feature_graphic_1024x500.png`
- **Phone Screenshots (1080×1920 px, 3 file):**
  - `assets/playstore/screenshot_1_canvas.png`
  - `assets/playstore/screenshot_2_input.png`
  - `assets/playstore/screenshot_3_sync_pdf.png`
- **Launcher & Adaptive Icon:** `assets/icon/app_icon.png` & `assets/icon/app_icon_foreground.png` (otomatis digenerate ke `mipmap-*` saat build via `flutter_launcher_icons`).

## 3. Teks Store Listing (Global & Sesuai Kebijakan)
- **Short Description (maks 80 karakter):**
  `Aplikasi Record Daily Control, lembar kerja digital interaktif & ekspor PDF.`
- **Full Description:**
  ```text
  UBnetwork adalah aplikasi utilitas Record Daily Control dan manajemen lembar kerja digital interaktif berbasis offline-first untuk pencatatan aktivitas harian, pemantauan target berkala, kolaborasi tim, dan dokumentasi kerja terstruktur.

  Fitur Utama:
  • Record Daily Control (Kanvas Lembar Kerja Digital): Navigasi kanvas interaktif dengan fitur cubit dua jari (pinch-to-zoom), geser bebas ke segala arah, kontrol presisi ukuran layar, serta tampilan lembar kerja yang rapi dan responsif.
  • Pencatatan Langsung & Praktis: Ketuk langsung pada kolom lembar kerja untuk mencatat rencana harian, capaian aktual, kehadiran anggota tim, evaluasi kendala, serta catatan tindak lanjut.
  • Manajemen Aktivitas & Kolaborasi: Dilengkapi papan catatan tugas harian, jadwal kegiatan berkala, evaluasi peningkatan berkelanjutan, serta pengelolaan dokumen kerja dalam satu aplikasi terpadu.
  • Offline-First & Sinkronisasi Cloud: Data tersimpan otomatis di perangkat meskipun tanpa koneksi internet dan dapat disinkronkan secara aman ke cloud kapan saja.
  • Ekspor & Cetak Dokumen PDF: Ekspor lembar kerja harian langsung ke format dokumen PDF beresolusi tinggi yang siap dibagikan atau dicetak.
  ```

## 4. Langkah Upload di Google Play Console
1. Buka **GitHub Releases** repo `tmminunion/ubnetworkFlutter` (atau klik link dari notif Telegram) dan unduh file **`UBnetwork-v...-release.aab`**.
2. Buka [Google Play Console](https://play.google.com/console) → **Create app** → isi nama `UBnetwork`, App, Free.
3. Di menu **App integrity**, aktifkan **Play App Signing** (default Google Play).
4. Isi **Store listing** menggunakan aset di `assets/playstore/` dan screenshot layar HP (minimal 2 screenshot).
5. Isi **App content**:
   - **Privacy Policy:** isi dengan URL publik `https://ubnetwork.vercel.app/privacy` (halaman web, bisa dibuka tanpa login).
   - **Ads:** No, my app does not contain ads.
   - **Data safety:** Offline storage lokal + optional HTTPS sync internal; tidak dibagikan ke pihak ketiga.
6. Upload file `.aab` ke track **Internal testing** / **Closed testing** / **Production**, lalu klik **Review & roll out**.
