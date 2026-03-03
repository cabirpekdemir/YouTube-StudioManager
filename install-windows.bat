@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1

:: ═══════════════════════════════════════════════════════════════
::  YT Studio - Windows Kurulum Sihirbazı
::  Gereksinimler: Windows 10/11, Docker Desktop, Git
:: ═══════════════════════════════════════════════════════════════

title YT Studio Kurulum Sihirbazi

:: Renk kodları
set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "CYAN=[96m"
set "WHITE=[97m"
set "RESET=[0m"
set "BOLD=[1m"

cls
echo.
echo %CYAN%╔══════════════════════════════════════════════════════════╗%RESET%
echo %CYAN%║%RESET%   %BOLD%%WHITE%YT_STUDIO  —  Windows Kurulum Sihirbazi%RESET%              %CYAN%║%RESET%
echo %CYAN%║%RESET%   YouTube · Instagram · TikTok · Facebook · X (Twitter)  %CYAN%║%RESET%
echo %CYAN%╚══════════════════════════════════════════════════════════╝%RESET%
echo.
echo  Bu sihirbaz YT Studio'yu adim adim kuracak.
echo  Her adimda ENTER'a basarak devam edebilirsiniz.
echo.
pause

:: ───────────────────────────────────────────────────────────────
:: ADIM 1 — DOCKER KONTROLÜ
:: ───────────────────────────────────────────────────────────────
:CHECK_DOCKER
cls
echo.
echo %CYAN%[ ADIM 1 / 6 ]  Docker Kontrolu%RESET%
echo ──────────────────────────────────────
echo.

docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo  %RED%✕ Docker bulunamadi!%RESET%
    echo.
    echo  Docker Desktop'i indirip kurun:
    echo.
    echo  %YELLOW%  https://www.docker.com/products/docker-desktop/%RESET%
    echo.
    echo  Kurulum tamamlandiktan sonra Docker Desktop'i BASLATIN
    echo  ve asagida ENTER'a basin.
    echo.
    start https://www.docker.com/products/docker-desktop/
    pause
    docker --version >nul 2>&1
    if !errorlevel! neq 0 (
        echo  %RED%Docker hala bulunamadi. Lutfen Docker Desktop'i kurun ve tekrar calistirin.%RESET%
        pause
        exit /b 1
    )
)

for /f "tokens=*" %%v in ('docker --version 2^>nul') do set DOCKER_VER=%%v
echo  %GREEN%✓ Docker bulundu: %DOCKER_VER%%RESET%

:: Docker Engine çalışıyor mu?
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo  %YELLOW%⚠ Docker Engine calismıyor.%RESET%
    echo  Docker Desktop'i acin ve baslatin, sonra ENTER'a basin.
    echo.
    start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe" 2>nul
    echo  Docker baslayana kadar bekleniyor...
    timeout /t 15 /nobreak >nul
    docker info >nul 2>&1
    if !errorlevel! neq 0 (
        echo  %RED%Docker Engine baslatılamadi. Docker Desktop'i manuel baslatin.%RESET%
        pause
        exit /b 1
    )
)

echo  %GREEN%✓ Docker Engine calisiyor%RESET%
echo.
pause

:: ───────────────────────────────────────────────────────────────
:: ADIM 2 — GIT KONTROLÜ
:: ───────────────────────────────────────────────────────────────
:CHECK_GIT
cls
echo.
echo %CYAN%[ ADIM 2 / 6 ]  Git Kontrolu%RESET%
echo ──────────────────────────────────────
echo.

git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo  %RED%✕ Git bulunamadi!%RESET%
    echo.
    echo  Git'i indirip kurun:
    echo  %YELLOW%  https://git-scm.com/download/win%RESET%
    echo.
    start https://git-scm.com/download/win
    pause
    git --version >nul 2>&1
    if !errorlevel! neq 0 (
        echo  %RED%Git hala bulunamadi. Kurulum sonrasi bu dosyayi tekrar calistirin.%RESET%
        pause
        exit /b 1
    )
)
echo  %GREEN%✓ Git bulundu%RESET%
echo.
pause

