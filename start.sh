#!/bin/bash
# YT Studio Başlatma Scripti
cd "$(dirname "$0")"
source venv/bin/activate

# Tarayıcıyı aç (Mac)
sleep 1.5 && open http://localhost:5055 &

python app.py
