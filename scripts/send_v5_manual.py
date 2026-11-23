import sys
import os
sys.path.append(r"c:\Users\Dr Pradip\Downloads\Society\scripts")
from telegram_sender import send_document

pdf_path = r"c:\Users\Dr Pradip\Downloads\Society\Society_Management_User_Manual_Marathi_v5.pdf"
if os.path.exists(pdf_path):
    print("Sending updated User Manual v5...")
    res = send_document(
        pdf_path,
        caption=(
            "📘 <b>सोसायटी व्यवस्थापन ॲप - अधिकृत वापरकर्ता मार्गदर्शिका (User Manual v5)</b>\n\n"
            "✅ विंग व मजला पर्याय काढून सरळ व सुलभ फ्लॅट रचना समाविष्ट\n"
            "✅ केवळ चेअरमन (Chairman) नवीन सदस्य मंजुरी व निवड अधिकार अद्यतनित\n"
            "✅ टेलिग्राम थेट वितरण तपशील समाविष्ट"
        )
    )
    print("Sent v5 manual:", res.get("ok"))
