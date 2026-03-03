# ⚡ Tek Tıkla Kurulum / One-Click Install

## 🍎 macOS

1. [`install-macos.command`](./install-macos.command) dosyasını indirin
2. Dosyaya **çift tıklayın** — Terminal açılır, sihirbaz başlar

### ⚠️ "Açılmadı" uyarısı çıkarsa (Gatekeeper)

macOS imzasız dosyaları otomatik engeller. İki çözümden birini kullanın:

**Yöntem A — Sağ tık (önerilen, 5 saniye):**
```
Dosyaya sağ tık → "Aç" → Açılan uyarıda "Aç" butonuna bas
```

**Yöntem B — Terminal:**
```bash
chmod +x ~/Downloads/install-macos.command
xattr -d com.apple.quarantine ~/Downloads/install-macos.command
```
Sonra çift tıkla — bir daha sormaz.

---

## 🪟 Windows

1. [`install-windows.bat`](./install-windows.bat) dosyasını indirin
2. Dosyaya **çift tıklayın** — Komut penceresi açılır ve sihirbaz başlar

> Windows Defender uyarısı çıkabilir.
> **"Daha fazla bilgi" → "Yine de çalıştır"** ile geçebilirsiniz.

---

## 🔄 Güncelleme

### macOS
```bash
cd ~/YTStudio && git pull && docker compose up -d --build
```

### Windows
```bat
cd C:\YTStudio && git pull && docker compose up -d --build
```

---

## 📋 Kurulum Sırasında Toplanacak Bilgiler

| Bilgi | Zorunlu | Nereden Alınır |
|-------|---------|----------------|
| Google OAuth JSON | ✅ Evet | console.cloud.google.com/apis/credentials |
| Gemini API Key | Önerilen | aistudio.google.com/app/apikey |
| Instagram Token | İsteğe bağlı | developers.facebook.com |
| TikTok Token | İsteğe bağlı | developers.tiktok.com |
| Facebook Token | İsteğe bağlı | developers.facebook.com |
| X Bearer Token | İsteğe bağlı | developer.x.com |

Sosyal medya tokenlarını kurulum sonrası .env dosyasından da ekleyebilirsiniz.
