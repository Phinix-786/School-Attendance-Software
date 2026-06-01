"""
App_Name Image Backend
FastAPI server that stores images for the EduSaas platform.
All other data (text) stays in Firebase Firestore.

File layout on disk:
  uploads/
    {schoolId}/
      {sectionId}/
        {classId}/
          homework/{homeworkId}/{index}.jpg
          tests/{testId}/{index}.jpg

Auth: every request must include header  X-API-Key: <API_KEY>
"""

import os
import uuid
import logging
from pathlib import Path
from typing import Optional

from fastapi import FastAPI, File, UploadFile, Header, HTTPException, Request
from fastapi.responses import FileResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware

# ── Config ────────────────────────────────────────────────────
API_KEY    = os.environ.get("App_Name_API_KEY", "CHANGE_THIS_KEY")
UPLOAD_DIR = Path(os.environ.get("App_Name_UPLOAD_DIR", "/var/App_Name/uploads"))
MAX_SIZE   = 10 * 1024 * 1024  # 10 MB per image
ALLOWED_CT = {"image/jpeg", "image/png", "image/webp", "image/gif"}

UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("App_Name")

app = FastAPI(title="App_Name Image Backend", docs_url=None, redoc_url=None)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "POST", "DELETE"],
    allow_headers=["*"],
)


# ── Auth helper ───────────────────────────────────────────────
def require_key(x_api_key: Optional[str] = Header(None)):
    if x_api_key != API_KEY:
        raise HTTPException(status_code=401, detail="Unauthorized")


# ── Health ────────────────────────────────────────────────────
@app.get("/health")
def health():
    return {"status": "ok"}


# ── Upload ────────────────────────────────────────────────────
@app.post("/upload/{school_id}/{section_id}/{class_id}/{item_type}/{item_id}")
async def upload_image(
    school_id:  str,
    section_id: str,
    class_id:   str,
    item_type:  str,   # "homework" | "tests"
    item_id:    str,
    file:       UploadFile = File(...),
    x_api_key:  Optional[str] = Header(None),
):
    """
    Upload one image.  Returns {"url": "http://host/files/..."}.
    item_type must be 'homework' or 'tests'.
    """
    require_key(x_api_key)

    if item_type not in ("homework", "tests"):
        raise HTTPException(400, "item_type must be 'homework' or 'tests'")

    # Validate content-type
    ct = (file.content_type or "").split(";")[0].strip()
    if ct not in ALLOWED_CT:
        raise HTTPException(400, f"Unsupported content type: {ct}")

    # Read & size check
    data = await file.read()
    if len(data) > MAX_SIZE:
        raise HTTPException(413, "Image too large (max 10 MB)")

    # Pick extension
    ext_map = {
        "image/jpeg": ".jpg",
        "image/png":  ".png",
        "image/webp": ".webp",
        "image/gif":  ".gif",
    }
    ext = ext_map.get(ct, ".jpg")

    # Sanitise path components (alphanumeric + dash/underscore only)
    def safe(s: str) -> str:
        return "".join(c for c in s if c.isalnum() or c in "-_")

    folder = (
        UPLOAD_DIR
        / safe(school_id)
        / safe(section_id)
        / safe(class_id)
        / safe(item_type)
        / safe(item_id)
    )
    folder.mkdir(parents=True, exist_ok=True)

    filename = f"{uuid.uuid4().hex}{ext}"
    dest     = folder / filename
    dest.write_bytes(data)

    # Build relative path for the URL
    rel = dest.relative_to(UPLOAD_DIR)
    url = f"/files/{rel.as_posix()}"
    log.info("Saved %s (%d bytes)", dest, len(data))
    return {"url": url}


# ── Serve ─────────────────────────────────────────────────────
@app.get("/files/{full_path:path}")
async def serve_file(
    full_path: str,
    x_api_key: Optional[str] = Header(None),
):
    """Serve a previously uploaded image. Requires API key."""
    require_key(x_api_key)

    # Prevent path traversal
    target = (UPLOAD_DIR / full_path).resolve()
    if not str(target).startswith(str(UPLOAD_DIR.resolve())):
        raise HTTPException(400, "Bad path")

    if not target.exists() or not target.is_file():
        raise HTTPException(404, "Not found")

    return FileResponse(str(target))


# ── Delete (optional, admin use) ──────────────────────────────
@app.delete("/files/{full_path:path}")
async def delete_file(
    full_path: str,
    x_api_key: Optional[str] = Header(None),
):
    require_key(x_api_key)
    target = (UPLOAD_DIR / full_path).resolve()
    if not str(target).startswith(str(UPLOAD_DIR.resolve())):
        raise HTTPException(400, "Bad path")
    if target.exists() and target.is_file():
        target.unlink()
        log.info("Deleted %s", target)
        return {"deleted": True}
    return {"deleted": False}
