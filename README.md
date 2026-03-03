# 🎬 YT Studio

YouTube, Instagram, TikTok, Facebook ve X için video yönetim, zamanlama ve otomatik yükleme sistemi. Google Calendar entegrasyonu ile yayın takviminizi otomatik oluşturun.

## ✨ Özellikler

- 📺 Çoklu YouTube kanal yönetimi
- ✏️ Kanal ekleme, düzenleme ve silme
- 🗓️ Gün bazlı / periyot bazlı yayın planlaması
- 📅 Google Calendar otomatik entegrasyonu (YouTube linki ile)
- 📡 Instagram, TikTok, Facebook, X otomatik paylaşım
- 🤖 Gemini AI ile otomatik başlık/açıklama/etiket üretimi
- 🔐 OAuth2 ile YouTube güvenli bağlantı

---

## 🚀 Kurulum (Docker — Önerilen)

### Gereksinimler
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- Google Cloud Console hesabı (OAuth için)

### 1. Repoyu klonla

```bash
git clone https://github.com/KULLANICI_ADI/yt-studio.git
cd yt-studio
```

### 2. Google OAuth Credentials

1. [Google Cloud Console](https://console.cloud.google.com/apis/credentials) → **Create Credentials → OAuth 2.0 Client ID → Desktop App**
2. **YouTube Data API v3** ve **Google Calendar API**'yi etkinleştir
3. JSON dosyasını indir → `secrets/client_secrets.json` olarak kaydet

```bash
mkdir secrets
mv ~/Downloads/client_secret_*.json secrets/client_secrets.json
```

### 3. Ortam değişkenlerini ayarla

```bash
cp .env.example .env
nano .env   # GEMINI_API_KEY ve diğerlerini doldur
```

### 4. Başlat

```bash
docker compose up -d
```

Tarayıcıda aç: **http://localhost:5055**

### 5. Güncelleme

```bash
git pull
docker compose up -d --build
```

---

## 💻 Manuel Kurulum (Docker olmadan)

### Gereksinimler
- Python 3.9+

```bash
# 1. Bağımlılıkları kur
python3 -m venv venv
source venv/bin/activate      # Windows: venv\Scripts\activate
pip install -r requirements.txt

# 2. Yapılandır
cp .env.example .env
mkdir secrets
# client_secrets.json dosyasını secrets/ klasörüne koy

# 3. Başlat
./start.sh       # Mac/Linux
python app.py    # Windows
```

---

## 🔑 YouTube Bağlantısı

1. Uygulamayı aç → Kanal kartına tıkla
2. **"YouTube Bağla"** butonuna tıkla
3. Google hesabını seç ve izin ver
4. ✅ Bağlandı!

## 📅 Google Calendar Bağlantısı

1. **http://localhost:5055/api/gcal/auth** adresini aç
2. Google hesabını seç ve izin ver
3. Artık her yükleme otomatik takvime eklenir

## 📡 Sosyal Medya API Anahtarları

| Platform | Nereden alınır |
|----------|---------------|
| Instagram | [Meta for Developers](https://developers.facebook.com/) → Graph API |
| TikTok | [TikTok for Developers](https://developers.tiktok.com/) → Content Posting API |
| Facebook | [Meta for Developers](https://developers.facebook.com/) → Page Access Token |
| X (Twitter) | [developer.x.com](https://developer.x.com/) → Bearer Token |

Token'ları kanal ayarlarından girebilirsiniz.

---

## 📁 Klasör Yapısı

```
yt-studio/
├── app.py                 # Ana Flask uygulaması
├── channel_manager.py     # Kanal yönetimi
├── scheduler.py           # Yayın zamanlama
├── youtube_client.py      # YouTube API
├── calendar_client.py     # Google Calendar API
├── social_publisher.py    # Instagram/TikTok/Facebook/X
├── ai_helper.py           # Gemini AI metadata üretimi
├── templates/             # HTML şablonları
├── secrets/               # OAuth credentials (git'e eklenmez)
├── data/                  # Kanal verileri (git'e eklenmez)
├── .env.example           # Örnek ortam değişkenleri
├── Dockerfile
└── docker-compose.yml
```

---

## 🛠️ Sorun Giderme

**Port kullanımda hatası:**
```bash
# Portu değiştir — docker-compose.yml içinde:
ports:
  - "5056:5055"   # 5056 olarak değiştir
```

**YouTube token süresi doldu:**
Kanal sayfasından "YouTube Bağla" butonunu tekrar kullanın, token otomatik yenilenir.

**Logları görüntüle:**
```bash
docker compose logs -f
```

---

## 📄 Lisans

MIT License — dilediğiniz gibi kullanın, geliştirebilirsiniz.
