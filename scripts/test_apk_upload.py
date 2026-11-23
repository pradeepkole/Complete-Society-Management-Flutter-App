import sys
import os
sys.path.append(r"c:\Users\Dr Pradip\Downloads\Society\scripts")
from telegram_sender import send_document

apk_path = r"c:\Users\Dr Pradip\Downloads\Society\app-release.apk"
if os.path.exists(apk_path):
    size_mb = os.path.getsize(apk_path) / (1024 * 1024)
    print(f"Trying to upload APK ({size_mb:.2f} MB)...")
    try:
        res = send_document(
            apk_path,
            caption=f"📱 <b>सोसायटी व्यवस्थापन ॲप (Android APK)</b>\nआकार: {size_mb:.2f} MB"
        )
        print("Upload result:", res)
    except Exception as e:
        print("Upload failed:", e)
