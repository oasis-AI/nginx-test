import smtplib
from email.mime.text import MIMEText

msg = MIMEText("这是测试告警邮件", "plain", "utf-8")
msg["Subject"] = "告警通知"
msg["From"] = "alert@example.com"
msg["To"] = "admin@example.com"

with smtplib.SMTP("localhost", 1025) as server:
    server.send_message(msg)
