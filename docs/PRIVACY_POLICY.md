# Kebijakan Privasi — UBnetwork

> Versi web resmi (URL untuk Google Play): **https://ubnetwork.vercel.app/privacy**

**Terakhir diperbarui:** 26 November 2026

**UBnetwork** adalah aplikasi Android offline-first untuk pencatatan **Daily Production Checksheet (Kanvas A3)** di lingkungan produksi Underbody Assy PT. TMMIN.

## 1. Data yang Disimpan
- Data checksheet produksi (plan, aktual, absensi MP, chokotei, dan catatan shift) disimpan **secara lokal** di perangkat pengguna menggunakan `SharedPreferences`.
- Aplikasi **tidak** mengumpulkan data lokasi GPS, kontak, foto pribadi, atau data periklanan pihak ketiga.

## 2. Sinkronisasi Server
- Apabila pengguna menekan tombol **Sync**, data produksi yang diinput akan dikirim ke server internal yang telah ditentukan (`bungtemin.net/ub/api` dan `nudb.bungtemin.net/functions/ub_sp_sync`) melalui koneksi HTTPS.

## 3. Iklan & Analitik Pihak Ketiga
- Aplikasi ini **bebas iklan** dan **tidak** menggunakan SDK analitik pihak ketiga.

## 4. Kontak
Untuk pertanyaan terkait privasi atau dukungan teknis, hubungi tim pengembang melalui repository GitHub `tmminunion/ubnetworkFlutter`.
