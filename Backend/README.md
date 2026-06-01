# your-domain Image Backend

FastAPI server that stores **images only** (homework photos, test photos).  
All other data (text, attendance, users, test marks, chats text) stays in **Firebase Firestore**.

## Architecture

```
Flutter apps  ──upload image──►  Ubuntu server (FastAPI)
                                   /var/your-domain/uploads/
                                     {schoolId}/{sectionId}/{classId}/
                                       homework/{homeworkId}/abc.jpg
                                       tests/{testId}/def.jpg
Flutter apps  ──read URL from Firestore──► GET /files/{path}  ──► serve image
```

Firestore still stores the relative URL string `/files/school1/sec1/cls1/homework/hw1/abc.jpg`.  
The Flutter `BackendImage` widget prepends `kBackendBaseUrl` and adds the `X-API-Key` header.

## First-time setup (Ubuntu server)

```bash
# 1. Copy backend files to the server
scp -r Backend/ user@YOUR_SERVER_IP:~/your-domain-backend/

# 2. SSH in
ssh user@YOUR_SERVER_IP
cd ~/your-domain-backend

# 3. Run the installer (takes ~2 min)
sudo bash install.sh

# 4. Edit the env file with your real values
sudo nano /etc/your-domain.env
#   DUCKDNS_TOKEN=xxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
#   DUCKDNS_DOMAIN=your-domain
#   your-domain_API_KEY=pick-a-long-random-secret-here

# 5. Restart the backend and run the first DuckDNS update
sudo systemctl restart your-domain-backend
sudo systemctl start  yourdomain-duckdns

# 6. Verify
curl -H "X-API-Key: YOUR_KEY" http://your-domain-duckdns.org:8000/health
# → {"status":"ok"}
```

## After server is running

Open `lib/backend_config.dart` in **every Flutter app** and set:
```dart
const String kBackendBaseUrl = 'http://your-domain-duckdns.org:8000';
const String kBackendApiKey  = 'same-key-as-your-name/domain_API_KEY';
```

## Systemd services (autostart on boot)

| Unit | Purpose |
|---|---|
| `your-dmain-backend.service` | Uvicorn FastAPI — auto-starts on boot |
| `your-domain-duckdns.timer` | Checks/updates DuckDNS every 5 min |

```bash
# Status
sudo systemctl status your-domain-backend
sudo journalctl -u your-domain-backend -f   # live logs

# Restart after config change
sudo systemctl restart your-domain-backend
```

## File layout on disk

```
/var/your-domain/uploads/
  {schoolId}/
    {sectionId}/
      {classId}/
        homework/
          {homeworkId}/
            <uuid>.jpg
        tests/
          {testId}/
            <uuid>.jpg
```

## API

All endpoints require header `X-API-Key: <key>`.

| Method | Path | Description |
|---|---|---|
| `GET` | `/health` | Health check (no auth required) |
| `POST` | `/upload/{school}/{section}/{class}/{type}/{id}` | Upload image. Returns `{"url":"/files/..."}` |
| `GET` | `/files/{full_path}` | Serve image |
| `DELETE` | `/files/{full_path}` | Delete image |

## Security

- Every request (except `/health`) requires the `X-API-Key` header.
- The key is stored only in `/etc/your-domain.env` (mode 600) on the server.
- On the Flutter side the key is in `lib/backend_config.dart` — keep this out of public git repos.
- Path traversal is prevented: the server resolves and validates that every path stays inside `/var/your-domain/uploads/`.
- `ufw` only opens port 8000 from the install script. Port 22 stays open for SSH.

## Backward compatibility

Old images already in Firestore as `data:image/jpeg;base64,...` strings  
continue to display correctly — `BackendImage` detects the `data:` prefix  
and decodes them locally without hitting the backend.
