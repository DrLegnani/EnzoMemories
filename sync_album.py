import datetime
import glob
import json
import os
import re
import shutil
import urllib.request
from PIL import Image, ImageOps

ALBUM_URL = "https://photos.app.goo.gl/VrMK2FNZVtVZCiPD8"
REPO_DIR = r"C:\Users\andre\.gemini\antigravity\scratch\EnzoMemories"
ALBUM_DIR = os.path.join(REPO_DIR, "album_enzo_memorias")
RES_DIR = os.path.join(REPO_DIR, "EnzoMemories", "Resources")

# Itens removidos a pedido do usuário (print de mapa e duplicatas)
EXCLUDED_KEYS = {
    "AF1QipMcKAxrtyrFcL0X66z84_VHWEKx6se4RFFKPcJ9",  # print mapa DISTRITO VICE
    "AF1QipPiIyOccKweatEc8gyNDy1llOlD6KDZzsy3SJSk",  # duplicata de #76
    "AF1QipM_WRSjIkABQdhRBSxbkFBeDdVWzTKGmyNOHNu6",  # duplicata de #77 (trampolim)
}

# Correções manuais de datas/temas (ex: formatura 4ª série em dez/2017 e Stories/TBTs de 2026-11-24)
DATE_OVERRIDES = {
    "AF1QipOKaRKnT-WddTiAOIrgaqdqTHlFiOH4DGA5USh3": "2017-12-15",
    # Infância / Europa / Judô (Fase 2)
    "AF1QipPoX7lFjUDoCcrO84P1i_ue35hm4knRPvkmwvz7": "2018-06-10",
    "AF1QipN8uxyn95PKZJDaKaW_JneVwCYLhdA-rddfcGnX": "2018-06-11",
    "AF1QipPe6Cv70UtJLtZHA27nO_1AlcN2yUmiBWvHq5dJ": "2018-06-12",
    "AF1QipNITPwU1xUbnvq0fAxG22vNiM7m5BfPQWo7rZRj": "2018-06-13",
    "AF1QipNb0-cU8kadpNEZvTmHoN7eYIFXa0qtQ_QZM42a": "2018-06-14",
    "AF1QipN940My-9NP4xVS3Nf4kvehiQHfDigKD9BFJpbm": "2018-06-15",
    "AF1QipNL5xgaNAD60KjoRKG2ok0l6UnyTRPtOdo_5Nc2": "2018-06-16",
    "AF1QipObR_2Tt86-C-zvEXfn5pVC2XKkX9Zl2XVCbykm": "2018-06-17",
    "AF1QipPiz_lWzEGHVIf0RGrJoA7S4KO_5D3iwNAiMyxd": "2018-06-18",
    "AF1QipM_VG1RIsEp1DtoQUcHuc8lKptvDVKqDh_tUgQQ": "2018-06-19",
    "AF1QipP1Z7u820xpFlaAV-uuDxT2qYwKR-uZz6Cc1hUf": "2018-06-20",
    "AF1QipO1XN1x7jSKmYXBlCLljJZ0UjXiIgOTHAUG38M6": "2018-08-12",
    # Viagens EUA / Parques / NY (Fase 3)
    "AF1QipOz79UGoncaq_FvAsR56AKx5f7CAXZEi0oamhWs": "2022-11-01",
    "AF1QipNnJ04PjKZreeR64mpcy5fPQCFW6RoNhIxqimfo": "2022-11-02",
    "AF1QipNQMn3CR1NqqCh29KTWmUltmq2Z6WwT2IRR4Trv": "2022-11-07",
    "AF1QipOetnER5nEN7KWnjTY76Af5IrxFQIweoDv0xSIt": "2022-11-08",
    "AF1QipMMmNg2XM7bpJFUjQFv5Eg_G4KHEV_pzhcmQ7bF": "2025-02-05",
    "AF1QipPa5K2OlXLP48zoSnrnaAIv6m6qNuHyP0yKMgnr": "2025-02-08",
    "AF1QipO_QmOHyuXtUa3uYvm3WWbc24yIlokYES1zWp2O": "2025-02-12",
    "AF1QipPMtiKJhamLPrFhGAs5b0SZ3iA2xAtR8Gnda45u": "2025-02-16",
    "AF1QipPZHSiXSMj0j01WOKD_zwwFh_mkwhxxj5PqoBNt": "2025-02-17",
    "AF1QipNRX_jYPAmYC0aLq4L8T8c-IyBJrHnTzstQ7IBo": "2025-02-17",
    "AF1QipNyryfgDaN3i89GkhD9FRcT1jBeeBVD9JaxX4YX": "2025-02-17",
    "AF1QipOCbePJvhSgvBYRvTvF_aSME9VM7F8l8LM9lJfU": "2022-11-04",
    "AF1QipNAaHsmieq33YkepGIdni-7G5WIpQpCVR-bEKXY": "2025-02-08",
    "AF1QipPuVcZzELNJV9HBpd4vO2kgmX2Fa8XXRwrkDUxU": "2022-11-05",
}

