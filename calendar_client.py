#!/usr/bin/env python3
"""
Google Calendar entegrasyonu — yüklenen/planlanan videolar otomatik takvime eklenir
"""
import os, json
from pathlib import Path
from datetime import datetime, timedelta, timezone
from dotenv import load_dotenv
load_dotenv(os.path.join(os.path.dirname(os.path.abspath(__file__)), '.env'))

BASE_DIR   = Path(os.getenv("YT_BASE_DIR", Path.home() / "YoutubeKanallar"))
TOKEN_FILE = BASE_DIR / "gcal_token.json"
SCOPES     = ["https://www.googleapis.com/auth/calendar"]
REDIRECT   = os.getenv("GCAL_REDIRECT_URI", "http://localhost:5055/gcal/callback")


def _get_credentials():
    from google.oauth2.credentials import Credentials
    from google.auth.transport.requests import Request

    if not TOKEN_FILE.exists():
        raise Exception("Google Calendar bağlı değil → http://localhost:5055/api/gcal/auth adresini ziyaret edin")

    d = json.loads(TOKEN_FILE.read_text())
    creds = Credentials(
        token=d["token"], refresh_token=d["refresh_token"],
        token_uri=d["token_uri"], client_id=d["client_id"],
        client_secret=d["client_secret"], scopes=d["scopes"],
    )
    if creds.expired and creds.refresh_token:
        creds.refresh(Request())
        d["token"] = creds.token
        TOKEN_FILE.write_text(json.dumps(d, indent=2))
    return creds


class CalendarClient:

    def get_auth_url(self) -> str:
        from google_auth_oauthlib.flow import Flow
        secrets = BASE_DIR / "client_secrets.json"
        if not secrets.exists():
            # Alternatif konum
            secrets = Path(os.getenv("YT_CLIENT_SECRETS", str(secrets)))
        flow = Flow.from_client_secrets_file(str(secrets), scopes=SCOPES, redirect_uri=REDIRECT)
        url, _ = flow.authorization_url(access_type="offline", prompt="consent")
        return url

    def save_token(self, code: str) -> dict:
        from google_auth_oauthlib.flow import Flow
        secrets = BASE_DIR / "client_secrets.json"
        if not secrets.exists():
            secrets = Path(os.getenv("YT_CLIENT_SECRETS", str(secrets)))
        flow = Flow.from_client_secrets_file(str(secrets), scopes=SCOPES, redirect_uri=REDIRECT)
        flow.fetch_token(code=code)
        c = flow.credentials
        TOKEN_FILE.parent.mkdir(parents=True, exist_ok=True)
        TOKEN_FILE.write_text(json.dumps({
            "token":         c.token,
            "refresh_token": c.refresh_token,
            "token_uri":     c.token_uri,
            "client_id":     c.client_id,
            "client_secret": c.client_secret,
            "scopes":        list(c.scopes),
        }, indent=2))
        return {"ok": True}

    def is_connected(self) -> bool:
        return TOKEN_FILE.exists()

    def add_video_event(self, channel: dict, video_title: str, publish_at: str,
                        youtube_url: str = "", video_type: str = "horizontal") -> dict:
        """
        Takvime video etkinliği ekle.
        publish_at: ISO format string örn. "2025-03-15T18:00:00+00:00"
        """
        try:
            from googleapiclient.discovery import build
            service = build("calendar", "v3", credentials=_get_credentials())

            cal_id = channel.get("google_calendar_id", "primary") or "primary"
            start  = datetime.fromisoformat(publish_at.replace("Z", "+00:00"))
            end    = start + timedelta(minutes=30)

            label  = "📱 Shorts" if video_type == "vertical" else "🎬 Yatay Video"
            sp     = channel.get("social_platforms", {})
            pts    = [p.capitalize() for p, v in sp.items() if v.get("enabled")]

            desc_lines = [
                f"Kanal: {channel.get('name', '')}",
                f"Tür: {label}",
            ]
            if youtube_url:
                desc_lines.append(f"YouTube: {youtube_url}")
            if pts:
                desc_lines.append(f"Platformlar: {', '.join(pts)}")

            event = {
                "summary":     f"🎥 {video_title}",
                "description": "\n".join(desc_lines),
                "start": {"dateTime": start.isoformat(), "timeZone": "UTC"},
                "end":   {"dateTime": end.isoformat(),   "timeZone": "UTC"},
                "colorId": "11" if video_type == "vertical" else "9",
                "reminders": {
                    "useDefault": False,
                    "overrides":  [{"method": "popup", "minutes": 60}],
                },
            }

            r = service.events().insert(calendarId=cal_id, body=event).execute()
            return {"ok": True, "event_id": r.get("id"), "event_url": r.get("htmlLink")}

        except Exception as e:
            return {"ok": False, "error": str(e)}

    def add_schedule_events(self, channel: dict, slots: list,
                            title_prefix: str = "Planlı Yayın",
                            video_type: str = "horizontal") -> dict:
        """Bir sonraki N slotu toplu takvime ekle"""
        results = []
        for s in slots:
            r = self.add_video_event(
                channel=channel,
                video_title=f"{title_prefix} — {s.get('display', '')}",
                publish_at=s["iso"],
                video_type=video_type,
            )
            results.append({"slot": s["display"], **r})
        return {"ok": True, "results": results}
