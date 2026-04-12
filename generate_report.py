"""
UtangKU - Progress Report PDF Generator
Kelompok: Aplikasi Bergerak
"""

from fpdf import FPDF
from datetime import date


class ProgressPDF(FPDF):
    def header(self):
        # Header bar
        self.set_fill_color(255, 107, 0)  # Orange
        self.rect(0, 0, 210, 25, 'F')
        self.set_font('Helvetica', 'B', 16)
        self.set_text_color(255, 255, 255)
        self.set_xy(10, 7)
        self.cell(0, 10, 'UTANGKU - LAPORAN PROGRESS', ln=True, align='C')
        self.set_font('Helvetica', '', 10)
        self.set_xy(10, 16)
        self.cell(0, 6, 'Aplikasi Pencatatan Utang Piutang dengan WhatsApp Integration', ln=True, align='C')
        self.set_text_color(0, 0, 0)

    def footer(self):
        self.set_y(-15)
        self.set_font('Helvetica', 'I', 8)
        self.set_text_color(128, 128, 128)
        self.cell(0, 10, f'UtangKU Progress Report - Halaman {self.page_no()}', ln=True, align='C')


def add_section_title(pdf, title):
    pdf.set_fill_color(255, 107, 0)
    pdf.rect(10, pdf.get_y(), 190, 8, 'F')
    pdf.set_font('Helvetica', 'B', 11)
    pdf.set_text_color(255, 255, 255)
    pdf.set_xy(14, pdf.get_y() + 1)
    pdf.cell(0, 6, title, ln=True)
    pdf.set_text_color(0, 0, 0)
    pdf.ln(4)


def add_subsection_title(pdf, title):
    pdf.set_font('Helvetica', 'B', 10)
    pdf.set_text_color(255, 107, 0)
    pdf.cell(0, 6, title, ln=True)
    pdf.set_text_color(0, 0, 0)
    pdf.ln(1)


def add_checkmark_item(pdf, text, indent=4):
    pdf.set_font('Helvetica', '', 9)
    pdf.set_x(10 + indent)
    pdf.cell(5, 5, '[v]', ln=False)  # checkmark
    pdf.multi_cell(175, 5, text)


def add_bullet_item(pdf, text, indent=4):
    pdf.set_font('Helvetica', '', 9)
    pdf.set_x(10 + indent)
    pdf.cell(5, 5, '-', ln=False)
    pdf.multi_cell(175, 5, text)


pdf = ProgressPDF('P', 'mm', 'A4')
pdf.set_auto_page_break(auto=True, margin=20)
pdf.add_page()

# ─── INFO HEADER ────────────────────────────────────────────────────────────
pdf.ln(4)

# Judul utama
pdf.set_font('Helvetica', 'B', 14)
pdf.set_text_color(255, 107, 0)
pdf.cell(0, 8, 'LAPORAN PROGRESS TUGAS KELOMPOK', ln=True, align='C')
pdf.set_text_color(0, 0, 0)
pdf.set_font('Helvetica', 'B', 12)
pdf.cell(0, 6, 'Aplikasi Mobile: UtangKU', ln=True, align='C')
pdf.ln(2)

# Tabel info dasar
pdf.set_fill_color(245, 245, 245)
pdf.set_font('Helvetica', '', 9)
info_data = [
    ('Mata Kuliah', 'Aplikasi Bergerak'),
    ('Nama Aplikasi', 'UtangKU'),
    ('Platform', 'Flutter (Dart)'),
    ('Database', 'SQLite (sqflite)'),
    ('State Management', 'Provider'),
    ('Tanggal Laporan', date.today().strftime('%d %B %Y')),
    ('Overall Progress', '~40% Complete'),
]
col_w = [55, 135]
for key, val in info_data:
    pdf.set_fill_color(240, 240, 240)
    pdf.rect(40, pdf.get_y(), 130, 7, 'F')
    pdf.set_xy(40, pdf.get_y())
    pdf.set_font('Helvetica', 'B', 9)
    pdf.cell(col_w[0], 7, f'  {key}', ln=False)
    pdf.set_font('Helvetica', '', 9)
    pdf.cell(col_w[1], 7, val, ln=True)
pdf.ln(6)

# ─── SECTION 1: DESKRIPSI PROYEK ───────────────────────────────────────────
add_section_title(pdf, '1. Deskripsi Proyek')

