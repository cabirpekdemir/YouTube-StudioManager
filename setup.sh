#!/bin/bash
# ─────────────────────────────────────────────────────────
# YT Studio - Mac Mini / MacBook Kurulum Scripti
# ─────────────────────────────────────────────────────────
set -e

echo "🎬 YT Studio kurulum başlıyor..."

# 1. Python venv
if [ ! -d "venv" ]; then
  python3 -m venv venv
  echo "✅ venv oluşturuldu"
fi

source venv/bin/activate
pip install -q --upgrade pip
pip install -q -r requirements.txt
echo "✅ Paketler kuruldu"

# 2. .env oluştur
if [ ! -f ".env" ]; then
cat > .env << 'ENV'
# YouTube OAuth Client Secrets dosyanızın yolu
# Google Cloud Console > APIs > Credentials > OAuth 2.0 Client ID > JSON indir
YT_CLIENT_SECRETS=./client_secrets.json

# Kanal klasör kökü (Mac Mini)
YT_BASE_DIR=/Users/cbr-ai/desktop/ytstudio/YoutubeKanallar

# Video arşiv klasörü (harici disk)
YT_ARCHIVE_DIR=/Volumes/Ca1/uploaded

# Gemini API (başlık/açıklama üretimi için)
GEMINI_API_KEY=your_gemini_api_key_here
ENV
echo "✅ .env oluşturuldu — lütfen düzenleyin"
fi

# 3. Klasör yapısı
BASE=$(python3 -c "import os; from dotenv import load_dotenv; load_dotenv(); print(os.getenv('YT_BASE_DIR', os.path.expanduser('~/YoutubeKanallar')))")
mkdir -p "$BASE"
echo "✅ Kanal klasörü: $BASE"

echo ""
echo "─────────────────────────────────────────────────────"
echo "SONRAKI ADIMLAR:"
echo ""
echo "1. Google Cloud Console'dan OAuth 2.0 credentials alın:"
echo "   https://console.cloud.google.com/apis/credentials"
echo "   YouTube Data API v3'ü etkinleştirin"
echo "   OAuth 2.0 Client ID → Desktop App → JSON indir"
echo "   → client_secrets.json olarak bu klasöre kaydedin"
echo ""
echo "2. .env dosyasını düzenleyin:"
echo "   nano .env"
echo ""
echo "3. Uygulamayı başlatın:"
echo "   ./start.sh"
echo ""
echo "4. Tarayıcıda açın: http://localhost:5055"
echo "─────────────────────────────────────────────────────"
