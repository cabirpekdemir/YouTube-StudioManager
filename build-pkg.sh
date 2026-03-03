#!/bin/bash
# ═══════════════════════════════════════════════════════════════
#  YT Studio — macOS .pkg Builder
#  Çalıştır: chmod +x build-pkg.sh && ./build-pkg.sh
#  Gereksinim: macOS + Xcode Command Line Tools
# ═══════════════════════════════════════════════════════════════

set -e

# ── AYARLAR ─────────────────────────────────────────────────────
APP_NAME="YT Studio"
APP_ID="com.ytstudio.installer"
VERSION="1.0.0"
INSTALL_DIR="$HOME/YTStudio"
OUT_DIR="$(pwd)/dist"
PKG_NAME="YTStudio-${VERSION}-macOS.pkg"

# ── RENKLER ─────────────────────────────────────────────────────
GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RESET='\033[0m'
ok()   { echo -e "${GREEN}  ✓ $1${RESET}"; }
info() { echo -e "${CYAN}  → $1${RESET}"; }
warn() { echo -e "${YELLOW}  ⚠ $1${RESET}"; }

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║   YT Studio — .pkg Installer Builder        ║${RESET}"
echo -e "${CYAN}╚══════════════════════════════════════════════╝${RESET}"
echo ""

# ── KONTROL ─────────────────────────────────────────────────────
if ! command -v pkgbuild &>/dev/null; then
  echo "Xcode Command Line Tools gerekli:"
  echo "  xcode-select --install"
  exit 1
fi
ok "pkgbuild bulundu"

# ── KLASÖR YAPISI ────────────────────────────────────────────────
BUILD_ROOT="$(pwd)/pkg-build"
PAYLOAD="$BUILD_ROOT/payload"
SCRIPTS="$BUILD_ROOT/scripts"
RESOURCES="$BUILD_ROOT/resources"

rm -rf "$BUILD_ROOT" "$OUT_DIR"
mkdir -p "$PAYLOAD/usr/local/bin"
mkdir -p "$SCRIPTS"
mkdir -p "$RESOURCES"
mkdir -p "$OUT_DIR"

ok "Klasör yapısı oluşturuldu"

# ── PAYLOAD: Ana kurulum scripti ─────────────────────────────────
# install-macos.command → /usr/local/bin/ytstudio-install olarak koy
if [ ! -f "install-macos.command" ]; then
  warn "install-macos.command bulunamadı! Bu script'i yt-studio klasöründe çalıştırın."
  exit 1
fi

cp install-macos.command "$PAYLOAD/usr/local/bin/ytstudio-install"
chmod +x "$PAYLOAD/usr/local/bin/ytstudio-install"
ok "Payload hazırlandı"

# ── PRE/POST INSTALL SCRIPTS ─────────────────────────────────────
cat > "$SCRIPTS/postinstall" << 'POSTINSTALL'
#!/bin/bash
# Kurulum sonrası: masaüstüne kısayol oluştur ve scripti çalıştır

DESKTOP="$HOME/Desktop"
SHORTCUT="$DESKTOP/YT Studio Kurulum.command"

cat > "$SHORTCUT" << 'SHORTCUTEOF'
#!/bin/bash
/usr/local/bin/ytstudio-install
SHORTCUTEOF

chmod +x "$SHORTCUT"
xattr -d com.apple.quarantine "$SHORTCUT" 2>/dev/null || true
xattr -d com.apple.quarantine "/usr/local/bin/ytstudio-install" 2>/dev/null || true

# Otomatik kurulumu başlat
open -a Terminal /usr/local/bin/ytstudio-install

exit 0
POSTINSTALL
chmod +x "$SCRIPTS/postinstall"
ok "postinstall scripti yazıldı"

