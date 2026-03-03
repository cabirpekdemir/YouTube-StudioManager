#!/bin/bash
# ═══════════════════════════════════════════════════════════════
#  YT Studio - macOS Kurulum Sihirbazı
#  Gereksinimler: macOS 12+, Docker Desktop, Git
#  Kullanım: Bu dosyaya çift tıklayın
# ═══════════════════════════════════════════════════════════════

# ── GATEKEEPER BYPASS ───────────────────────────────────────────
# macOS imzasız dosyaları karantinaya alır.
# Bu blok karantina bayrağını kaldırır ve bir daha sorulmaz.
SELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
if xattr "$SELF" 2>/dev/null | grep -q "com.apple.quarantine"; then
  echo ""
  echo "🔐 macOS güvenlik izni gerekiyor..."
  echo "   Şifrenizi girin (ekranda görünmez, normal):"
  sudo xattr -rd com.apple.quarantine "$SELF" 2>/dev/null
  sudo chmod +x "$SELF" 2>/dev/null
  echo "   ✅ İzin verildi. Devam ediliyor..."
  echo ""
fi

# Renkler
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
RESET='\033[0m'

# Terminali temizle ve başlık göster
clear
echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║${RESET}   ${BOLD}${WHITE}YT_STUDIO  —  macOS Kurulum Sihirbazı${RESET}               ${CYAN}║${RESET}"
echo -e "${CYAN}║${RESET}   YouTube · Instagram · TikTok · Facebook · X (Twitter)  ${CYAN}║${RESET}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo "  Bu sihirbaz YT Studio'yu adım adım kuracak."
echo "  Her adımda ENTER'a basarak devam edebilirsiniz."
echo ""
read -p "  Başlamak için ENTER'a basın..." _

# ─────────────────────────────────────────────────────────────
# YARDIMCI FONKSİYONLAR
# ─────────────────────────────────────────────────────────────

step() {
    clear
    echo ""
    echo -e "${CYAN}[ ADIM $1 / 6 ]  $2${RESET}"
    echo "──────────────────────────────────────────────"
    echo ""
}

ok()   { echo -e "  ${GREEN}✓ $1${RESET}"; }
err()  { echo -e "  ${RED}✕ $1${RESET}"; }
warn() { echo -e "  ${YELLOW}⚠ $1${RESET}"; }
info() { echo -e "  ${CYAN}→ $1${RESET}"; }

wait_enter() { read -p "  ENTER'a basın..." _; }

open_url() { open "$1" 2>/dev/null || xdg-open "$1" 2>/dev/null || echo "  Tarayıcıda açın: $1"; }

# ─────────────────────────────────────────────────────────────
# ADIM 1 — DOCKER KONTROLÜ
# ─────────────────────────────────────────────────────────────

step 1 "Docker Kontrolü"

if ! command -v docker &>/dev/null; then
    err "Docker bulunamadı!"
    echo ""
    echo "  Docker Desktop'i indirip kurun:"
    echo -e "  ${YELLOW}  https://www.docker.com/products/docker-desktop/${RESET}"
    echo ""
    echo "  Tarayıcı açılıyor..."
    open_url "https://www.docker.com/products/docker-desktop/"
    echo ""
    echo "  Docker Desktop'i kurduktan ve başlattıktan sonra"
    read -p "  ENTER'a basın..." _

    if ! command -v docker &>/dev/null; then
        err "Docker hala bulunamadı. Kurulum tamamlandıktan sonra tekrar çalıştırın."
        wait_enter
        exit 1
    fi
fi

ok "Docker bulundu: $(docker --version 2>/dev/null)"

