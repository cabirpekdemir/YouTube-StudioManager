#!/usr/bin/env python3
from __future__ import annotations
"""
YouTube Data API v3 - OAuth2 + Video Upload
"""
import os, json, re
from pathlib import Path
from datetime import datetime, timezone
from typing import Optional
from dotenv import load_dotenv
load_dotenv(os.path.join(os.path.dirname(os.path.abspath(__file__)), '.env'))

CLIENT_SECRETS_FILE = Path(os.getenv("YT_BASE_DIR", str(Path.home() / "YoutubeKanallar"))) / "client_secrets.json"
SCOPES = ["https://www.googleapis.com/auth/youtube.upload",
          "https://www.googleapis.com/auth/youtube"]
REDIRECT_URI = "http://localhost:5055/oauth2callback"


def _token_path(channel_id: str) -> Path:
    base = Path(os.getenv("YT_BASE_DIR", str(Path.home() / "YoutubeKanallar")))
    p = base / channel_id
    p.mkdir(parents=True, exist_ok=True)
    return p / "token.json"


def _clean_tags(tags: list) -> list:
    """YouTube: max 30 tag, tek tag max 30 kar, toplam max 400 kar"""
    result = []
    total = 0
    for t in tags:
        t = str(t).strip()
        t = re.sub(r"[^\w\s\-]", "", t, flags=re.UNICODE).strip()
        if not t:
            continue
        if len(t) > 30:
            t = t[:30].strip()
        if len(result) >= 30:
            break
        if total + len(t) > 400:
            break
        result.append(t)
        total += len(t) + 1
    return result


class YouTubeClient:

    def get_auth_url(self, channel: dict) -> str:
        from google_auth_oauthlib.flow import Flow
        secrets = Path(os.getenv("YT_BASE_DIR", str(Path.home() / "YoutubeKanallar"))) / "client_secrets.json"
        flow = Flow.from_client_secrets_file(str(secrets), scopes=SCOPES, redirect_uri=REDIRECT_URI)
        auth_url, _ = flow.authorization_url(
            access_type="offline", include_granted_scopes="true",
            state=channel["id"], prompt="consent"
        )
        return auth_url

    def save_token(self, channel_id: str, code: str):
        from google_auth_oauthlib.flow import Flow
        secrets = Path(os.getenv("YT_BASE_DIR", str(Path.home() / "YoutubeKanallar"))) / "client_secrets.json"
        flow = Flow.from_client_secrets_file(str(secrets), scopes=SCOPES, redirect_uri=REDIRECT_URI)
        flow.fetch_token(code=code)
        creds = flow.credentials
        _token_path(channel_id).write_text(json.dumps({
            "token": creds.token, "refresh_token": creds.refresh_token,
            "token_uri": creds.token_uri, "client_id": creds.client_id,
            "client_secret": creds.client_secret, "scopes": list(creds.scopes),
        }, indent=2))

    def _get_credentials(self, channel_id: str):
        from google.oauth2.credentials import Credentials
        from google.auth.transport.requests import Request
        tp = _token_path(channel_id)
        if not tp.exists():
            raise Exception(f"Token bulunamadi: /api/auth/{channel_id}")
        data = json.loads(tp.read_text())
        creds = Credentials(
            token=data["token"], refresh_token=data["refresh_token"],
            token_uri=data["token_uri"], client_id=data["client_id"],
            client_secret=data["client_secret"], scopes=data["scopes"],
        )
        if creds.expired and creds.refresh_token:
            creds.refresh(Request())
            data["token"] = creds.token
            tp.write_text(json.dumps(data, indent=2))
        return creds

    def upload(self, channel: dict, video_path: Path, thumbnail_path: Optional[Path], metadata: dict) -> dict:
        from googleapiclient.discovery import build
        from googleapiclient.http import MediaFileUpload

        channel_id = channel["id"]
        creds = self._get_credentials(channel_id)
        youtube = build("youtube", "v3", credentials=creds)

        publish_at = metadata.get("publish_at")
        privacy = metadata.get("privacy", "private")
        if publish_at:
            privacy = "private"

        clean_tags = _clean_tags(metadata.get("tags", []))
        print(f"[YT] Tags ({len(clean_tags)}): {clean_tags[:5]}...")

        body = {
            "snippet": {
                "title":           str(metadata["title"])[:100],
                "description":     str(metadata.get("description", "")),
                "tags":            clean_tags,
                "categoryId":      str(channel.get("category_id", "22")),
                "defaultLanguage": str(channel.get("language", "en")),
            },
            "status": {
                "privacyStatus":           privacy,
                "selfDeclaredMadeForKids": False,
            }
        }
        if publish_at:
            body["status"]["publishAt"] = publish_at

        media = MediaFileUpload(str(video_path), chunksize=10*1024*1024, resumable=True, mimetype="video/*")
        print(f"[YT] Yukleniyor: {video_path.name}")

        req = youtube.videos().insert(part=",".join(body.keys()), body=body, media_body=media)
        response = None
        while response is None:
            status, response = req.next_chunk()
            if status:
                print(f"[YT] %{int(status.progress() * 100)}")

        video_id = response["id"]
        print(f"[YT] Yuklendi: https://youtu.be/{video_id}")

        if thumbnail_path and Path(thumbnail_path).exists():
            try:
                youtube.thumbnails().set(
                    videoId=video_id,
                    media_body=MediaFileUpload(str(thumbnail_path))
                ).execute()
                print("[YT] Kapak yuklendi")
            except Exception as e:
                print(f"[YT] Kapak hatasi: {e}")

        return {
            "ok": True, "video_id": video_id,
            "url": f"https://youtu.be/{video_id}",
            "title": metadata["title"],
            "publish_at": publish_at,
            "uploaded_at": datetime.now(timezone.utc).isoformat(),
        }
