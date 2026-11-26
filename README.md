# UBnetwork Flutter

Aplikasi Android **Native Flutter** offline-first untuk **Daily Production Checksheet (Kanvas Kertas A3 950px)** Underbody Assy PT. TMMIN.

## Fitur Utama
- **Kanvas A3 Interaktif (`InteractiveViewer`):** Pinch-to-zoom 2 jari, pan 1 jari, tombol Zoom (`- | % | +`), Fit-Width (`⛶`), dan D-Pad (`▲ ◀ ▶ ▼`).
- **Tampilan 1:1 UBnetwork Checksheet:** Kop Header TMMIN + Stempel Shift (`RED`/`WHITE`, `DAY`/`NIGHT`), tabel 9 kolom 2 sub-baris (`PLAN`, `ACT`, `DIFF`, `EFF %`), baris `ISTIRAHAT`, ikon ⭐, CBU Auto-Rasio Hamilton-Hare, Master CKD aktual (`57403-KK010` & `57404-KK010`), MP Absensi (24 RED / 19 WHITE), Record No Body & Waktu Sistem, Target & OT, Efisiensi INT/EXT/TOTAL, dan kotak Chokotei INT.
- **Offline-First + 1-Click Sync:** Tersimpan otomatis di penyimpanan lokal HP, lalu kirim 1x klik ke MySQL (`bungtemin.net/ub/api`) & SharePoint (`nudb.bungtemin.net/functions/ub_sp_sync`).
- **Cetak / Export PDF A4:** Render langsung dari `RepaintBoundary` ke PDF HD via `printing`.