# Docker Engine çalışıyor mu?
if ! docker info &>/dev/null; then
    warn "Docker Engine çalışmıyor."
    echo "  Docker Desktop'i açıp başlatın..."
    open -a "Docker" 2>/dev/null
    echo ""
    info "Docker başlayana kadar bekleniyor (30 saniye)..."
    for i in {1..6}; do
        sleep 5
        if docker info &>/dev/null; then
            ok "Docker Engine çalışıyor"
            break
        fi
        echo "  Bekleniyor... ($((i*5))/30s)"
    done

    if ! docker info &>/dev/null; then
        err "Docker Engine başlatılamadı. Docker Desktop'i manuel başlatın."
        wait_enter
        exit 1
    fi
fi

ok "Docker Engine çalışıyor"
echo ""
wait_enter

# ─────────────────────────────────────────────────────────────
# ADIM 2 — GIT KONTROLÜ
# ─────────────────────────────────────────────────────────────

step 2 "Git Kontrolü"

if ! command -v git &>/dev/null; then
    warn "Git bulunamadı. Xcode Command Line Tools kuruluyor..."
    echo ""
    xcode-select --install 2>/dev/null
    echo ""
    echo "  Açılan pencereden 'Yükle' butonuna tıklayın."
    echo "  Kurulum tamamlandıktan sonra"
    wait_enter

    if ! command -v git &>/dev/null; then
        err "Git hala bulunamadı. Tekrar çalıştırın."
        exit 1
    fi
fi

ok "Git bulundu: $(git --version)"
echo ""
wait_enter

# ─────────────────────────────────────────────────────────────
# ADIM 3 — KURULUM KLASÖRÜ
# ─────────────────────────────────────────────────────────────

step 3 "Kurulum Klasörü"

echo "  YT Studio nereye kurulsun?"
echo "  (Boş bırakırsanız varsayılan kullanılır: ~/YTStudio)"
echo ""
read -p "  Klasör yolu: " INSTALL_DIR
INSTALL_DIR="${INSTALL_DIR:-$HOME/YTStudio}"
INSTALL_DIR="${INSTALL_DIR/#\~/$HOME}"   # ~ genişlet

echo ""

if [ -f "$INSTALL_DIR/docker-compose.yml" ]; then
    warn "Bu klasörde zaten YT Studio kurulu görünüyor."
    echo ""
    read -p "  Güncelleme yapmak istiyor musunuz? (e/h): " UPDATE_CHOICE
    if [[ "$UPDATE_CHOICE" =~ ^[Ee]$ ]]; then
        cd "$INSTALL_DIR"
        info "Git pull yapılıyor..."
        git pull
        echo ""
        ok "Güncellendi!"
        # env yapılandırmasına atla
    fi
else
    info "Repo klonlanıyor..."
    git clone https://github.com/cabir/youtube-channel-manager.git "$INSTALL_DIR"
    if [ $? -ne 0 ]; then
        err "Klonlama başarısız. İnternet bağlantınızı kontrol edin."
        wait_enter
        exit 1
    fi
    cd "$INSTALL_DIR"
    mkdir -p secrets data/channels data/archive
    ok "Dosyalar indirildi: $INSTALL_DIR"
fi

echo ""
wait_enter

# ─────────────────────────────────────────────────────────────
# ADIM 4 — API ANAHTARLARI
# ─────────────────────────────────────────────────────────────

step 4 "API Anahtarları ve Yapılandırma"

echo "  Şimdi gerekli API anahtarlarını gireceksiniz."
echo "  Bilmediğiniz anahtarları boş bırakın — daha sonra .env dosyasından düzenleyebilirsiniz."
echo ""

# --- Gemini API ---
echo -e "  ${YELLOW}[1/6] GEMINI API ANAHTARI${RESET}"
echo "  AI ile otomatik başlık/açıklama/etiket üretimi için."
echo "  Nereden alınır → https://aistudio.google.com/app/apikey"
echo ""
open_url "https://aistudio.google.com/app/apikey"
read -p "  Gemini API Key: " GEMINI_KEY
GEMINI_KEY="${GEMINI_KEY:-YOUR_GEMINI_API_KEY_HERE}"
echo ""

