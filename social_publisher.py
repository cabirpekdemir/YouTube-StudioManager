#!/usr/bin/env python3
"""
Instagram, TikTok, Facebook, X (Twitter) video/post paylaşımı
"""
import os, json, requests
from pathlib import Path


class SocialPublisher:

    def publish_all(self, channel: dict, video_path: str, title: str,
                    description: str, thumbnail_path: str = None) -> dict:
        """Aktif tüm platformlara yayınla"""
        sp = channel.get("social_platforms", {})
        results = {}

        if sp.get("instagram", {}).get("enabled"):
            token = sp["instagram"].get("token", "")
            results["instagram"] = self.publish_instagram(token, video_path, description)

        if sp.get("tiktok", {}).get("enabled"):
            token = sp["tiktok"].get("token", "")
            results["tiktok"] = self.publish_tiktok(token, video_path, title)

        if sp.get("facebook", {}).get("enabled"):
            token = sp["facebook"].get("token", "")
            results["facebook"] = self.publish_facebook(token, video_path, title, description)

        if sp.get("twitter", {}).get("enabled"):
            token = sp["twitter"].get("token", "")
            results["twitter"] = self.publish_twitter(token, title, description)

        return results

    # ── INSTAGRAM ────────────────────────────────────────────────────────────
    def publish_instagram(self, token: str, video_path: str, caption: str) -> dict:
        """
        Instagram Graph API — Reels yükleme
        Not: video_path, Instagram'ın erişebileceği public URL olmalı
             (lokal dosya için ngrok/CDN kullanın)
        """
        if not token:
            return {"ok": False, "error": "Instagram token eksik"}
        try:
            # Adım 1: Container oluştur
            r1 = requests.post(
                "https://graph.instagram.com/me/media",
                params={
                    "media_type":  "REELS",
                    "video_url":   video_path,    # public URL olmalı
                    "caption":     caption[:2200],
                    "access_token": token,
                },
                timeout=30,
            )
            d1 = r1.json()
            if "id" not in d1:
                return {"ok": False, "error": d1.get("error", {}).get("message", str(d1))}

            # Adım 2: Yayınla
            r2 = requests.post(
                "https://graph.instagram.com/me/media_publish",
                params={"creation_id": d1["id"], "access_token": token},
                timeout=30,
            )
            d2 = r2.json()
            return {"ok": "id" in d2, "id": d2.get("id")}
        except Exception as e:
            return {"ok": False, "error": str(e)}

    # ── TIKTOK ───────────────────────────────────────────────────────────────
    def publish_tiktok(self, token: str, video_path: str, title: str) -> dict:
        """TikTok Content Posting API v2"""
        if not token:
            return {"ok": False, "error": "TikTok token eksik"}
        try:
            path = Path(video_path)
            if not path.exists():
                return {"ok": False, "error": "Video dosyası bulunamadı"}

            size = path.stat().st_size
            headers = {
                "Authorization": f"Bearer {token}",
                "Content-Type":  "application/json; charset=UTF-8",
            }

            # Init upload
            init_resp = requests.post(
                "https://open.tiktokapis.com/v2/post/publish/video/init/",
                headers=headers,
                json={
                    "post_info": {
                        "title":            title[:150],
                        "privacy_level":    "PUBLIC_TO_EVERYONE",
                        "disable_duet":     False,
                        "disable_stitch":   False,
                        "disable_comment":  False,
                    },
                    "source_info": {
                        "source":             "FILE_UPLOAD",
                        "video_size":         size,
                        "chunk_size":         size,
                        "total_chunk_count":  1,
                    },
                },
                timeout=30,
            )
            init_data = init_resp.json()
            err = init_data.get("error", {})
            if err.get("code", "ok") != "ok":
                return {"ok": False, "error": err.get("message", str(init_data))}

            upload_url = init_data["data"]["upload_url"]
            publish_id = init_data["data"]["publish_id"]

            # Dosyayı yükle
            with open(video_path, "rb") as f:
                put_resp = requests.put(
                    upload_url, data=f,
                    headers={
                        "Content-Type":  "video/mp4",
                        "Content-Range": f"bytes 0-{size-1}/{size}",
                    },
                    timeout=300,
                )

            return {"ok": True, "publish_id": publish_id}
        except Exception as e:
            return {"ok": False, "error": str(e)}

    # ── FACEBOOK ─────────────────────────────────────────────────────────────
    def publish_facebook(self, token: str, video_path: str,
                         title: str, description: str) -> dict:
        """Facebook Graph API — Page video upload"""
        if not token:
            return {"ok": False, "error": "Facebook token eksik"}
        try:
            # Page listesini al
            me = requests.get(
                "https://graph.facebook.com/me/accounts",
                params={"access_token": token},
                timeout=15,
            ).json()
            pages = me.get("data", [])
            if not pages:
                return {"ok": False, "error": "Facebook Page bulunamadı. Page Access Token kullandığınızdan emin olun."}

            page        = pages[0]
            page_id     = page["id"]
            page_token  = page["access_token"]

            path = Path(video_path)
            if not path.exists():
                return {"ok": False, "error": "Video dosyası bulunamadı"}

            with open(video_path, "rb") as f:
                r = requests.post(
                    f"https://graph-video.facebook.com/{page_id}/videos",
                    data={
                        "title":        title[:255],
                        "description":  description[:2000],
                        "access_token": page_token,
                    },
                    files={"source": f},
                    timeout=600,
                )
            d = r.json()
            return {"ok": "id" in d, "id": d.get("id")}
        except Exception as e:
            return {"ok": False, "error": str(e)}

    # ── X (TWITTER) ──────────────────────────────────────────────────────────
    def publish_twitter(self, bearer_token: str, title: str, description: str) -> dict:
        """
        X (Twitter) API v2 — Tweet at
        Not: Video upload için OAuth1.0a user credentials gerekir.
             Bu sürüm sadece metin tweet atar (link ile).
        """
        if not bearer_token:
            return {"ok": False, "error": "X (Twitter) token eksik"}
        try:
            text = f"{title}\n\n{description}"[:280]
            r = requests.post(
                "https://api.twitter.com/2/tweets",
                headers={
                    "Authorization": f"Bearer {bearer_token}",
                    "Content-Type":  "application/json",
                },
                json={"text": text},
                timeout=15,
            )
            d = r.json()
            if "data" in d:
                return {"ok": True, "id": d["data"]["id"]}
            return {"ok": False, "error": d.get("detail", str(d))}
        except Exception as e:
            return {"ok": False, "error": str(e)}
