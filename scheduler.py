#!/usr/bin/env python3
"""
Yayın zamanı hesaplama — periyot veya belirli günler + birden fazla saat
"""
from datetime import datetime, timedelta, timezone
import os, json
from pathlib import Path

BASE_DIR = Path(os.getenv("YT_BASE_DIR", Path.home() / "YoutubeKanallar"))

WEEKDAY_TR = ["Pazartesi","Salı","Çarşamba","Perşembe","Cuma","Cumartesi","Pazar"]


class Scheduler:

    def next_available_slots(self, channel: dict, vtype: str, count: int = 10) -> list:
        """
        vtype: 'horizontal' veya 'vertical'
        Döner: [{datetime, display, weekday, iso}, ...]
        """
        period_key = "normal_period" if vtype == "horizontal" else "shorts_period"
        period = channel.get(period_key, {"days": 7, "hour": 18, "minute": 0})

        weekdays = period.get("weekdays", [])   # [0,1,...6] Pazartesi=0
        times    = period.get("times", [])       # [{hour, minute}, ...]
        days     = period.get("days", 7)
        hour     = period.get("hour", 18)
        minute   = period.get("minute", 0)

        # Eski format uyumu
        if not times:
            times = [{"hour": hour, "minute": minute}]

        now = datetime.now(timezone.utc)

        if weekdays:
            return self._slots_by_weekdays(weekdays, times, now, count)
        else:
            return self._slots_by_period(days, times, channel["id"], vtype, now, count)

    def _slots_by_weekdays(self, weekdays: list, times: list, now: datetime, count: int) -> list:
        """Haftanın belirli günleri + saatler için slotlar"""
        slots = []
        cursor_date = now.date()
        max_days = count * 14

        for _ in range(max_days):
            if cursor_date.weekday() in weekdays:
                for t in sorted(times, key=lambda x: (x.get("hour", 0), x.get("minute", 0))):
                    candidate = datetime(
                        cursor_date.year, cursor_date.month, cursor_date.day,
                        t.get("hour", 18), t.get("minute", 0), 0,
                        tzinfo=timezone.utc
                    )
                    if candidate > now:
                        slots.append(self._fmt(candidate))
                        if len(slots) >= count:
                            return slots
            cursor_date += timedelta(days=1)

        return slots

    def _slots_by_period(self, days: int, times: list, channel_id: str, vtype: str, now: datetime, count: int) -> list:
        """Periyot bazlı slotlar"""
        last_dt = self._last_publish_time(channel_id, vtype)

        t0 = times[0] if times else {"hour": 18, "minute": 0}
        if last_dt is None or last_dt < now:
            base = now.replace(
                hour=t0.get("hour", 18), minute=t0.get("minute", 0),
                second=0, microsecond=0
            )
            if base <= now:
                base += timedelta(days=1)
            cursor = base - timedelta(days=days)
        else:
            cursor = last_dt

        slots = []
        while len(slots) < count:
            cursor += timedelta(days=days)
            for t in sorted(times, key=lambda x: (x.get("hour", 0), x.get("minute", 0))):
                candidate = cursor.replace(
                    hour=t.get("hour", 18),
                    minute=t.get("minute", 0),
                    second=0, microsecond=0
                )
                if candidate > now:
                    slots.append(self._fmt(candidate))
                if len(slots) >= count:
                    break

        return slots[:count]

    def _fmt(self, dt: datetime) -> dict:
        return {
            "datetime": dt.isoformat(),
            "display":  dt.strftime("%d %b %Y, %H:%M"),
            "weekday":  WEEKDAY_TR[dt.weekday()],
            "iso":      dt.strftime("%Y-%m-%dT%H:%M:00Z"),
        }

    def _last_publish_time(self, channel_id: str, vtype: str):
        result_dir = BASE_DIR / channel_id / "upload_results"
        if not result_dir.exists():
            return None
        latest = None
        for f in result_dir.glob("*.json"):
            try:
                data = json.loads(f.read_text())
                if not data.get("ok"):
                    continue
                pub = data.get("publish_at") or data.get("uploaded_at")
                if pub:
                    dt = datetime.fromisoformat(pub.replace("Z", "+00:00"))
                    if latest is None or dt > latest:
                        latest = dt
            except Exception:
                pass
        return latest
