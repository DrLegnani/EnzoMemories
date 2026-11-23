#!/usr/bin/env python3
"""
Gera o clipe em vídeo de transição estilo GTA V / GTA VI usando Gemini Omni 1.2 Flash
(sucessor oficial na Gemini API para geração de vídeo com referências):
- Visão aérea de satélite/drone a 90° descendo em zoom rápido para a rua de Vice City;
- Personagem 3D estilizado realista baseado nas fotos do Enzo (14 anos);
- O personagem levanta o celular moderno revelando a tela inicial do app Enzo • Memories.

Uso no PowerShell:
    $env:GEMINI_API_KEY = "SUA_CHAVE_GEMINI_AQUI"
    pip install -U google-genai
    python generate_veo_clip.py
"""

import os
import sys
import time
from google import genai
from google.genai import types

MODEL = "gemini-omni-1.2-flash"
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
RES_DIR = os.path.join(SCRIPT_DIR, "EnzoMemories", "Resources")

DRONE_MAP_IMG = os.path.join(RES_DIR, "drone_map_90.jpg")
ENZO_REF_1 = os.path.join(RES_DIR, "enzo_hero_1.png")
ENZO_REF_2 = os.path.join(RES_DIR, "enzo_hero_3.png")
OUTPUT_MP4 = os.path.join(RES_DIR, "veo_intro.mp4")


def upload_and_wait(client: genai.Client, path: str):
    if not os.path.exists(path):
        raise FileNotFoundError(f"Arquivo de referência não encontrado: {path}")
    print(f"Enviando referência {os.path.basename(path)} para a Gemini Files API...")
    uploaded = client.files.upload(file=path)
    while str(getattr(uploaded, "state", "")).endswith("PROCESSING"):
        time.sleep(2)
        uploaded = client.files.get(name=uploaded.name)
    return uploaded


def main():
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print(
            "ERRO: Variável GEMINI_API_KEY não definida.\n"
            "No PowerShell, execute antes:\n"
            '  $env:GEMINI_API_KEY = "SUA_CHAVE"\n'
            "  python generate_veo_clip.py",
            file=sys.stderr,
        )
        sys.exit(1)

    client = genai.Client(http_options=types.HttpOptions(timeout=600 * 1000))

    map_ref = upload_and_wait(client, DRONE_MAP_IMG)
    enzo_ref1 = upload_and_wait(client, ENZO_REF_1)
    enzo_ref2 = upload_and_wait(client, ENZO_REF_2)

    prompt = (
        "Use the first image as the starting frame: a 90-degree top-down GTA V satellite drone map view "
        "of a neon-lit Miami Vice City neighborhood at sunset. "
        "In a single continuous unbroken shot: "
        "[0-3s] Three rapid GTA V character-switch camera drop zooms plunge straight down from 90-degree satellite altitude "
        "through palm trees onto a vibrant coastal street at golden hour. "
        "[3-7s] The camera lands smoothly behind the 3D stylized realistic teenage protagonist shown in the second and third reference images "
        "(14-year-old boy with black middle-part curtain hair wearing a stylish dark navy blazer and light shirt, keeping his exact facial likeness). "
        "[7-10s] He pulls out a sleek modern smartphone in his hand, lifts it toward the camera showing a glowing neon pink-and-cyan app interface on the screen, "
        "and the camera zooms directly into the phone screen filling the entire frame. No dialogue, no text overlays, cinematic 60fps GTA VI Unreal Engine lighting."
    )

    input_parts = [
        {"type": "image", "uri": map_ref.uri, "mime_type": map_ref.mime_type},
        {"type": "image", "uri": enzo_ref1.uri, "mime_type": enzo_ref1.mime_type},
        {"type": "image", "uri": enzo_ref2.uri, "mime_type": enzo_ref2.mime_type},
        {"type": "text", "text": prompt},
    ]

    print(f"Solicitando geração de vídeo com {MODEL} (10s, 1080p)...")
    interaction = client.interactions.create(
        model=MODEL,
        input=input_parts,
        response_format={
            "type": "video",
            "delivery": "uri",
            "aspect_ratio": "16:9",
            "duration": 10,
            "resolution": "1080p",
        },
    )

    output_video = getattr(interaction, "output_video", None)
    if not output_video or not getattr(output_video, "uri", None):
        raise RuntimeError(f"Nenhum vídeo retornado na resposta (interaction id: {getattr(interaction, 'id', 'N/A')}).")

    print(f"Baixando vídeo gerado para {OUTPUT_MP4}...")
    video_bytes = client.files.download(file=output_video.uri)
    with open(OUTPUT_MP4, "wb") as f:
        f.write(video_bytes)

    print(f"Sucesso! Vídeo salvo em {OUTPUT_MP4} ({len(video_bytes) / (1024*1024):.2f} MB)")


if __name__ == "__main__":
    main()
