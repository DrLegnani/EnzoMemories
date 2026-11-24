import datetime
import json
import os
import re
import urllib.request
from PIL import Image, ImageOps

ALBUM_URL = "https://photos.app.goo.gl/VrMK2FNZVtVZCiPD8"
REPO_DIR = r"C:\Users\andre\.gemini\antigravity\scratch\EnzoMemories"
ALBUM_DIR = os.path.join(REPO_DIR, "album_enzo_memorias")
RES_DIR = os.path.join(REPO_DIR, "EnzoMemories", "Resources")


def era_for_year(year: int) -> dict:
    if year <= 2012:
        return {
            "eraId": "01_chegada",
            "eraTitle": "PRÓLOGO • A CHEGADA",
            "eraSubtitle": "Ultrassom, nascimento e os primeiros dias com a família",
            "eraYears": "2010–2012",
        }
    if year == 2013:
        return {
            "eraId": "02_primeiras_aventuras",
            "eraTitle": "FASE 1 • PRIMEIRAS AVENTURAS",
            "eraSubtitle": "Primeiros voos, Golden Gate, Las Vegas e viagens pela Europa",
            "eraYears": "2013",
        }
    if year <= 2020:
        return {
            "eraId": "03_infancia_epica",
            "eraTitle": "FASE 2 • INFÂNCIA ÉPICA",
            "eraSubtitle": "Cruzeiro, praia, judô, corrida com medalha, bike e irmãozinho",
            "eraYears": "2014–2020",
        }
    if year <= 2025:
        return {
            "eraId": "04_explorando_mundo",
            "eraTitle": "FASE 3 • EXPLORANDO O MUNDO",
            "eraSubtitle": "Universal Studios, viagens em família e aventuras de inverno",
            "eraYears": "2021–2025",
        }
    return {
        "eraId": "05_colegio_alfa",
        "eraTitle": "FASE 4 • LEVEL 9: COLÉGIO ALFA",
        "eraSubtitle": "Medalhas no Alfa, família reunida e a conquista do 9º ano",
        "eraYears": "2026",
    }


def sync() -> int:
    os.makedirs(ALBUM_DIR, exist_ok=True)
    os.makedirs(RES_DIR, exist_ok=True)

    manifest_path = os.path.join(ALBUM_DIR, "manifest.json")
    old_keys = set()
    if os.path.exists(manifest_path):
        with open(manifest_path, encoding="utf-8") as f:
            old_keys = {x["mkey"] for x in json.load(f).get("items", [])}

    req = urllib.request.Request(ALBUM_URL, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=25) as r:
        html = r.read().decode("utf-8", errors="ignore")

    blocks = re.findall(r"AF_initDataCallback\(\{key:\s*'ds:1'.*?data:(.*?), sideChannel:", html, re.S)
    if not blocks:
        raise RuntimeError("Could not parse ds:1 block from Google Photos album")

    items = json.loads(blocks[0])[1]
    manifest = []
    app_entries = []
    new_count = 0

    for idx, item in enumerate(items, 1):
        mkey = item[0]
        base_url = item[1][0]
        w, h = item[1][1], item[1][2]
        ts = item[2]
        dt_obj = datetime.datetime.fromtimestamp(ts / 1000.0) if ts else None
        dt = dt_obj.strftime("%Y-%m-%d") if dt_obj else "2026-01-01"
        year = dt_obj.year if dt_obj else 2026

        if mkey not in old_keys:
            new_count += 1

        raw_name = f"memoria_{idx:02d}_{dt}_{mkey[:8]}.jpg"
        raw_path = os.path.join(ALBUM_DIR, raw_name)
        if not os.path.exists(raw_path):
            req_img = urllib.request.Request(base_url + "=w2048-h2048", headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req_img, timeout=30) as ir:
                with open(raw_path, "wb") as f:
                    f.write(ir.read())

        res_base = f"memoria_{idx:02d}"
        res_path = os.path.join(RES_DIR, f"{res_base}.jpg")
        if not os.path.exists(res_path):
            with Image.open(raw_path) as im:
                im = ImageOps.exif_transpose(im).convert("RGB")
                im.thumbnail((1600, 1600), Image.Resampling.LANCZOS)
                im.save(res_path, "JPEG", quality=86, optimize=True)

        manifest.append({
            "index": idx,
            "mkey": mkey,
            "date": dt,
            "timestamp": ts,
            "width": w,
            "height": h,
            "file": raw_name,
            "size": os.path.getsize(raw_path),
        })

        era = era_for_year(year)
        app_entries.append({
            "id": res_base,
            "resourceName": res_base,
            "date": dt,
            "year": year,
            "eraId": era["eraId"],
            "eraTitle": era["eraTitle"],
            "eraSubtitle": era["eraSubtitle"],
            "eraYears": era["eraYears"],
        })

    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump({"album_url": ALBUM_URL, "count": len(manifest), "items": manifest}, f, indent=2)

    with open(os.path.join(RES_DIR, "memories_manifest.json"), "w", encoding="utf-8") as f:
        json.dump(app_entries, f, indent=2, ensure_ascii=False)

    res_total = sum(
        os.path.getsize(os.path.join(RES_DIR, f"memoria_{i:02d}.jpg"))
        for i in range(1, len(manifest) + 1)
    )
    print(f"SYNC_OK total={len(manifest)} new={new_count} res_mb={res_total / (1024 * 1024):.2f}")
    return new_count


if __name__ == "__main__":
    sync()
