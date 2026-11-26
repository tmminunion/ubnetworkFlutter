# UBnetwork Flutter — 1:1 Migration Plan & Todo

Dokumen ini menjadi acuan resmi migrasi 1:1 dari `ubnetwork` (Next.js Web) ke `ubnetworkFlutter` (Native Flutter Offline-First Android).

## Siklus Kerja Wajib per Pekerjaan
1. Baca kode sumber web `ubnetwork/app/...` secara menyeluruh (perbandingan 1:1).
2. Bangun model, store (offline-first + sync), dan layar native Flutter.
3. Tambah / perbarui unit test (`test/`).
4. Pengecekan total: commit, push ke `main`, verifikasi GitHub Actions (`Static Analysis` + `Run Unit Tests` + `Build APK & AAB`) hijau.
5. Update checklist di file ini dan pindah ke pekerjaan selanjutnya.

---

## Matriks Perbandingan 1:1 (Web vs Flutter)

| Area / Route | Modul Web | Status Flutter | Catatan |
| :--- | :--- | :--- | :--- |
| `/` (Home Hub) | Top Bar macOS, Display & Monitor, 6 Pilar `SQPCEHR`, 5 Kaizen, 11 Quick App | **Selesai (1:1)** | `lib/features/hub/hub_screen.dart` |
| `/display` (GL Board Hub) | 7 Pilar × 4 Kertas KPI (28 board) | **28 / 28 Native** | `lib/features/display/display_paper_screen.dart` |
| `/monitor` (Slide Show TV) | Khusus TV Display Web Next.js | **Dihapus dari APK** | Tidak dipakai di mobile APK (khusus TV shopfloor) |
| `/productivity` | 14 modul | **14 / 14 Native** | **Selesai 100%** |
| `/safety` | 7 modul APK | **7 / 7 Native** | **Selesai 100%** (6 operasional + 1 Display Proses KPI) |
| `/quality` | 6 modul | **6 / 6 Native** | **Selesai 100%** (2 operasional + 4 Display KPI) |
| `/cost` | 6 modul | **6 / 6 Native** | **Selesai 100%** (2 operasional + 4 Display KPI) |
| `/env` | 7 modul | **7 / 7 Native** | **Selesai 100%** (3 operasional + 4 Display KPI) |
| `/hr` | 9 modul | **9 / 9 Native** | **Selesai 100%** (5 operasional + 4 Display KPI) |
| Kaizen & Quick App Dx | 5 Kaizen + 11 Quick App | **Selesai (1:1)** | QCC, TPM, 5R, SW, Henkaten, Post-It, UBdrive, Docs |

---

## Todo Bertahap

### Fase 0 — Fondasi & Hub 1:1
- [x] Home Hub 1:1 (`SQPCEHR`, `Display KPI`, `Monitor`, `Aktivitas Kaizen`, `UB Quick App Dx`)
- [x] Display KPI GL Management Board Hub (`/display`)
- [x] 6 Sub-Hub Shells (`/safety`, `/quality`, `/productivity`, `/cost`, `/hr`, `/env`)
- [x] Dokumen `MIGRATION_PLAN.md`

### Fase 1 — Pilar Safety (`/safety`) — **SELESAI 8/8 NATIVE**
- [x] **1.1** `/safety/temuan` — Temuan Safety
- [x] **1.2** `/kyt/monitoring` — KYT Monitoring 12 Bulan
- [x] **1.3** `/safety/group` — Group SGA
- [x] **1.4** `/safety/device` — Safety Device & Interlock
- [x] **1.5** `/safety/bira` — BIRA
- [x] **1.6** `/safety/kpi` — Safety KPI & Zero Accident

### Fase 2 — Pilar Quality (`/quality`) — **SELESAI 6/6 NATIVE**
- [x] **2.1** `/quality/daily/out` — Defect Out Flow
- [x] **2.2** `/quality/daily/in` — Defect In Proses

### Fase 3 — Pilar Productivity Lanjutan (`/productivity`) — **SELESAI 14/14 NATIVE**
- [x] **3.1** `/productivity/monitoring`
- [x] **3.2** `/productivity/chokotei` & `/productivity/chokotei-manual`
- [x] **3.3** `/productivity/cbu` & `/productivity/ckd`
- [x] **3.4** `/productivity/roster` & `/productivity/absensi`
- [x] **3.5** `/productivity/after-prod`, `/productivity/tasks`, `/productivity/shift-template`, `/productivity/kaizen`

### Fase 4 — Pilar Cost (`/cost`) & Environment (`/env`) — **SELESAI 13/13 NATIVE**
- [x] **4.1** `/cost/daily` & `/cost/temuan`
- [x] **4.2** `/env/air-leakage` (`#lub` & `#klub`), `/env/daily` (kWh), `/env/temuan`

### Fase 5 — Pilar HR & Morale (`/hr`) — **SELESAI 9/9 NATIVE**
- [x] **5.1** `/bacadoa` — Jadwal & Matrik Baca Doa Asare 1–31
- [x] **5.2** `/hr/rankmp` — Rank MP
- [x] **5.3** `/hr/idea`, `/idnu` (Idea), `/hr/temuan`

### Fase 6 — Display KPI 16:9 (`/display`) & Monitor (`/monitor`) — **SELESAI 100%**
- [x] **6.1** Kertas `Main KPI`, `Sub KPI`, `Proses KPI`, `Kaizen` (7 Pilar × 4 Kertas = 28 Board Live Offline-First, Zoomable)
- [x] **6.2** `/monitor` — Dihapus dari APK (khusus TV Display Next.js)

### Fase 7 — Quick App Dx & Aktivitas Kaizen — **SELESAI 100%**
- [x] **7.1** Henkaten Board, Post-It Board, UBdrive, Dokumentasi
- [x] **7.2** QCC, TPM, 5R / 5S, SW Observasi