# --- Google OAuth ---
echo -e "  ${YELLOW}[2/6] GOOGLE OAUTH (client_secrets.json)${RESET}"
echo "  YouTube API ve Google Calendar için zorunlu."
echo ""
echo "  Nasıl alınır:"
echo "    1. console.cloud.google.com/apis/credentials adresine git"
echo "    2. Create Credentials → OAuth 2.0 Client ID → Desktop App seç"
echo "    3. YouTube Data API v3 ve Google Calendar API'yi etkinleştir"
echo "    4. JSON dosyasını indir ve şu konuma kopyala:"
echo -e "    ${YELLOW}  $INSTALL_DIR/secrets/client_secrets.json${RESET}"
echo ""
open_url "https://console.cloud.google.com/apis/credentials"
echo "  JSON dosyasını kopyaladığınızda ENTER'a basın..."
wait_enter

if [ -f "$INSTALL_DIR/secrets/client_secrets.json" ]; then
    ok "client_secrets.json bulundu"
else
    warn "client_secrets.json henüz yok. Şu yola kopyalayın:"
    echo "     $INSTALL_DIR/secrets/client_secrets.json"

    # Finder'da aç
    echo ""
    echo "  Finder'da klasör açılıyor..."
    open "$INSTALL_DIR/secrets/"
    echo ""
    echo "  Dosyayı kopyaladıktan sonra ENTER'a basın..."
    wait_enter

    if [ -f "$INSTALL_DIR/secrets/client_secrets.json" ]; then
        ok "client_secrets.json bulundu"
    else
        warn "Hala bulunamadı. Daha sonra ekleyebilirsiniz."
    fi
fi
echo ""

# --- Instagram ---
echo -e "  ${YELLOW}[3/6] INSTAGRAM GRAPH API TOKEN${RESET}"
echo "  Nereden alınır → https://developers.facebook.com/"
echo ""
read -p "  Instagram Token (boş bırakabilirsiniz): " IG_TOKEN
echo ""

# --- TikTok ---
echo -e "  ${YELLOW}[4/6] TIKTOK ACCESS TOKEN${RESET}"
echo "  Nereden alınır → https://developers.tiktok.com/"
echo ""
read -p "  TikTok Token (boş bırakabilirsiniz): " TT_TOKEN
echo ""

# --- Facebook ---
echo -e "  ${YELLOW}[5/6] FACEBOOK PAGE ACCESS TOKEN${RESET}"
echo "  Nereden alınır → https://developers.facebook.com/ → Access Token Tool"
echo ""
read -p "  Facebook Token (boş bırakabilirsiniz): " FB_TOKEN
echo ""

# --- Twitter/X ---
echo -e "  ${YELLOW}[6/6] X (TWITTER) BEARER TOKEN${RESET}"
echo "  Nereden alınır → https://developer.x.com/ → Projects → Keys and Tokens"
echo ""
read -p "  X Bearer Token (boş bırakabilirsiniz): " TW_TOKEN
echo ""

# .env yaz
FLASK_SECRET=$(openssl rand -hex 32 2>/dev/null || echo "change_this_secret_$(date +%s)")

cat > "$INSTALL_DIR/.env" << EOF
YT_BASE_DIR=/data/channels
YT_ARCHIVE_DIR=/data/archive
YT_CLIENT_SECRETS=/app/secrets/client_secrets.json
GCAL_REDIRECT_URI=http://localhost:5055/gcal/callback
GEMINI_API_KEY=${GEMINI_KEY}
FLASK_SECRET_KEY=${FLASK_SECRET}
INSTAGRAM_TOKEN=${IG_TOKEN}
TIKTOK_TOKEN=${TT_TOKEN}
FACEBOOK_TOKEN=${FB_TOKEN}
TWITTER_TOKEN=${TW_TOKEN}
EOF

