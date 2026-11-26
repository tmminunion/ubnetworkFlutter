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

### Fase 8 — Refactoring 1:1 Data API & Mutasi Server (Audit Lanjutan)
- [x] **8.0a (Kritis)** `/productivity/checksheet` — Koneksi MySQL 1:1 tanpa paralel burst timeout, validasi wajib cookie `ub_gate` + auto re-login saat `401`, modal loading blokir input (`Memuat Data Checksheet`), hidrasi penuh `get_report` + `monthly_plan` + `get_settings` + `get_members` (aman terhadap string angka DECIMAL PHP), & cetak PDF A3 Landscape presisi.
- [x] **8.0b (Kritis)** `/safety/temuan` & Kaizen Safety — Sinkron penuh MongoDB Atlas `GET /api/findings?limit=200` (multi-page), mutasi 1:1 `PATCH /api/findings/[id]` & `POST /api/findings` (termasuk `closedAt` & resolusi gambar `nudb.bungtemin.net`), kartu Before–After (toggleable Horizontal & Vertikal + zoom foto), serta kanvas kertas fisik i-Reporter `KAIZEN REPORT · SAFETY` (Horizontal A4 & Vertikal A4 + cetak/share PDF).
- [ ] **8.1 (P0)** `/quality/daily/out` & `/quality/daily/in` — Sambungkan CRUD `POST / PUT / DELETE /api/quality/findings` dan sesuaikan skema `inRed`/`inWhite`/`inTarget` pada `/api/quality/defect` agar temuan tidak tertimpa saat reload.
- [ ] **8.2 (P0)** `/productivity/chokotei-manual` — Sambungkan CRUD `GET / POST / PATCH / DELETE /api/chokotei-manual` ke MongoDB Atlas (saat ini baru `SharedPreferences` lokal).
- [ ] **8.3 (P0)** `/bacadoa` & `/hr/rankmp` — Ambil anggota aktif live dari `/api/ub?action=get_members` (`role == 'TM'`, pertahankan `id` asli MySQL), tarik skor `/api/hr/rankmp`, riwayat `/api/hr/bacadoa?action=history`, & kanvas kertas fisik i-Reporter A4 Matrik Baca Doa.
- [ ] **8.4 (P0)** `KaizenActivityStore` & `UbdriveScreen` — Migrasikan semua request HTTP langsung ke `UbWebApi.instance` agar ekstraksi cookie `ub_gate` & header identitas konsisten.
- [ ] **8.5 (P1)** `/idnu` (Idea Innovation Portal) — Sambungkan `/api/idnu/auth`, `/api/idnu/check-title`, `/api/idnu/submit`, `/api/idnu/outstanding`, dan `/api/idnu/recap`.
- [ ] **8.6 (P1)** `/productivity/tasks`, `/productivity/settings`, `/productivity/monitoring`, `/productivity/kaizen`, & `/productivity/after-prod` — Sambungkan `POST /api/task?action=add_task`, halaman penuh `save_settings` (CBU ratio, CKD, Service Parts), `save_monthly_plan` & `delete_report` di Monitoring 1–31, tab Chokotei Solved di Kaizen Report, dan auto-sync absensi + WA bot di After-Prod.
- [ ] **8.7 (P2)** Modul & Media Tambahan — Tambah modul **Voice Member (`/vm`)** + widget Hub, **Andon Live Monitor (`/andon`)** (Quick App ke-11), **Upload Foto Before/After (`/api/upload`)**, **Share Forum WA Checksheet (`/api/productivity/share-wa`)**, **Upload/Preview File UBdrive**, & **Display KPI Editor (`/display/edit`)**.