:: ───────────────────────────────────────────────────────────────
:: ADIM 3 — KURULUM KLASÖRÜ
:: ───────────────────────────────────────────────────────────────
:INSTALL_DIR
cls
echo.
echo %CYAN%[ ADIM 3 / 6 ]  Kurulum Klasoru%RESET%
echo ──────────────────────────────────────
echo.
echo  YT Studio nereye kurulsun?
echo  (Bos birakirsaniz varsayilan kullanilir: C:\YTStudio)
echo.
set /p INSTALL_DIR="  Klasor yolu: "
if "%INSTALL_DIR%"=="" set INSTALL_DIR=C:\YTStudio

:: Klasörü oluştur ve repo klon
if exist "%INSTALL_DIR%\docker-compose.yml" (
    echo.
    echo  %YELLOW%⚠ Bu klasorde zaten YT Studio kurulu gorunuyor.%RESET%
    echo  Guncelleme yapmak istiyor musunuz? (E/H)
    set /p UPDATE_CHOICE="  Seciminiz: "
    if /i "!UPDATE_CHOICE!"=="E" (
        cd /d "%INSTALL_DIR%"
        echo  Git pull yapiliyor...
        git pull
        goto CONFIGURE_ENV
    ) else (
        goto CONFIGURE_ENV
    )
)

echo.
echo  %CYAN%Repo klonlaniyor...%RESET%
git clone https://github.com/cabir/youtube-channel-manager.git "%INSTALL_DIR%"
if %errorlevel% neq 0 (
    echo  %RED%Klonlama basarisiz. Internet baglantinizi kontrol edin.%RESET%
    pause
    exit /b 1
)

echo  %GREEN%✓ Dosyalar indirildi: %INSTALL_DIR%%RESET%
cd /d "%INSTALL_DIR%"
mkdir secrets 2>nul
mkdir data\channels 2>nul
mkdir data\archive 2>nul
echo.
pause

:: ───────────────────────────────────────────────────────────────
:: ADIM 4 — API ANAHTARLARI VE ORTAM DEĞİŞKENLERİ
:: ───────────────────────────────────────────────────────────────
:CONFIGURE_ENV
cls
echo.
echo %CYAN%[ ADIM 4 / 6 ]  API Anahtarlari ve Yapilandirma%RESET%
echo ──────────────────────────────────────────────────────
echo.
echo  Simdi gerekli API anahtarlarini gireceksiniz.
echo  Hic bir anahtari bilmiyorsaniz bos birakin (sonra .env dosyasindan duzenleyebilirsiniz).
echo.

:: --- Gemini API ---
echo  %YELLOW%[1/6] GEMINI API ANAHTARI%RESET%
echo  AI ile otomatik baslik/aciklama/etiket uretimi icin gerekli.
echo  Nereden alinir: https://aistudio.google.com/app/apikey
echo.
set /p GEMINI_KEY="  Gemini API Key: "
if "%GEMINI_KEY%"=="" set GEMINI_KEY=YOUR_GEMINI_API_KEY_HERE
echo.

:: --- Google OAuth ---
echo  %YELLOW%[2/6] GOOGLE OAUTH (client_secrets.json)%RESET%
echo  YouTube Data API v3 ve Google Calendar icin zorunlu.
echo.
echo  Nasil alinir:
echo    1. https://console.cloud.google.com/apis/credentials adresine git
echo    2. Create Credentials ^> OAuth 2.0 Client ID ^> Desktop App sec
echo    3. YouTube Data API v3 ve Google Calendar API'yi etkinlestir
echo    4. JSON'u indir, asagidaki klasore kopyala:
echo    %YELLOW%  %INSTALL_DIR%\secrets\client_secrets.json%RESET%
echo.
start https://console.cloud.google.com/apis/credentials
echo  JSON dosyasini kopyaladiginizda ENTER'a basin...
pause

