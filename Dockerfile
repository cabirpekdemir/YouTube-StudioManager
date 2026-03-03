FROM python:3.11-slim

WORKDIR /app

# Sistem bağımlılıkları
RUN apt-get update && apt-get install -y \
    ffmpeg \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Python bağımlılıkları
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Uygulama dosyaları
COPY . .

# Kanal klasörü için volume mount noktası
RUN mkdir -p /data/channels /data/archive

# Port
EXPOSE 5055

# Başlat
CMD ["python", "app.py"]