# Vídeos/GIFs já nomeados manualmente por data
MANUAL_VIDEO_BY_DATE = {
    "2012-04-13": ("clip_01_Ultrassom (2012)", "mov"),
    "2013-04-01": ("clip_02_Primeiros Meses (2013)", "mp4"),
    "2025-02-18": ("clip_06_Animacao Viagem (2025)", "gif"),
}

# Nomes amigáveis para os novos vídeos do álbum
VIDEO_TITLES = {
    "AF1QipPm5a9H": "Reveillon em Familia (2021)",
    "AF1QipPoX7lF": "Viagem de Aviao (Infancia)",
    "AF1QipPe6Cv7": "Tunel de Gelo (Europa)",
    "AF1QipNL5xga": "Campo de Tulipas",
    "AF1QipPiz_lW": "Passeio de Teleferico",
    "AF1QipP1Z7u8": "Aeroporto em Familia",
    "AF1QipNnJ04P": "Parque Jurassic",
    "AF1QipNQMn3C": "Miami Drive",
    "AF1QipPuVcZz": "Montanha Russa TBT",
}


def era_for_year(year: int) -> dict:
    if year <= 2012:
        return {
            "eraId": "01_chegada",
            "eraTitle": "PRÓLOGO • A CHEGADA",
            "eraSubtitle": "Ultrassom, nascimento e os primeiros dias com a família",
            "eraYears": "2012",
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
            "eraSubtitle": "Cruzeiro, formatura 4ª série (2017), judô, corrida e Europa",
            "eraYears": "2014–2020",
        }
    if year <= 2025:
        return {
            "eraId": "04_explorando_mundo",
            "eraTitle": "FASE 3 • EXPLORANDO O MUNDO",
            "eraSubtitle": "Miami, Universal Studios, Las Vegas, Nova York e família",
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
    old_by_key = {}
    if os.path.exists(manifest_path):
        with open(manifest_path, encoding="utf-8") as f:
            for x in json.load(f).get("items", []):
                old_by_key[x["mkey"]] = x

    req = urllib.request.Request(ALBUM_URL, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=25) as r:
        html = r.read().decode("utf-8", errors="ignore")

    blocks = re.findall(r"AF_initDataCallback\(\{key:\s*'ds:1'.*?data:(.*?), sideChannel:", html, re.S)
    if not blocks:
        raise RuntimeError("Could not parse ds:1 block from Google Photos album")

    raw_items = json.loads(blocks[0])[1]
    enriched = []
    new_count = 0

    for item in raw_items:
        mkey = item[0]
        if mkey in EXCLUDED_KEYS:
            continue

        base_url = item[1][0]
        w, h = item[1][1], item[1][2]
        ts = item[2]
        dt_obj = datetime.datetime.fromtimestamp(ts / 1000.0) if ts else None
        dt = DATE_OVERRIDES.get(mkey, dt_obj.strftime("%Y-%m-%d") if dt_obj else "2026-01-01")
        year = int(dt[:4])

        s_dump = json.dumps(item)
        is_vid = ("video" in s_dump.lower()) or ("76647426" in s_dump) or ("139842850" in s_dump)

        if mkey not in old_by_key:
            new_count += 1

        cached_file = old_by_key.get(mkey, {}).get("file")
        if cached_file and os.path.exists(os.path.join(ALBUM_DIR, cached_file)):
            raw_path = os.path.join(ALBUM_DIR, cached_file)
            raw_name = cached_file
        else:
            raw_name = f"raw_{dt}_{mkey[:8]}.jpg"
            raw_path = os.path.join(ALBUM_DIR, raw_name)
            if not os.path.exists(raw_path):
                req_img = urllib.request.Request(base_url + "=w2048-h2048", headers={"User-Agent": "Mozilla/5.0"})
                with urllib.request.urlopen(req_img, timeout=30) as ir:
                    with open(raw_path, "wb") as f:
                        f.write(ir.read())

        vid_info = MANUAL_VIDEO_BY_DATE.get(dt)
        if is_vid and not vid_info:
            vid_raw = os.path.join(ALBUM_DIR, f"vid_{mkey[:12]}.mp4")
            if not os.path.exists(vid_raw):
                downloaded_vid = False
                for suffix in ("=dv", "=m22", "=m18"):
                    try:
                        req_vid = urllib.request.Request(base_url + suffix, headers={"User-Agent": "Mozilla/5.0"})
                        with urllib.request.urlopen(req_vid, timeout=60) as vr:
                            ct = vr.headers.get("Content-Type", "")
                            if "video" in ct or "octet-stream" in ct:
                                with open(vid_raw, "wb") as f:
                                    f.write(vr.read())
                                downloaded_vid = True
                                break
                    except Exception:
                        continue
            if os.path.exists(vid_raw):
                title = VIDEO_TITLES.get(mkey[:12], f"Memoria {dt}")
                clip_base = f"clip_album_{dt}_{title}"
                clip_dst = os.path.join(RES_DIR, f"{clip_base}.mp4")
                if not os.path.exists(clip_dst):
                    shutil.copy2(vid_raw, clip_dst)
                vid_info = (clip_base, "mp4")

        enriched.append({
            "mkey": mkey,
            "date": dt,
            "year": year,
            "timestamp": ts,
            "width": w,
            "height": h,
            "file": raw_name,
            "raw_path": raw_path,
            "vid_info": vid_info,
        })

    enriched.sort(key=lambda x: (x["date"], x["timestamp"] or 0, x["mkey"]))

    # Remove memoria_*.jpg antigas antes de regravar na nova contagem
    for old_mem in glob.glob(os.path.join(RES_DIR, "memoria_*.jpg")):
        os.remove(old_mem)

    manifest = []
    app_entries = []
    for idx, entry in enumerate(enriched, 1):
        res_base = f"memoria_{idx:02d}"
        res_path = os.path.join(RES_DIR, f"{res_base}.jpg")
        with Image.open(entry["raw_path"]) as im:
            im = ImageOps.exif_transpose(im).convert("RGB")
            im.thumbnail((1600, 1600), Image.Resampling.LANCZOS)
            im.save(res_path, "JPEG", quality=86, optimize=True)

        manifest.append({
            "index": idx,
            "mkey": entry["mkey"],
            "date": entry["date"],
            "timestamp": entry["timestamp"],
            "width": entry["width"],
            "height": entry["height"],
            "file": entry["file"],
            "size": os.path.getsize(entry["raw_path"]),
        })

        era = era_for_year(entry["year"])
        vid = entry["vid_info"]
        app_entries.append({
            "id": res_base,
            "resourceName": res_base,
            "date": entry["date"],
            "year": entry["year"],
            "eraId": era["eraId"],
            "eraTitle": era["eraTitle"],
            "eraSubtitle": era["eraSubtitle"],
            "eraYears": era["eraYears"],
            "videoResourceName": vid[0] if vid else None,
            "videoExt": vid[1] if vid else None,
        })

    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump({"album_url": ALBUM_URL, "count": len(manifest), "items": manifest}, f, indent=2)

    with open(os.path.join(RES_DIR, "memories_manifest.json"), "w", encoding="utf-8") as f:
        json.dump(app_entries, f, indent=2, ensure_ascii=False)

    res_total = sum(
        os.path.getsize(os.path.join(RES_DIR, f"memoria_{i:02d}.jpg"))
        for i in range(1, len(manifest) + 1)
    )
    clips = glob.glob(os.path.join(RES_DIR, "clip_*"))
    clips_mb = sum(os.path.getsize(c) for c in clips) / (1024 * 1024)
    print(f"SYNC_OK total={len(manifest)} new={new_count} clips={len(clips)} clips_mb={clips_mb:.2f} mem_mb={res_total / (1024 * 1024):.2f}")
    return new_count


if __name__ == "__main__":
    sync()
