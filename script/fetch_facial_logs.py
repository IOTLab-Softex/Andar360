import requests
import time
import sys
from datetime import datetime
from requests.auth import HTTPDigestAuth

DEVICE_IP = '192.168.1.38'
USERNAME = 'admin'
PASSWORD = '246810softex'

start_time = int(sys.argv[1]) if len(sys.argv) > 1 else int(time.time()) - 600
end_time = int(time.time())

url = f"http://{DEVICE_IP}/cgi-bin/recordFinder.cgi?action=find&name=AccessControlCardRec&StartTime={start_time}&EndTime={end_time}"
auth = HTTPDigestAuth(USERNAME, PASSWORD)

try:
    response = requests.get(url, auth=auth, timeout=20, verify=False)
    print(response.text.strip())  # ✅ importante: apenas printar a saída no final
except Exception as e:
    print(f"[✘] Erro: {e}", file=sys.stderr)
    sys.exit(1)
