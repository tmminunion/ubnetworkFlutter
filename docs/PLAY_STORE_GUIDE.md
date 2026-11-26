# Panduan Publish UBnetwork ke Google Play Store

Semua kebutuhan teknis build & signing untuk Google Play Store sudah disiapkan otomatis melalui GitHub Actions.

## 1. Identitas Aplikasi
- **App Name:** `UBnetwork`
- **Package / Application ID:** `com.tmmin.ub.ubnetwork_flutter`
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

## 3. Teks Store Listing (Siap Copy-Paste)
- **Short Description (maks 80 karakter):**
  `Checksheet produksi A3 offline-first dengan zoom, sync & export PDF A4.`
- **Full Description:**
  ```text
  UBnetwork adalah aplikasi checksheet produksi harian (Kanvas Kertas A3) berbasis offline-first untuk kebutuhan pencatatan lini produksi Underbody Assy.

  Fitur Utama:
  • Kanvas A3 Interaktif: Zoom cubit 2 jari, geser bebas, tombol zoom presisi, Fit-Width, dan navigasi D-Pad.
  • Input Langsung di Kertas: Tap sel untuk mengisi Plan, Aktual, Absensi MP, Chokotei, dan catatan shift (RED/WHITE, DAY/NIGHT).
  • Offline-First + 1-Click Sync: Data tersimpan otomatis di perangkat dan dapat disinkronkan ke server produksi saat online.
  • Export & Cetak PDF A4: Cetak langsung checksheet ke PDF resolusi tinggi.
  ```

## 4. Langkah Upload di Google Play Console
1. Buka **GitHub Releases** repo `tmminunion/ubnetworkFlutter` (atau klik link dari notif Telegram) dan unduh file **`UBnetwork-v...-release.aab`**.
2. Buka [Google Play Console](https://play.google.com/console) → **Create app** → isi nama `UBnetwork`, App, Free.
3. Di menu **App integrity**, aktifkan **Play App Signing** (default Google Play).
4. Isi **Store listing** menggunakan aset di `assets/playstore/` dan screenshot layar HP (minimal 2 screenshot).
5. Isi **App content**:
   - **Privacy Policy:** tautkan ke `docs/PRIVACY_POLICY.md` (atau halaman web privacy policy).
   - **Ads:** No, my app does not contain ads.
   - **Data safety:** Offline storage lokal + optional HTTPS sync internal; tidak dibagikan ke pihak ketiga.
6. Upload file `.aab` ke track **Internal testing** / **Closed testing** / **Production**, lalu klik **Review & roll out**.