if not exist "%INSTALL_DIR%\secrets\client_secrets.json" (
    echo.
    echo  %RED%✕ client_secrets.json bulunamadi!%RESET%
    echo  Dosyayi asagidaki klasore kopyalayin:
    echo  %YELLOW%  %INSTALL_DIR%\secrets\client_secrets.json%RESET%
    echo  Kopyaladiniz mi? ENTER'a basin...
    pause
)

if exist "%INSTALL_DIR%\secrets\client_secrets.json" (
    echo  %GREEN%✓ client_secrets.json bulundu%RESET%
) else (
    echo  %YELLOW%⚠ client_secrets.json henuz yok. Sonra ekleyebilirsiniz.%RESET%
)
echo.

:: --- Instagram ---
echo  %YELLOW%[3/6] INSTAGRAM GRAPH API TOKEN%RESET%
echo  Nereden alinir: https://developers.facebook.com/ ^> Graph API Explorer
echo.
set /p IG_TOKEN="  Instagram Token (bos birakabilirsiniz): "
if "%IG_TOKEN%"=="" set IG_TOKEN=
echo.

:: --- TikTok ---
echo  %YELLOW%[4/6] TIKTOK ACCESS TOKEN%RESET%
echo  Nereden alinir: https://developers.tiktok.com/
echo.
set /p TT_TOKEN="  TikTok Token (bos birakabilirsiniz): "
if "%TT_TOKEN%"=="" set TT_TOKEN=
echo.

:: --- Facebook ---
echo  %YELLOW%[5/6] FACEBOOK PAGE ACCESS TOKEN%RESET%
echo  Nereden alinir: https://developers.facebook.com/ ^> Access Token Tool
echo.
set /p FB_TOKEN="  Facebook Token (bos birakabilirsiniz): "
if "%FB_TOKEN%"=="" set FB_TOKEN=
echo.

:: --- Twitter/X ---
echo  %YELLOW%[6/6] X (TWITTER) BEARER TOKEN%RESET%
echo  Nereden alinir: https://developer.x.com/ ^> Projects ^> Keys and Tokens
echo.
set /p TW_TOKEN="  X Bearer Token (bos birakabilirsiniz): "
if "%TW_TOKEN%"=="" set TW_TOKEN=
echo.

:: .env dosyasını yaz
echo  %CYAN%.env dosyasi yaziliyor...%RESET%
(
echo YT_BASE_DIR=/data/channels
echo YT_ARCHIVE_DIR=/data/archive
echo YT_CLIENT_SECRETS=/app/secrets/client_secrets.json
echo GCAL_REDIRECT_URI=http://localhost:5055/gcal/callback
echo GEMINI_API_KEY=%GEMINI_KEY%
echo FLASK_SECRET_KEY=%RANDOM%%RANDOM%%RANDOM%%RANDOM%
echo INSTAGRAM_TOKEN=%IG_TOKEN%
echo TIKTOK_TOKEN=%TT_TOKEN%
echo FACEBOOK_TOKEN=%FB_TOKEN%
echo TWITTER_TOKEN=%TW_TOKEN%
) > "%INSTALL_DIR%\.env"

echo  %GREEN%✓ .env dosyasi olusturuldu%RESET%
echo.
pause

:: ───────────────────────────────────────────────────────────────
:: ADIM 5 — DOCKER İMAJI OLUŞTURma ve BAŞLATMA
:: ───────────────────────────────────────────────────────────────
:BUILD_AND_START
cls
echo.
echo %CYAN%[ ADIM 5 / 6 ]  Uygulama Baslatiliyor%RESET%
echo ──────────────────────────────────────────
echo.
echo  %CYAN%Docker imaji olusturuluyor (ilk seferde 2-5 dakika surebilir)...%RESET%
echo.

