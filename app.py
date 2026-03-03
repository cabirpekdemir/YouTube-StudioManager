#!/usr/bin/env python3
"""
YT Studio - YouTube Kanal Yönetim Sistemi
Mac Mini / MacBook uyumlu, Flask tabanlı web arayüzü
"""
import os, json, shutil, threading, time
from pathlib import Path
from flask import Flask, render_template, request, jsonify, send_file
from dotenv import load_dotenv

from channel_manager import ChannelManager
from ai_helper import AIHelper
from youtube_client import YouTubeClient
from scheduler import Scheduler
from calendar_client import CalendarClient
from social_publisher import SocialPublisher

load_dotenv(os.path.join(os.path.dirname(__file__), ".env"))

app = Flask(__name__)
app.secret_key = os.getenv("FLASK_SECRET_KEY", os.urandom(24))

# Global managers
cm   = ChannelManager()
ai   = AIHelper()
yt   = YouTubeClient()
sc   = Scheduler()
gcal = CalendarClient()
sp   = SocialPublisher()


# ─────────────────────────────────────────────
# SAYFA ROTALARI
# ─────────────────────────────────────────────

@app.route("/")
def index():
    channels = cm.list_channels()
    return render_template("index.html", channels=channels)

@app.route("/channel/<channel_id>")
def channel_detail(channel_id):
    channel = cm.get_channel(channel_id)
    if not channel:
        return "Kanal bulunamadı", 404
    videos = cm.get_pending_videos(channel_id)
    return render_template("channel.html", channel=channel, videos=videos)

@app.route("/channel/<channel_id>/video/<path:video_rel>")
def video_detail(channel_id, video_rel):
    channel = cm.get_channel(channel_id)
    video_path = cm.get_video_path(channel_id, video_rel)
    return render_template("video_detail.html", channel=channel, video_rel=video_rel, video_path=str(video_path))


# ─────────────────────────────────────────────
# API - KANAL YÖNETİMİ
# ─────────────────────────────────────────────

@app.route("/api/channels", methods=["GET"])
def api_channels():
    return jsonify(cm.list_channels())

@app.route("/api/channels", methods=["POST"])
def api_create_channel():
    data = request.json
    result = cm.create_channel(data)
    return jsonify(result)

@app.route("/api/channels/<channel_id>", methods=["PUT"])
def api_update_channel(channel_id):
    data = request.json
    result = cm.update_channel(channel_id, data)
    return jsonify(result)

@app.route("/api/channels/<channel_id>", methods=["DELETE"])
def api_delete_channel(channel_id):
    result = cm.delete_channel(channel_id)
    return jsonify(result)


# ─────────────────────────────────────────────
# API - VİDEO İŞLEMLERİ
# ─────────────────────────────────────────────

@app.route("/api/channels/<channel_id>/videos")
def api_videos(channel_id):
    videos = cm.get_pending_videos(channel_id)
    return jsonify(videos)

@app.route("/api/channels/<channel_id>/scan")
def api_scan(channel_id):
    videos = cm.scan_videos(channel_id)
    return jsonify(videos)

@app.route("/api/video/thumbnail/<channel_id>/<path:video_rel>")
def api_thumbnail(channel_id, video_rel):
    thumb = cm.get_thumbnail(channel_id, video_rel)
    if thumb and thumb.exists():
        return send_file(str(thumb))
    return "", 404

@app.route("/api/video/stream/<channel_id>/<path:video_rel>")
def api_stream(channel_id, video_rel):
    vpath = cm.get_video_path(channel_id, video_rel)
    if vpath and vpath.exists():
        return send_file(str(vpath), mimetype="video/mp4")
    return "", 404


# ─────────────────────────────────────────────
# API - AI YARDIMCISI
# ─────────────────────────────────────────────

@app.route("/api/ai/generate", methods=["POST"])
def api_ai_generate():
    data = request.json
    channel_id = data.get("channel_id")
    video_name = data.get("video_name", "")
    channel = cm.get_channel(channel_id)
    result = ai.generate_metadata(
        video_name=video_name,
        channel=channel,
        lang=data.get("lang", "tr")
    )
    return jsonify(result)


# ─────────────────────────────────────────────
# API - ZAMANLAMA
# ─────────────────────────────────────────────

@app.route("/api/channels/<channel_id>/next-slots")
def api_next_slots(channel_id):
    vtype = request.args.get("type", "horizontal")
    count = int(request.args.get("count", 10))
    channel = cm.get_channel(channel_id)
    slots = sc.next_available_slots(channel, vtype, count)
    return jsonify(slots)


# ─────────────────────────────────────────────
# API - YOUTUBE UPLOAD
# ─────────────────────────────────────────────

