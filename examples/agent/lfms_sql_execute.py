#!/usr/bin/env python3
"""HMAC POST tới LFMS SQL Gateway. Dùng từ Dify Agent CLI (Studio /agent/).

Env:
  LFMS_EMBED_TOKEN     JWT từ POST /api/embed/dify-token (session LFMS)
  LFMS_API_BASE        vd. http://host.docker.internal:8010 (không slash cuối)
  DIFY_LFMS_HMAC_SECRET  trùng apps/.env LFMS

Arg: câu SELECT (một tham số hoặc ghép sys.argv[1:]).
"""

from __future__ import annotations

import hashlib
import hmac
import json
import os
import sys
import time
import uuid
import urllib.error
import urllib.request

PATH = "/api/internal/dify/sql/execute"
METHOD = "POST"


def _sign(raw_body: str, timestamp: str, nonce: str, secret: str) -> str:
    body_hash = hashlib.sha256(raw_body.encode("utf-8")).hexdigest()
    signing_string = f"{timestamp}\n{nonce}\n{METHOD}\n{PATH}\n{body_hash}"
    return hmac.new(secret.encode("utf-8"), signing_string.encode("utf-8"), hashlib.sha256).hexdigest()


def main() -> int:
    token = (os.environ.get("LFMS_EMBED_TOKEN") or os.environ.get("lfms_token") or "").strip()
    base = (os.environ.get("LFMS_API_BASE") or os.environ.get("lfms_api_base") or "").rstrip("/")
    secret = (os.environ.get("DIFY_LFMS_HMAC_SECRET") or "").strip()
    sql = " ".join(sys.argv[1:]).strip().rstrip(";")

    if token == "" or base == "" or secret == "":
        print(
            json.dumps(
                {
                    "ok": False,
                    "message": (
                        "Thiếu LFMS_EMBED_TOKEN, LFMS_API_BASE hoặc DIFY_LFMS_HMAC_SECRET. "
                        "Studio /agent/ không gắn user LFMS — dán JWT từ POST /api/embed/dify-token "
                        "vào User Input, HMAC vào Environment."
                    ),
                },
                ensure_ascii=False,
            )
        )
        return 2
    if sql == "":
        print(json.dumps({"ok": False, "message": "Thiếu SQL."}, ensure_ascii=False))
        return 2

    payload = {
        "embed_token": token,
        "sql": sql,
        "natural_language_query": os.environ.get("LFMS_NL_QUERY") or "",
        "request_id": str(uuid.uuid4()),
        "context": {"source": "dify", "app": "text_to_sql_agent"},
    }
    raw = json.dumps(payload, ensure_ascii=False, separators=(",", ":"))
    timestamp = str(int(time.time()))
    nonce = str(uuid.uuid4())
    signature = _sign(raw, timestamp, nonce, secret)
    req = urllib.request.Request(
        base + PATH,
        data=raw.encode("utf-8"),
        method=METHOD,
        headers={
            "Content-Type": "application/json",
            "X-Dify-Timestamp": timestamp,
            "X-Dify-Nonce": nonce,
            "X-Dify-Signature": signature,
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            body = resp.read().decode("utf-8", "replace")
            print(body)
            return 0
    except urllib.error.HTTPError as err:
        extra = err.read().decode("utf-8", "replace")[:2000]
        print(json.dumps({"ok": False, "message": f"HTTP {err.code}", "body": extra}, ensure_ascii=False))
        return 1
    except urllib.error.URLError as err:
        print(json.dumps({"ok": False, "message": str(err.reason)}, ensure_ascii=False))
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