ok ".env dosyası oluşturuldu"
echo ""
wait_enter

# ─────────────────────────────────────────────────────────────
# ADIM 5 — DOCKER BAŞLAT
# ─────────────────────────────────────────────────────────────

step 5 "Uygulama Başlatılıyor"

info "Docker imajı oluşturuluyor (ilk seferde 2-5 dakika sürebilir)..."
echo ""

cd "$INSTALL_DIR"
docker compose up -d --build

if [ $? -ne 0 ]; then
    err "Docker başlatma hatası!"
    echo ""
    echo "  Hata detayları için şu komutu çalıştırın:"
    echo -e "  ${YELLOW}  docker compose logs${RESET}"
    wait_enter
    exit 1
fi

ok "YT Studio başlatıldı!"
echo ""
wait_enter

# ─────────────────────────────────────────────────────────────
# ADIM 6 — GOOGLE OAUTH BAĞLANTISI
# ─────────────────────────────────────────────────────────────

step 6 "Google Hesabı Bağlantısı"

echo "  Şimdi Google hesabınızı YouTube ve Takvim için bağlamanız gerekiyor."
echo ""
echo -e "  ${YELLOW}YouTube için:${RESET}"
echo "    1. http://localhost:5055 adresini açın"
echo "    2. Kanal ekleyin"
echo "    3. Kanal sayfasında 'YouTube Bağla' butonuna tıklayın"
echo ""
echo -e "  ${YELLOW}Google Takvim için:${RESET}"
echo "    1. http://localhost:5055/api/gcal/auth adresini açın"
echo "    2. Google hesabınızı seçin ve izin verin"
echo ""
echo "  Tarayıcı açılıyor..."
sleep 2
open_url "http://localhost:5055"

# ─────────────────────────────────────────────────────────────
# KURULUM TAMAMLANDI
# ─────────────────────────────────────────────────────────────

clear
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}║${RESET}                                                          ${GREEN}║${RESET}"
echo -e "${GREEN}║${RESET}   ${BOLD}${WHITE}✓  YT Studio başarıyla kuruldu!${RESET}                     ${GREEN}║${RESET}"
echo -e "${GREEN}║${RESET}                                                          ${GREEN}║${RESET}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  ${CYAN}Adres    :${RESET}  http://localhost:5055"
echo -e "  ${CYAN}Kurulum  :${RESET}  $INSTALL_DIR"
echo -e "  ${CYAN}Ayarlar  :${RESET}  $INSTALL_DIR/.env"
echo -e "  ${CYAN}Secrets  :${RESET}  $INSTALL_DIR/secrets/"
echo ""
echo "  ─────────────────────────────────────────────────────"
echo -e "  ${YELLOW}Masaüstü kısayolu oluşturuluyor...${RESET}"

# Masaüstüne başlatma kısayolu yaz
SHORTCUT="$HOME/Desktop/YT Studio.command"
cat > "$SHORTCUT" << SHORTCUTEOF
#!/bin/bash
cd "$INSTALL_DIR"
docker compose up -d
sleep 2
open http://localhost:5055
SHORTCUTEOF
chmod +x "$SHORTCUT"
ok "Masaüstü kısayolu oluşturuldu: 'YT Studio.command'"

echo ""
echo "  ─────────────────────────────────────────────────────"
echo -e "  ${YELLOW}Faydalı Komutlar:${RESET}"
echo "    Durdur   : cd \"$INSTALL_DIR\" && docker compose down"
echo "    Başlat   : cd \"$INSTALL_DIR\" && docker compose up -d"
echo "    Güncelle : cd \"$INSTALL_DIR\" && git pull && docker compose up -d --build"
echo "    Loglar   : cd \"$INSTALL_DIR\" && docker compose logs -f"
echo "  ─────────────────────────────────────────────────────"
echo ""
echo "  ENTER'a basarak çıkabilirsiniz."
read -p "" _
