import json
import urllib.request
import urllib.error

TOKEN = "9296282629:AAHzUCMfF11ovqVxSTTd3bPgB3cvJH9WcFg"
BASE_URL = f"https://api.telegram.org/bot{TOKEN}"

def get_me():
    try:
        req = urllib.request.Request(f"{BASE_URL}/getMe")
        with urllib.request.urlopen(req, timeout=10) as response:
            res = json.loads(response.read().decode())
            print("Bot info:", res)
            return res
    except Exception as e:
        print("getMe Error:", e)
        return None

def get_updates():
    try:
        req = urllib.request.Request(f"{BASE_URL}/getUpdates")
        with urllib.request.urlopen(req, timeout=10) as response:
            res = json.loads(response.read().decode())
            print("Updates:", res)
            return res
    except Exception as e:
        print("getUpdates Error:", e)
        return None

if __name__ == "__main__":
    get_me()
    get_updates()
