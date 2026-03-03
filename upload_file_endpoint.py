
# ── app.py'a eklenecek endpoint ──
# Bu bloğu app.py'daki "if __name__ == '__main__'" satırından ÖNCE ekle

import shutil
from werkzeug.utils import secure_filename

ALLOWED_EXTENSIONS = {'mp4', 'mov', 'mkv', 'avi', 'webm', 'm4v'}

def allowed_video(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@app.route("/api/upload-file", methods=["POST"])
def api_upload_file():
    """Drag & drop ile gelen video dosyasını kanal klasörüne kopyala"""
    channel_id = request.form.get("channel_id")
    if not channel_id:
        return jsonify({"ok": False, "error": "channel_id missing"})

    channel = cm.get_channel(channel_id)
    if not channel:
        return jsonify({"ok": False, "error": "Channel not found"})

    file = request.files.get("file")
    if not file or not file.filename:
        return jsonify({"ok": False, "error": "No file"})

    if not allowed_video(file.filename):
        return jsonify({"ok": False, "error": "Not a supported video format"})

    filename  = secure_filename(file.filename)
    video_dir = Path(channel.get("video_dir") or (Path(os.getenv("YT_BASE_DIR", Path.home() / "YoutubeKanallar")) / channel_id))
    video_dir.mkdir(parents=True, exist_ok=True)

    dest = video_dir / filename
    file.save(str(dest))

    return jsonify({"ok": True, "path": str(dest), "filename": filename})
