#!/usr/bin/env python3
"""
Kanal yönetimi: config okuma/yazma, video tarama, arşivleme
Tek queue/ klasörü — video tipi (shorts/normal) metadata'da tutulur
"""
from dotenv import load_dotenv
load_dotenv()
import os, json, shutil
from pathlib import Path
from datetime import datetime

def _base_dir():
    return Path(os.getenv("YT_BASE_DIR", Path.home() / "YoutubeKanallar"))
BASE_DIR = _base_dir()
ARCHIVE_DIR = Path(os.getenv("YT_ARCHIVE_DIR", "/Volumes/CA1/uploaded"))
CONFIG_FILE = BASE_DIR / "channels.json"
VIDEO_EXTS  = {".mp4", ".mov", ".avi", ".mkv", ".m4v", ".webm"}
IMAGE_EXTS  = {".jpg", ".jpeg", ".png", ".webp"}


class ChannelManager:

    def __init__(self):
        BASE_DIR.mkdir(parents=True, exist_ok=True)
        if not CONFIG_FILE.exists():
            CONFIG_FILE.write_text(json.dumps({"channels": {}}, ensure_ascii=False, indent=2))

    def _load(self):
        return json.loads(CONFIG_FILE.read_text(encoding="utf-8"))

    def _save(self, data):
        CONFIG_FILE.write_text(json.dumps(data, ensure_ascii=False, indent=2))

    def list_channels(self):
        data = self._load()
        channels = []
        for cid, ch in data["channels"].items():
            ch = dict(ch)
            ch["id"] = cid
            ch["auth_ok"] = self._token_path(cid).exists()
            ch["pending_count"] = len(self.get_pending_videos(cid))
            channels.append(ch)
        return channels

    def get_channel(self, channel_id):
        data = self._load()
        ch = data["channels"].get(channel_id)
        if ch:
            ch = dict(ch)
            ch["id"] = channel_id
            ch["auth_ok"] = self._token_path(channel_id).exists()
        return ch

    def create_channel(self, info):
        data = self._load()
        cid = info.get("id") or info["name"].lower().replace(" ", "_")

        channel = {
            "name":                 info["name"],
            "youtube_channel_id":   info.get("youtube_channel_id", ""),
            "description_template": info.get("description_template", ""),
            "tags_default":         info.get("tags_default", []),
            "normal_period":        info.get("normal_period", {"days": 7, "hour": 18, "minute": 0}),
            "shorts_period":        info.get("shorts_period", {"days": 3, "hour": 20, "minute": 0}),
            "language":             info.get("language", "tr"),
            "category_id":          info.get("category_id", "22"),
            "privacy_default":      info.get("privacy_default", "private"),
            "video_dir":            info.get("video_dir", str(BASE_DIR / cid)),
        }

        data["channels"][cid] = channel
        self._save(data)

        vdir = Path(channel["video_dir"])
        (vdir / "queue").mkdir(parents=True, exist_ok=True)
        (vdir / "archive").mkdir(parents=True, exist_ok=True)

        return {"ok": True, "id": cid, "channel": channel}

    def update_channel(self, channel_id, info):
        data = self._load()
        if channel_id not in data["channels"]:
            return {"ok": False, "error": "Kanal bulunamadi"}
        data["channels"][channel_id].update(info)
        self._save(data)
        return {"ok": True}

    def delete_channel(self, channel_id):
        data = self._load()
        if channel_id not in data["channels"]:
            return {"ok": False, "error": "Kanal bulunamadi"}
        del data["channels"][channel_id]
        self._save(data)
        return {"ok": True}

    def scan_videos(self, channel_id):
        return self.get_pending_videos(channel_id)

    def get_pending_videos(self, channel_id):
        channel = self.get_channel(channel_id)
        if not channel:
            return []

        queue = Path(channel["video_dir"]) / "queue"
        queue.mkdir(parents=True, exist_ok=True)

        videos = []
        for f in sorted(queue.iterdir()):
            if f.suffix.lower() not in VIDEO_EXTS:
                continue

            thumb = self._find_thumbnail(queue, f.stem)

            meta_file = queue / f"{f.stem}.json"
            meta = {}
            if meta_file.exists():
                try:
                    meta = json.loads(meta_file.read_text(encoding="utf-8"))
                except Exception:
                    pass

            stat = f.stat()
            videos.append({
                "rel":       f"queue/{f.name}",
                "name":      f.name,
                "stem":      f.stem,
                "is_shorts": meta.get("is_shorts", False),
                "size_mb":   round(stat.st_size / 1_048_576, 1),
                "modified":  datetime.fromtimestamp(stat.st_mtime).isoformat(),
                "has_thumb": thumb is not None,
                "thumb_rel": f"queue/{thumb.name}" if thumb else None,
                "meta":      meta,
            })

        return videos

    def get_video_path(self, channel_id, video_rel):
        channel = self.get_channel(channel_id)
        if not channel:
            return None
        return Path(channel["video_dir"]) / video_rel

    def get_thumbnail(self, channel_id, video_rel):
        channel = self.get_channel(channel_id)
        if not channel:
            return None
        vpath = Path(channel["video_dir"]) / video_rel
        return self._find_thumbnail(vpath.parent, vpath.stem)

    def _find_thumbnail(self, folder, stem):
        for ext in IMAGE_EXTS:
            for candidate in [f"{stem}{ext}", f"{stem}_thumb{ext}"]:
                p = folder / candidate
                if p.exists():
                    return p
        return None

    def save_metadata(self, channel_id, video_rel, meta):
        channel = self.get_channel(channel_id)
        vpath = Path(channel["video_dir"]) / video_rel
        meta_file = vpath.parent / f"{vpath.stem}.json"
        meta_file.write_text(json.dumps(meta, ensure_ascii=False, indent=2))
        return {"ok": True}

    def load_metadata(self, channel_id, video_rel):
        channel = self.get_channel(channel_id)
        vpath = Path(channel["video_dir"]) / video_rel
        meta_file = vpath.parent / f"{vpath.stem}.json"
        if meta_file.exists():
            return json.loads(meta_file.read_text(encoding="utf-8"))
        return {}

    def archive_video(self, channel_id, video_rel):
        channel = self.get_channel(channel_id)
        vpath = Path(channel["video_dir"]) / video_rel

        local_archive = Path(channel["video_dir"]) / "archive"
        local_archive.mkdir(exist_ok=True)

        dest = local_archive / vpath.name
        shutil.move(str(vpath), str(dest))

        thumb = self._find_thumbnail(vpath.parent, vpath.stem)
        if thumb:
            shutil.move(str(thumb), str(local_archive / thumb.name))

        meta_f = vpath.parent / f"{vpath.stem}.json"
        if meta_f.exists():
            shutil.move(str(meta_f), str(local_archive / meta_f.name))

        if ARCHIVE_DIR.exists():
            ext_dir = ARCHIVE_DIR / channel_id
            ext_dir.mkdir(parents=True, exist_ok=True)
            shutil.copy2(str(dest), str(ext_dir / vpath.name))

    def save_upload_result(self, channel_id, video_rel, result):
        result_dir = BASE_DIR / channel_id / "upload_results"
        result_dir.mkdir(parents=True, exist_ok=True)
        safe = video_rel.replace("/", "_")
        (result_dir / f"{safe}.json").write_text(
            json.dumps(result, ensure_ascii=False, indent=2)
        )

    def get_upload_result(self, channel_id, video_rel):
        result_dir = BASE_DIR / channel_id / "upload_results"
        safe = video_rel.replace("/", "_")
        f = result_dir / f"{safe}.json"
        if f.exists():
            return json.loads(f.read_text(encoding="utf-8"))
        return None

    def _token_path(self, channel_id):
        return BASE_DIR / channel_id / "token.json"