cd /d "%INSTALL_DIR%"
docker compose up -d --build
if %errorlevel% neq 0 (
    echo.
    echo  %RED%✕ Docker baslatma hatasi!%RESET%
    echo  Asagidaki komutu calistirip hata mesajini kontrol edin:
    echo  %YELLOW%  docker compose logs%RESET%
    pause
    exit /b 1
)

echo.
echo  %GREEN%✓ YT Studio baslatildi!%RESET%
echo.
pause

:: ───────────────────────────────────────────────────────────────
:: ADIM 6 — GOOGLE OAUTH BAĞLANTISI
:: ───────────────────────────────────────────────────────────────
:OAUTH_SETUP
cls
echo.
echo %CYAN%[ ADIM 6 / 6 ]  Google Hesabi Baglantisi%RESET%
echo ──────────────────────────────────────────────
echo.
echo  Simdi Google hesabinizi YouTube ve Takvim icin baglamaniz gerekiyor.
echo.
echo  %YELLOW%YouTube icin:%RESET%
echo    1. Tarayicida http://localhost:5055 adresini acin
echo    2. Kanal ekleyin
echo    3. Kanal sayfasinda "YouTube Bagla" butonuna tiklayin
echo.
echo  %YELLOW%Google Takvim icin:%RESET%
echo    1. http://localhost:5055/api/gcal/auth adresini acin
echo    2. Google hesabinizi secin ve izin verin
echo.
echo  Simdi tarayici acilacak...
timeout /t 2 /nobreak >nul
start http://localhost:5055
echo.

:: ───────────────────────────────────────────────────────────────
:: TAMAMLANDI
:: ───────────────────────────────────────────────────────────────
:DONE
cls
echo.
echo %GREEN%╔══════════════════════════════════════════════════════════╗%RESET%
echo %GREEN%║%RESET%                                                          %GREEN%║%RESET%
echo %GREEN%║%RESET%   %BOLD%%WHITE%✓  YT Studio basariyla kuruldu!%RESET%                      %GREEN%║%RESET%
echo %GREEN%║%RESET%                                                          %GREEN%║%RESET%
echo %GREEN%╚══════════════════════════════════════════════════════════╝%RESET%
echo.
echo  %CYAN%Adres    :%RESET%  http://localhost:5055
echo  %CYAN%Kurulum  :%RESET%  %INSTALL_DIR%
echo  %CYAN%Ayarlar  :%RESET%  %INSTALL_DIR%\.env
echo  %CYAN%Secrets  :%RESET%  %INSTALL_DIR%\secrets\
echo.
echo  ─────────────────────────────────────────────
echo  %YELLOW%Faydali Komutlar:%RESET%
echo    Durdur  : docker compose -f "%INSTALL_DIR%\docker-compose.yml" down
echo    Baslat  : docker compose -f "%INSTALL_DIR%\docker-compose.yml" up -d
echo    Guncelle: cd "%INSTALL_DIR%" ^&^& git pull ^&^& docker compose up -d --build
echo    Loglar  : docker compose -f "%INSTALL_DIR%\docker-compose.yml" logs -f
echo  ─────────────────────────────────────────────
echo.

:: Masaüstüne kısayol oluştur
echo  %CYAN%Masaustu kisayolu olusturuluyor...%RESET%
set SHORTCUT_PATH=%USERPROFILE%\Desktop\YT Studio.bat
(
echo @echo off
echo cd /d "%INSTALL_DIR%"
echo docker compose up -d
echo timeout /t 2 /nobreak ^>nul
echo start http://localhost:5055
) > "%SHORTCUT_PATH%"
echo  %GREEN%✓ Masaustu kisayolu olusturuldu: "YT Studio.bat"%RESET%
echo.
echo  ENTER'a basarak cikabilirsiniz.
pause
exit /b 0
