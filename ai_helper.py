#!/usr/bin/env python3
"""
Gemini API ile video metadata üretimi
"""
import os, json, re, urllib.request
from pathlib import Path

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")
GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key={key}"


class AIHelper:

    def generate_metadata(self, video_name: str, channel: dict, lang: str = "tr") -> dict:
        if not GEMINI_API_KEY:
            return {"error": "GEMINI_API_KEY eksik"}

        ch_name = channel.get("name", "")
        desc_tmpl = channel.get("description_template", "")
        tags_default = channel.get("tags_default", [])

        lang_instruction = "Türkçe" if lang == "tr" else "English"

        prompt = f"""YouTube video metadata üret. {lang_instruction} olarak yaz.

Kanal adı: {ch_name}
Video dosya adı: {video_name}
Kanal açıklama şablonu: {desc_tmpl}
Mevcut etiketler: {', '.join(tags_default)}

Şu JSON formatında döndür (başka hiçbir şey yazma):
{{
  "title": "...",
  "description": "...",
  "tags": ["tag1", "tag2", "tag3", "..."]
}}

Kurallar:
- Başlık: max 100 karakter, ilgi çekici, SEO uyumlu
- Açıklama: 200-400 karakter, kanal şablonunu temel al, video konusuna uyarla
- Etiketler: 10-15 adet, mevcut etiketlere ekle, konuyla ilgili
- Dosya adındaki alt çizgi/tire varsa kelime olarak oku"""

        payload = {
            "contents": [{"parts": [{"text": prompt}]}],
            "generationConfig": {"temperature": 0.7, "maxOutputTokens": 1024}
        }

        try:
            url = GEMINI_URL.format(key=GEMINI_API_KEY)
            data = json.dumps(payload).encode("utf-8")
            req = urllib.request.Request(url, data=data, headers={"Content-Type": "application/json"})
            with urllib.request.urlopen(req, timeout=30) as resp:
                result = json.loads(resp.read().decode("utf-8"))

            raw = result["candidates"][0]["content"]["parts"][0]["text"].strip()
            raw = re.sub(r"^```[a-z]*\n?", "", raw).rstrip("`").strip()
            meta = json.loads(raw)

            # Default tagleri birleştir
            existing_tags = set(tags_default)
            new_tags = [t for t in meta.get("tags", []) if t not in existing_tags]
            meta["tags"] = list(existing_tags) + new_tags

            return {"ok": True, "meta": meta}

        except Exception as e:
            return {"ok": False, "error": str(e)}