pdf.set_font('Helvetica', '', 9)
pdf.multi_cell(190, 5,
    'UtangKU adalah aplikasi mobile berbasis Flutter yang dirancang untuk membantu pengguna '
    'mencatat dan mengelola utang dan piutang mereka. Aplikasi ini terintegrasi langsung dengan '
    'WhatsApp untuk memudahkan proses penagihan. Dibangun menggunakan Dart/Flutter dengan SQLite '
    'sebagai database lokal dan Provider untuk state management.'
)
pdf.ln(3)

add_subsection_title(pdf, 'Fitur Utama:')
features = [
    'Add/Edit/Delete data utang dan piutang',
    'Pemisahan Utang (yang Anda hutang) dan Piutang (yang orang lain hutang ke Anda)',
    'Filter berdasarkan status pembayaran (Lunas / Belum Lunas)',
    'Deteksi jatuh tempo otomatis dengan peringatan',
    'Integrasi WhatsApp untuk pengiriman pesan tagihan otomatis',
    'Dashboard ringkasan keuangan',
    'Local database storage dengan SQLite',
]
for f in features:
    add_bullet_item(pdf, f)
pdf.ln(4)

# ─── SECTION 2: TAMPILAN APLIKASI ───────────────────────────────────────────
add_section_title(pdf, '2. Tampilan Aplikasi')

screenshots_note = [
    ('Splash Screen', 'Layar pembuka aplikasi dengan animasi/logo UtangKU'),
    ('Dashboard / Home', 'Halaman utama menampilkan ringkasan saldo, total utang, total piutang, dan transaksi terbaru'),
    ('Daftar Utang', 'Halaman daftar utang dengan filter status dan aksi cepat (tagih via WA)'),
    ('Daftar Piutang', 'Halaman daftar piutang dengan filter dan integrasi WhatsApp'),
    ('Form Tambah / Edit', 'Forminput untuk menambah atau mengedit data utang/piutang'),
    ('Settings', 'Pengaturan aplikasi'),
]
for name, desc in screenshots_note:
    pdf.set_fill_color(245, 245, 245)
    pdf.rect(10, pdf.get_y(), 190, 7, 'F')
    pdf.set_xy(14, pdf.get_y() + 1)
    pdf.set_font('Helvetica', 'B', 9)
    pdf.cell(55, 5, name, ln=False)
    pdf.set_font('Helvetica', '', 9)
    pdf.multi_cell(120, 5, desc)
pdf.ln(4)

# ─── SECTION 3: FITUR YANG SUDAH DIBANGUN ──────────────────────────────────
add_section_title(pdf, '3. Fitur yang Sudah Dibangun (Phase 1 & 2)')

phases = [
    ('Phase 1: Setup & Foundation (100%)', [
        'Struktur proyek Flutter dengan folder yang terorganisir',
        'Konfigurasi pubspec.yaml dengan semua dependencies',
        'Setup tema Material 3 dengan warna orange (#FF6B00)',
        'Database helper SQLite dengan schema lengkap',
        'Model data (DebtModel, DebtType, PaymentStatus)',
        'Provider state management',
        'WhatsApp service untuk generate pesan tagihan',
        'Formatters untuk mata uang IDR dan tanggal lokal Indonesia',
    ]),
    ('Phase 2: Full CRUD Functionality (100%)', [
        'Add Debt Screen - Form lengkap dengan validasi, date picker, live preview',
        'Debt List Screen - Daftar utang dengan filter (Semua/Belum Lunas/Lunas)',
        'Piutang List Screen - Daftar piutang dengan filter dan aksisama',
        'WhatsApp Integration - Tombol "Tagih via WhatsApp" dengan pesan otomatis',
        'Toggle Status - Tandai Lunas / Belum Lunas dengan konfirmasi',
        'Long-press menu - Edit dan Delete dengan dialog konfirmasi',
        'Overdue detection - Peringatan otomatis untuk yang lewat jatuh tempo',
        'Empty state handling - Tampilan khusus ketika belum ada data',
    ]),
]

for phase_title, items in phases:
    pdf.set_font('Helvetica', 'B', 9)
    pdf.set_text_color(56, 142, 60)  # Green
    pdf.cell(0, 6, phase_title, ln=True)
    pdf.set_text_color(0, 0, 0)
    for item in items:
        add_checkmark_item(pdf, item, indent=6)
    pdf.ln(3)

# ─── SECTION 4: STRUKTUR KODE ───────────────────────────────────────────────
add_section_title(pdf, '4. Struktur Kode / File')

# Folder structure table
pdf.set_font('Helvetica', 'B', 9)
pdf.cell(0, 6, 'Direktori lib/', ln=True)
pdf.set_font('Helvetica', '', 8)