@app.route("/api/upload", methods=["POST"])
def api_upload():
    data       = request.json
    channel_id = data["channel_id"]
    video_rel  = data["video_rel"]
    metadata   = data["metadata"]

    channel    = cm.get_channel(channel_id)
    video_path = cm.get_video_path(channel_id, video_rel)
    thumb_path = cm.get_thumbnail(channel_id, video_rel)

    def do_upload():
        try:
            result = yt.upload(
                channel=channel,
                video_path=video_path,
                thumbnail_path=thumb_path,
                metadata=metadata
            )
            cm.archive_video(channel_id, video_rel)
            cm.save_upload_result(channel_id, video_rel, result)

            # ── Google Calendar'a ekle ──────────────────────
            if result.get("ok") and channel.get("google_calendar_id"):
                publish_at = metadata.get("publish_at") or result.get("uploaded_at")
                if publish_at:
                    video_type = "vertical" if metadata.get("is_shorts") else "horizontal"
                    gcal.add_video_event(
                        channel=channel,
                        video_title=metadata.get("title", video_path.name),
                        publish_at=publish_at,
                        youtube_url=result.get("url", ""),
                        video_type=video_type,
                    )

            # ── Sosyal medya paylaşımı ──────────────────────
            publish_social = data.get("publish_social", False)
            if result.get("ok") and publish_social:
                sp.publish_all(
                    channel=channel,
                    video_path=str(video_path),
                    title=metadata.get("title", ""),
                    description=metadata.get("description", ""),
                    thumbnail_path=str(thumb_path) if thumb_path else None,
                )

        except Exception as e:
            import traceback
            print("[UPLOAD HATA]", traceback.format_exc())
            cm.save_upload_result(channel_id, video_rel, {"error": str(e)})

    threading.Thread(target=do_upload).start()
    return jsonify({"status": "uploading", "message": "Yükleme başlatıldı"})


@app.route("/api/upload/status/<channel_id>/<path:video_rel>")
def api_upload_status(channel_id, video_rel):
    result = cm.get_upload_result(channel_id, video_rel)
    return jsonify(result or {"status": "pending"})


# ─────────────────────────────────────────────
# API - VIDEO META
# ─────────────────────────────────────────────

@app.route("/api/channels/<channel_id>/video-meta", methods=["POST"])
def api_save_meta(channel_id):
    data = request.json
    result = cm.save_metadata(channel_id, data["video_rel"], data["meta"])
    return jsonify(result)

@app.route("/api/channels/<channel_id>/video-meta/<path:video_rel>")
def api_load_meta(channel_id, video_rel):
    meta = cm.load_metadata(channel_id, video_rel)
    return jsonify(meta)


# ─────────────────────────────────────────────
# API - YouTube OAuth
# ─────────────────────────────────────────────

@app.route("/api/auth/<channel_id>")
def api_auth(channel_id):
    channel = cm.get_channel(channel_id)
    auth_url = yt.get_auth_url(channel)
    return jsonify({"auth_url": auth_url})

@app.route("/oauth2callback")
def oauth2callback():
    channel_id = request.args.get("state")
    code = request.args.get("code")
    yt.save_token(channel_id, code)
    return render_template("oauth_success.html", channel_id=channel_id)


# ─────────────────────────────────────────────
# API - GOOGLE CALENDAR
# ─────────────────────────────────────────────

@app.route("/api/gcal/status")
def api_gcal_status():
    return jsonify({"connected": gcal.is_connected()})

@app.route("/api/gcal/auth")
def api_gcal_auth():
    return jsonify({"auth_url": gcal.get_auth_url()})

@app.route("/gcal/callback")
def gcal_callback():
    code = request.args.get("code")
    gcal.save_token(code)
    return "<h2 style='font-family:sans-serif;padding:40px'>✅ Google Calendar bağlandı! Bu sekmeyi kapatabilirsiniz.</h2>"

@app.route("/api/gcal/add-schedule", methods=["POST"])
def api_gcal_add_schedule():
    data    = request.json
    channel = cm.get_channel(data["channel_id"])
    result  = gcal.add_schedule_events(
        channel=channel,
        slots=data["slots"],
        title_prefix=data.get("title_prefix", f"{channel['name']} Yayın"),
        video_type=data.get("video_type", "horizontal"),
    )
    return jsonify(result)


# ─────────────────────────────────────────────
# API - SOSYAL MEDYA
# ─────────────────────────────────────────────

@app.route("/api/social/publish", methods=["POST"])
def api_social_publish():
    data       = request.json
    channel_id = data["channel_id"]
    video_rel  = data["video_rel"]
    metadata   = data.get("metadata", {})
    channel    = cm.get_channel(channel_id)
    video_path = str(cm.get_video_path(channel_id, video_rel))
    thumb_path = cm.get_thumbnail(channel_id, video_rel)

    results = sp.publish_all(
        channel=channel,
        video_path=video_path,
        title=metadata.get("title", ""),
        description=metadata.get("description", ""),
        thumbnail_path=str(thumb_path) if thumb_path else None,
    )
    return jsonify({"ok": True, "results": results})


if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5055)
