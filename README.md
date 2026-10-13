# ALFATH × DONWAY NEWSROOM

Portal berita teknologi berbahasa Indonesia. Publisher: DONWAY. Creator: Alfath.

## Isi ZIP

- `index.html` — **preview statis mandiri**, bisa dibuka langsung di browser Android/file manager tanpa build. Data artikelnya contoh dan diberi label demo.
- `admin.html` — preview visual CMS admin yang bisa dibuka langsung. Formulir dan angka pada file ini demo, tidak tersimpan.
- `app.html` — entry aplikasi React untuk deployment Vercel (file `index.html` tetap preview offline).\n- `src/` — aplikasi React + TypeScript untuk deployment Vercel, routing, login Supabase, detail artikel, halaman admin berbasis role.
- `supabase/schema.sql` — tabel, indeks, trigger, RLS, dan kebijakan Supabase Storage.
- `.env.example` — contoh konfigurasi tanpa rahasia.
- `public/robots.txt`, `public/site.webmanifest`.

## 1. Lihat tampilan lewat HP sekarang

1. Unduh dan ekstrak ZIP.
2. Buka folder hasil ekstrak.
3. Ketuk `index.html` lalu pilih Chrome/browser. Bila aplikasi file tidak membuka HTML, gunakan menu browser **Buka file** bila tersedia.
4. Untuk CMS preview, buka `admin.html`.

File `index.html` adalah preview visual, bukan website live. File `app.html` digunakan sebagai entry aplikasi React pada deployment Vercel. Artikel contoh bukan berita terkini yang diverifikasi. Gambar demo membutuhkan koneksi internet.

## 2. Deploy aplikasi React ke Vercel

1. Buat repository GitHub baru.
2. Upload semua isi folder ZIP, termasuk `package.json`, `src/`, `public/`, dan `supabase/` (bukan folder pembungkus project).
3. Di Vercel pilih **Add New → Project**, impor repository tersebut.
4. Framework akan dikenali sebagai Vite. Build command `npm run build`, output directory `dist`.
5. Tambahkan Environment Variables:
   - `VITE_SUPABASE_URL` = Project URL dari Supabase → Project Settings → API.
   - `VITE_SUPABASE_ANON_KEY` = publishable/anon key dari Supabase → API Keys.
   - `VITE_SITE_URL` = URL deployment (opsional untuk pengembangan metadata).
6. Deploy. Setelah mengubah environment variables, lakukan redeploy.
7. Untuk kerja dari HP, gunakan browser mode desktop bila kontrol GitHub/Vercel terlalu sempit.

## 3. Siapkan Supabase

1. Buat project Supabase baru.
2. Buka **SQL Editor → New query**.
3. Salin seluruh `supabase/schema.sql`, jalankan, lalu periksa pesan hasil eksekusi.
4. Buka Authentication → URL Configuration. Masukkan URL deployment Vercel sebagai Site URL dan tambahkan callback/redirect URL yang sesuai.
5. Buat akun melalui Supabase Auth Dashboard (registrasi publik tidak dibuat dalam UI ini).
6. Di Authentication → Users, salin UUID user yang telah diverifikasi.
7. Di SQL Editor jalankan perintah promosi admin pada bagian akhir schema, ganti placeholder dengan UUID yang benar. Jangan menyediakan promosi role dari frontend.
8. Tambahkan environment variables Vercel dan redeploy.

## 4. Variabel lingkungan

| Nama | Wajib | Kegunaan |
|---|---|---|
| `VITE_SUPABASE_URL` | Ya untuk live | URL project Supabase |
| `VITE_SUPABASE_ANON_KEY` | Ya untuk live | Publishable/anon key; boleh berada di browser jika RLS benar |
| `VITE_SITE_URL` | Dianjurkan | URL publik kanonis untuk pengembangan fitur SEO |

Jangan pernah menaruh `service_role`, secret key, database password, atau token administratif di kode frontend atau repository GitHub. `.env` sudah diabaikan oleh `.gitignore`.

## 5. Status fitur dan batasan

- Preview `index.html` dan `admin.html` berjalan tanpa konfigurasi backend; semua artikel dan statistik di dalamnya adalah demo.
- Aplikasi React mengambil artikel published dari Supabase, memiliki route `/news/:slug`, login email/password, reset password, serta proteksi halaman admin berdasarkan profil role.
- SQL menerapkan RLS untuk pembacaan artikel published dan operasi konten oleh admin. Profil baru selalu mendapat role `reader`.
- CMS React saat ini menyediakan alur buat artikel, hapus artikel, dan daftar artikel. Fitur rich-text penuh, edit artikel lengkap, uploader Storage terintegrasi, pagination UI, audit log, dan rate limiting server-side belum selesai pada paket awal ini.
- File upload bucket dibatasi 50 MB dan tipe MIME di SQL; batas ini bukan pengganti pemeriksaan isi file di server. Tambahkan validasi upload server-side sebelum membuka upload di produksi.
- Rate limiting, CAPTCHA, logging server-side, sitemap dinamis, canonical/OG dinamis per artikel, preview editorial yang aman, dan pengujian end-to-end belum dikonfigurasi.
- Karena kredensial Supabase tidak disediakan, integrasi live, RLS melalui akun nyata, email reset, upload, dan deploy Vercel **belum dapat diuji**.
- Build belum dapat diklaim lulus kecuali dijalankan di lingkungan yang menginstal dependency. Jalankan `npm install` lalu `npm run build` sebelum deploy.

## 6. Uji lokal

Dengan Node.js:
```bash
npm install
npm run dev
```
Buka URL lokal yang ditampilkan Vite. Untuk cek build:
```bash
npm run build
npm run preview
```

## 7. Checklist keamanan sebelum produksi

- Pastikan admin pertama ditetapkan lewat SQL Editor setelah memverifikasi UUID.
- Pastikan anon key hanya digunakan dengan RLS aktif.
- Uji akses draft memakai sesi anon; hasilnya tidak boleh memuat draft.
- Uji insert/update/delete memakai akun reader; semua harus ditolak.
- Periksa redirect URL Supabase Auth.
- Tambahkan validasi input server-side, rate limiting, dan alur upload server-side sebelum mengaktifkan upload.
- Ganti konten contoh dengan berita yang bersumber dan terverifikasi.
