import json
import urllib.request

TOKEN = "9296282629:AAHzUCMfF11ovqVxSTTd3bPgB3cvJH9WcFg"
BASE_URL = f"https://api.telegram.org/bot{TOKEN}"

def get_latest_chat():
    req = urllib.request.Request(f"{BASE_URL}/getUpdates")
    with urllib.request.urlopen(req, timeout=10) as response:
        res = json.loads(response.read().decode())
        updates = res.get("result", [])
        print(f"Total updates: {len(updates)}")
        if updates:
            latest = updates[-1]
            chat = latest.get("message", {}).get("chat", {}) or latest.get("channel_post", {}).get("chat", {})
            print("Detected Chat:", json.dumps(chat, indent=2))
            return chat.get("id")
        return None

if __name__ == "__main__":
    chat_id = get_latest_chat()
    print("CHAT_ID =", chat_id)