structure = [
    ('lib/main.dart', 'Entry point aplikasi'),
    ('lib/models/', 'Data models (debt_model.dart, debt_type.dart, payment_status.dart)'),
    ('lib/database/', 'Database helper & service (SQLite CRUD)'),
    ('lib/screens/home/', 'Splash screen & Dashboard/Home screen'),
    ('lib/screens/debt/', 'Add debt screen & Debt list screen'),
    ('lib/screens/piutang/', 'Piutang list screen'),
    ('lib/screens/settings/', 'Settings screen'),
    ('lib/services/', 'WhatsApp service & Mock service'),
    ('lib/utils/', 'Theme, constants, formatters (IDR currency, tanggal Indonesia)'),
    ('lib/providers/', 'DebtProvider - State management'),
]

fill_colors = [255, 248]
row = 0
for path, desc in structure:
    c = fill_colors[row % 2]
    pdf.set_fill_color(c, c, c)
    pdf.set_font('Courier', '', 7.5)
    pdf.cell(65, 5, f'  {path}', ln=False)
    pdf.set_font('Helvetica', '', 8)
    pdf.multi_cell(120, 5, desc)
    row += 1

pdf.ln(3)
add_subsection_title(pdf, 'Total Lines of Code (Phase 1 & 2):')
pdf.set_font('Helvetica', '', 9)
pdf.cell(0, 5, '  - add_debt_screen.dart      : ~380 baris', ln=True)
pdf.cell(0, 5, '  - debt_list_screen.dart      : ~430 baris', ln=True)
pdf.cell(0, 5, '  - piutang_list_screen.dart   : ~440 baris', ln=True)
pdf.cell(0, 5, '  - home_screen.dart + splash : ~200 baris', ln=True)
pdf.cell(0, 5, '  - database_helper.dart        : ~150 baris', ln=True)
pdf.set_font('Helvetica', 'B', 9)
pdf.cell(0, 5, '  - Total: ~1.600+ baris kode production-ready!', ln=True)
pdf.ln(4)

# ─── SECTION 5: TECHNOLOGY STACK ────────────────────────────────────────────
add_section_title(pdf, '5. Technology Stack')

stack_data = [
    ('Framework', 'Flutter (Dart)', 'Cross-platform mobile development'),
    ('Language', 'Dart', 'Bahasa pemrograman utama'),
    ('Database', 'SQLite (sqflite ^2.3.0)', 'Local database storage'),
    ('State Mgmt', 'Provider (^6.1.1)', 'State management'),
    ('UI', 'Material Design 3', 'Desain antarmuka pengguna'),
    ('Charts', 'fl_chart (^0.66.0)', 'Visualisasi data (prepared)'),
    ('WhatsApp', 'url_launcher + whatsapp_unilink', 'Integrasi WhatsApp'),
    ('Date/Time', 'intl + table_calendar', 'Formatting & kalender'),
    ('Icons', 'cupertino_icons', 'Ikon iOS-style'),
]

col_widths = [35, 55, 95]
pdf.set_font('Helvetica', 'B', 8.5)
pdf.set_fill_color(255, 107, 0)
pdf.set_text_color(255, 255, 255)
pdf.cell(col_widths[0], 6, '  Kategori', ln=False)
pdf.cell(col_widths[1], 6, '  Teknologi', ln=False)
pdf.cell(col_widths[2], 6, '  Keterangan', ln=True)
pdf.set_text_color(0, 0, 0)

for i, (cat, tech, ket) in enumerate(stack_data):
    c = 245 if i % 2 == 0 else 255
    pdf.set_fill_color(c, c, c)
    pdf.set_font('Helvetica', '', 8.5)
    pdf.cell(col_widths[0], 5, f'  {cat}', ln=False)
    pdf.set_font('Courier', '', 8.5)
    pdf.cell(col_widths[1], 5, tech, ln=False)
    pdf.set_font('Helvetica', '', 8.5)
    pdf.cell(col_widths[2], 5, ket, ln=True)
pdf.ln(4)

# ─── SECTION 6: PROGRESS CHART (ASCII) ─────────────────────────────────────
add_section_title(pdf, '6. Grafik Progress per Phase')

pdf.set_font('Helvetica', 'B', 9)
pdf.cell(0, 6, 'Phase Progress:', ln=True)

progress_data = [
    ('Phase 1: Setup & Foundation', 100),
    ('Phase 2: Full CRUD', 100),
    ('Phase 3: Statistics & Charts', 0),
    ('Phase 4: Notifications', 0),
    ('Phase 5: Security (PIN/Biometric)', 0),
]

