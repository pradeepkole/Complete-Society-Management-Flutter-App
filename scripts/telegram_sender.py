import os
import json
import mimetypes
import urllib.request
import urllib.parse
import uuid

BOT_TOKEN = "9296282629:AAHzUCMfF11ovqVxSTTd3bPgB3cvJH9WcFg"
CHAT_ID = 467870752

def send_message(text: str, chat_id=CHAT_ID):
    url = f"https://api.telegram.org/bot{BOT_TOKEN}/sendMessage"
    payload = json.dumps({
        "chat_id": chat_id,
        "text": text,
        "parse_mode": "HTML"
    }).encode("utf-8")
    req = urllib.request.Request(url, data=payload, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=15) as res:
        return json.loads(res.read().decode())

def send_document(file_path: str, caption: str = "", chat_id=CHAT_ID):
    url = f"https://api.telegram.org/bot{BOT_TOKEN}/sendDocument"
    boundary = f"----WebKitFormBoundary{uuid.uuid4().hex}"
    
    file_name = os.path.basename(file_path)
    mime_type = mimetypes.guess_type(file_path)[0] or "application/octet-stream"
    
    with open(file_path, "rb") as f:
        file_bytes = f.read()

    body = bytearray()
    
    # chat_id field
    body.extend(f"--{boundary}\r\n".encode("utf-8"))
    body.extend(f'Content-Disposition: form-data; name="chat_id"\r\n\r\n{chat_id}\r\n'.encode("utf-8"))
    
    # caption field
    if caption:
        body.extend(f"--{boundary}\r\n".encode("utf-8"))
        body.extend(f'Content-Disposition: form-data; name="caption"\r\n\r\n{caption}\r\n'.encode("utf-8"))
        body.extend(f"--{boundary}\r\n".encode("utf-8"))
        body.extend(f'Content-Disposition: form-data; name="parse_mode"\r\n\r\nHTML\r\n'.encode("utf-8"))
        
    # file field
    body.extend(f"--{boundary}\r\n".encode("utf-8"))
    body.extend(f'Content-Disposition: form-data; name="document"; filename="{file_name}"\r\n'.encode("utf-8"))
    body.extend(f"Content-Type: {mime_type}\r\n\r\n".encode("utf-8"))
    body.extend(file_bytes)
    body.extend(b"\r\n")
    
    body.extend(f"--{boundary}--\r\n".encode("utf-8"))
    
    req = urllib.request.Request(
        url,
        data=body,
        headers={
            "Content-Type": f"multipart/form-data; boundary={boundary}",
            "Content-Length": str(len(body))
        }
    )
    with urllib.request.urlopen(req, timeout=60) as res:
        return json.loads(res.read().decode())

if __name__ == "__main__":
    print("Sending greeting message...")
    msg_res = send_message(
        "👋 <b>नमस्कार डॉ. प्रदीप कोले सर!</b>\n\n"
        "आपला <b>PKTelegram</b> बॉट यशस्वीरीत्या कनेक्ट झाला आहे.\n"
        "आता सर्व नवीन बिल्ड्स आणि अपडेट्स थेट आपल्या या चॅटमध्ये पाठवले जातील. 🚀"
    )
    print("Message result:", msg_res.get("ok"))
    
    pdf_path = r"c:\Users\Dr Pradip\Downloads\Society\Society_Management_User_Manual_Marathi_v4.pdf"
    if os.path.exists(pdf_path):
        print(f"Sending User Manual PDF ({os.path.getsize(pdf_path)} bytes)...")
        doc_res = send_document(
            pdf_path,
            caption="📘 <b>सोसायटी व्यवस्थापन ॲप - अधिकृत वापरकर्ता मार्गदर्शिका (User Manual v4)</b>\n\nसंपूर्ण मराठी मार्गदर्शिका."
        )
        print("Document result:", doc_res.get("ok"))