# ── WELCOME / README / LICENSE (pkg ekranları) ──────────────────
cat > "$RESOURCES/welcome.html" << 'EOF'
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"><style>
body{font-family:-apple-system,sans-serif;padding:20px;color:#1a1a2e;}
h1{color:#ff3f3f;font-size:22px;margin-bottom:8px;}
p{font-size:14px;line-height:1.6;color:#444;}
ul{font-size:13px;color:#555;line-height:1.8;}
</style></head>
<body>
<h1>🎬 YT Studio'ya Hoş Geldiniz</h1>
<p>Bu yükleyici YT Studio'yu Mac'inize kuracak. Kurulum sırasında şunlara ihtiyaç duyacaksınız:</p>
<ul>
  <li>✅ Docker Desktop (kurulu ve çalışır durumda)</li>
  <li>✅ İnternet bağlantısı</li>
  <li>✅ Google Cloud Console hesabı (OAuth için)</li>
</ul>
<p>Devam etmek için <strong>Devam</strong> butonuna tıklayın.</p>
</body>
</html>
EOF

cat > "$RESOURCES/readme.html" << 'EOF'
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"><style>
body{font-family:-apple-system,sans-serif;padding:20px;}
h2{color:#ff3f3f;font-size:16px;}
p,li{font-size:13px;line-height:1.7;color:#444;}
code{background:#f4f4f4;padding:2px 6px;border-radius:4px;font-size:12px;}
</style></head>
<body>
<h2>Kurulum Adımları</h2>
<ol>
  <li>Bu yükleyiciyi tamamlayın</li>
  <li>Masaüstünde açılan <strong>"YT Studio Kurulum"</strong> dosyasına çift tıklayın</li>
  <li>Terminal'de sihirbazı takip edin</li>
  <li>Google OAuth için <code>client_secrets.json</code> dosyasını hazırlayın</li>
  <li>Tarayıcıda <strong>http://localhost:5055</strong> adresini açın</li>
</ol>
<h2>Sorun mu var?</h2>
<p>GitHub Issues: <strong>github.com/YOUR_USERNAME/yt-studio/issues</strong></p>
</body>
</html>
EOF

cat > "$RESOURCES/license.html" << 'EOF'
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"><style>
body{font-family:-apple-system,sans-serif;padding:20px;}
h2{font-size:16px;}
p{font-size:12px;line-height:1.6;color:#555;}
</style></head>
<body>
<h2>MIT License</h2>
<p>Copyright (c) 2025 YT Studio</p>
<p>Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:</p>
<p>The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.</p>
<p>THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED.</p>
</body>
</html>
EOF

ok "Kaynak dosyalar hazırlandı"

# ── COMPONENT PKG ────────────────────────────────────────────────
info "Component pkg oluşturuluyor..."
pkgbuild \
  --root "$PAYLOAD" \
  --scripts "$SCRIPTS" \
  --identifier "$APP_ID" \
  --version "$VERSION" \
  --install-location "/" \
  "$OUT_DIR/component.pkg"
ok "Component pkg hazır"

# ── DISTRIBUTION XML ─────────────────────────────────────────────
cat > "$BUILD_ROOT/distribution.xml" << DISTXML
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="2">
    <title>${APP_NAME} ${VERSION}</title>
    <organization>${APP_ID}</organization>
    <domains enable_localSystem="true"/>
    <options customize="never" require-scripts="true" rootVolumeOnly="true"/>

    <!-- Ekranlar -->
    <welcome    file="welcome.html" mime-type="text/html"/>
    <readme     file="readme.html"  mime-type="text/html"/>
    <license    file="license.html" mime-type="text/html"/>

    <!-- macOS 12+ gereksinimi -->
    <os-version min="12.0"/>

    <choices-outline>
        <line choice="default"/>
    </choices-outline>
    <choice id="default" title="${APP_NAME}">
        <pkg-ref id="${APP_ID}"/>
    </choice>
    <pkg-ref id="${APP_ID}" version="${VERSION}" onConclusion="none">component.pkg</pkg-ref>
</installer-gui-script>
DISTXML
ok "Distribution XML hazır"

# ── PRODUCT BUILD ────────────────────────────────────────────────
info "Final .pkg oluşturuluyor..."
productbuild \
  --distribution "$BUILD_ROOT/distribution.xml" \
  --resources "$RESOURCES" \
  --package-path "$OUT_DIR" \
  "$OUT_DIR/$PKG_NAME"

ok "Final pkg hazır!"

# ── TEMİZLİK ────────────────────────────────────────────────────
rm -f "$OUT_DIR/component.pkg"
rm -rf "$BUILD_ROOT"

# ── SONUÇ ────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}║   ✓ .pkg başarıyla oluşturuldu!              ║${RESET}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  📦 Dosya : ${CYAN}dist/${PKG_NAME}${RESET}"
echo -e "  📏 Boyut : $(du -sh "$OUT_DIR/$PKG_NAME" | cut -f1)"
echo ""
echo "  GitHub Releases'e yüklemek için:"
echo "  → Repo → Releases → New Release → dist/$PKG_NAME"
echo ""

# Finder'da göster
open "$OUT_DIR"