max_bar = 100
bar_width = 140
label_w = 65

for label, pct in progress_data:
    pdf.set_font('Helvetica', '', 8.5)
    pdf.cell(label_w, 5, f'  {label}', ln=False)
    filled = int((pct / 100) * bar_width)
    empty = bar_width - filled
    pdf.set_fill_color(255, 107, 0)
    pdf.rect(pdf.get_x(), pdf.get_y() + 1, filled, 4, 'F')
    if empty > 0:
        pdf.set_fill_color(230, 230, 230)
        pdf.rect(pdf.get_x() + filled, pdf.get_y() + 1, empty, 4, 'F')
    pdf.set_font('Helvetica', 'B', 8)
    pdf.set_x(pdf.get_x() + bar_width + 4)
    color = '56, 142, 60' if pct == 100 else ('189, 189, 189' if pct == 0 else '255, 107, 0')
    r, g, b = [int(x) for x in color.split(', ')]
    pdf.set_text_color(r, g, b)
    pdf.cell(15, 5, f'{pct}%', ln=True)
    pdf.set_text_color(0, 0, 0)

pdf.ln(3)
pdf.set_font('Helvetica', 'B', 10)
pdf.set_text_color(255, 107, 0)
pdf.cell(0, 6, '  Overall Progress: ~40% Complete', ln=True)
pdf.set_text_color(0, 0, 0)
pdf.ln(4)

# ─── SECTION 7: NEXT STEPS / TODO ──────────────────────────────────────────
add_section_title(pdf, '7. Rencana Selanjutnya (Next Steps)')

todo_items = [
    ('Statistics & Charts (Phase 3)', '0%', [
        'Implementasi fl_chart untuk visualisasi data',
        'Monthly summary chart',
        'Category breakdown chart',
        'Visual trend analysis',
    ]),
    ('Notifications (Phase 4)', '0%', [
        'Due date reminders / notifikasi',
        'Notification permissions handling',
        'Scheduled notifications',
    ]),
    ('Security / PIN (Phase 5)', '0%', [
        'PIN setup screen',
        'Biometric authentication (Face ID / Fingerprint)',
        'Auto-lock after timeout',
    ]),
    ('Polish & Extra Features', '0%', [
        'Search functionality',
        'Export data (CSV/PDF)',
        'Dark mode',
        'Settings screen improvements',
    ]),
]

for title, pct, subitems in todo_items:
    pdf.set_fill_color(245, 245, 245)
    pdf.rect(10, pdf.get_y(), 190, 6, 'F')
    pdf.set_xy(14, pdf.get_y())
    pdf.set_font('Helvetica', 'B', 9)
    pdf.set_text_color(56, 142, 60)
    pdf.cell(145, 6, title, ln=False)
    pdf.set_font('Helvetica', '', 9)
    pdf.cell(30, 6, f'[{pct}]', ln=True)
    pdf.set_text_color(0, 0, 0)
    for s in subitems:
        add_bullet_item(pdf, s, indent=10)
    pdf.ln(2)

# ─── SECTION 8: USER FLOW ──────────────────────────────────────────────────
add_section_title(pdf, '8. Alur Penggunaan (User Flow)')

user_flows = [
    ('Menambah Utang/Piutang',
     'Dashboard > Tap "Tambah Utang/Piutang" > Isi form > Simpan > Data tersimpan'),
    ('Melihat Daftar',
     'Bottom Nav > Tab "Utang/Piutang" > Lihat daftar > Filter sesuai kebutuhan'),
    ('Menandai Lunas',
     'Daftar Utang/Piutang > Tap "Tandai Lunas" > Konfirmasi > Status berubah hijau'),
    ('Edit / Hapus Data',
     'Tekan lama (long-press) pada item > Pilih "Edit" atau "Hapus" > Konfirmasi'),
    ('Tagih via WhatsApp',
     'Daftar Piutang > Tap tombol "Tagih" > WhatsApp terbuka dengan pesan otomatis'),
    ('Filter Daftar',
     'Tap chip filter: "Semua" | "Belum Lunas" | "Lunas" > Daftar terfilter'),
]

col_w = [45, 140]
for aksi, flow in user_flows:
    pdf.set_font('Helvetica', 'B', 8.5)
    pdf.cell(col_w[0], 5, f'  {aksi}', ln=False)
    pdf.set_font('Helvetica', '', 8.5)
    pdf.multi_cell(col_w[1], 5, flow)

pdf.ln(4)

# ─── SECTION 9: WARNA & DESAIN ──────────────────────────────────────────────
add_section_title(pdf, '9. Warna & Desain UI')

color_data = [
    ('Primary / Accent', '#FF6B00', 'Orange', 'Warna utama aplikasi, tombol, aksen'),
    ('Utang Color', '#E53935', 'Red', 'Indikator utang (uang yang Anda hutang)'),
    ('Piutang Color', '#43A047', 'Green', 'Indikator piutang (uang yang orang hutang ke Anda)'),
    ('Success', '#388E3C', 'Green', 'Status lunas, konfirmasi sukses'),
    ('Warning', '#F57C00', 'Orange', 'Peringatan jatuh tempo'),
    ('Error', '#D32F2F', 'Red', 'Error, hapus data'),
    ('Background', '#FAFAFA', 'Light Gray', 'Background halaman'),
    ('Card BG', '#FFFFFF', 'White', 'Kartu komponen'),
]

col_w = [35, 22, 28, 100]
pdf.set_font('Helvetica', 'B', 8.5)
pdf.set_fill_color(255, 107, 0)
pdf.set_text_color(255, 255, 255)
pdf.cell(col_w[0], 6, '  Nama Warna', ln=False)
pdf.cell(col_w[1], 6, '  Hex Code', ln=False)
pdf.cell(col_w[2], 6, '  Warna', ln=False)
pdf.cell(col_w[3], 6, '  Keterangan', ln=True)
pdf.set_text_color(0, 0, 0)

for i, (name, hex_code, color_name, desc) in enumerate(color_data):
    c = 245 if i % 2 == 0 else 255
    pdf.set_fill_color(c, c, c)
    pdf.set_font('Helvetica', '', 8.5)
    pdf.cell(col_w[0], 5, f'  {name}', ln=False)
    pdf.set_font('Courier', '', 8.5)
    pdf.cell(col_w[1], 5, hex_code, ln=False)
    pdf.set_font('Helvetica', '', 8.5)
    pdf.cell(col_w[2], 5, color_name, ln=False)
    pdf.set_font('Helvetica', '', 8.5)
    pdf.cell(col_w[3], 5, desc, ln=True)

pdf.ln(4)

# ─── SECTION 10: KESIMPULAN ─────────────────────────────────────────────────
add_section_title(pdf, '10. Kesimpulan')

pdf.set_font('Helvetica', '', 9)
pdf.multi_cell(190, 5,
    'Aplikasi UtangKU telah berhasil dibangun dengan fitur utama CRUD (Create, Read, Update, Delete) '
    'yang berjalan dengan baik. Fase 1 (Setup) dan Fase 2 (CRUD) telah selesai 100%. '
    'Aplikasi ini sudah dapat digunakan secara fungsional untuk mencatat dan mengelola utang serta piutang.'
)
pdf.ln(2)
pdf.multi_cell(190, 5,
    'Fitur integrasi WhatsApp memungkinkan pengguna untuk langsung mengirim pesan tagihan hanya dengan '
    'satu ketukan. Dashboard memberikan ringkasan cepat kondisi keuangan. Aplikasi siap untuk '
    'dikembangkan lebih lanjut dengan fitur statistik, notifikasi, dan keamanan (PIN/Biometric).'
)
pdf.ln(3)

# Summary box
pdf.set_fill_color(255, 237, 218)
pdf.rect(10, pdf.get_y(), 190, 18, 'F')
pdf.set_xy(14, pdf.get_y() + 2)
pdf.set_font('Helvetica', 'B', 9)
pdf.set_text_color(255, 107, 0)
pdf.cell(0, 5, 'Ringkasan Progress:', ln=True)
pdf.set_font('Helvetica', '', 9)
pdf.set_text_color(0, 0, 0)
summary = [
    ('Phase 1 (Setup)', '100%', 'Selesai'),
    ('Phase 2 (CRUD)', '100%', 'Selesai'),
    ('Phase 3 (Stats)', '0%', 'Belum dimulai'),
    ('Phase 4 (Notif)', '0%', 'Belum dimulai'),
    ('Phase 5 (Security)', '0%', 'Belum dimulai'),
]
for name, pct, status in summary:
    pdf.set_x(14)
    pdf.cell(50, 4.5, f'  {name}', ln=False)
    pdf.cell(30, 4.5, pct, ln=False)
    pdf.cell(40, 4.5, status, ln=True)
pdf.ln(5)

# Output
output_path = '/Users/nadya/Documents/SEMESTER_4/aplikasi_bergerak/utangku_app/UtangKU_Progress_Report.pdf'
pdf.output(output_path)
print(f'PDF saved to: {output_path}')
