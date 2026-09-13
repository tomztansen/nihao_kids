import os
import sys
import re
import math
import struct
import wave
import asyncio
import requests
import edge_tts

try:
    sys.stdout.reconfigure(encoding='utf-8')
except Exception:
    pass

# Voice configuration: Xiaoxiao is Microsoft's neural voice - friendly, warm, ideal for children
VOICE_NAME = "zh-CN-XiaoxiaoNeural"
RATE_ADJUST = "-10%"

OUTPUT_WORDS_DIR = r"D:\PROJECT GMN\nihao\assets\audio\words"
OUTPUT_SFX_DIR = r"D:\PROJECT GMN\nihao\assets\audio\sfx"
PREVIEW_WORDS_DIR = r"D:\PROJECT GMN\nihao\preview\audio\words"
PREVIEW_SFX_DIR = r"D:\PROJECT GMN\nihao\preview\audio\sfx"

for d in [OUTPUT_WORDS_DIR, OUTPUT_SFX_DIR, PREVIEW_WORDS_DIR, PREVIEW_SFX_DIR]:
    os.makedirs(d, exist_ok=True)

def parse_vocabs_from_file(filepath):
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    chunks = content.split("VocabItem(")[1:]
    items = []
    for c in chunks:
        end_idx = c.find("),")
        if end_idx == -1:
            end_idx = c.find(")")
        body = c[:end_idx]

        v_id = re.search(r"id:\s*'([^']+)'", body)
        v_hz = re.search(r"hanzi:\s*'([^']+)'", body)
        v_py = re.search(r"pinyin:\s*'([^']+)'", body)
        v_m = re.search(r"meaningId:\s*'([^']+)'", body)

        if v_id and v_hz:
            items.append({
                "id": v_id.group(1),
                "hanzi": v_hz.group(1),
                "pinyin": v_py.group(1) if v_py else "",
                "meaning": v_m.group(1) if v_m else ""
            })
    return items

def fallback_google_tts(text, target_path):
    url = "https://translate.google.com/translate_tts"
    params = {
        "ie": "UTF-8",
        "tl": "zh-CN",
        "client": "tw-ob",
        "q": text
    }
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
    }
    resp = requests.get(url, params=params, headers=headers, timeout=10)
    if resp.status_code == 200 and len(resp.content) > 500:
        with open(target_path, "wb") as f:
            f.write(resp.content)
        return True
    return False

async def generate_word_audio(item):
    vocab_id = item["id"]
    hanzi = item["hanzi"]
    target_path = os.path.join(OUTPUT_WORDS_DIR, f"{vocab_id}.mp3")
    preview_path = os.path.join(PREVIEW_WORDS_DIR, f"{vocab_id}.mp3")

    if os.path.exists(target_path) and os.path.getsize(target_path) > 1000:
        if not os.path.exists(preview_path):
            with open(target_path, "rb") as src, open(preview_path, "wb") as dst:
                dst.write(src.read())
        return True

    try:
        tts = edge_tts.Communicate(text=hanzi, voice=VOICE_NAME, rate=RATE_ADJUST)
        await tts.save(target_path)
        if os.path.exists(target_path) and os.path.getsize(target_path) > 1000:
            with open(target_path, "rb") as src, open(preview_path, "wb") as dst:
                dst.write(src.read())
            return True
    except Exception as e:
        print(f"Edge-TTS failed for {hanzi} ({vocab_id}): {e}")

    success = fallback_google_tts(hanzi, target_path)
    if success:
        with open(target_path, "rb") as src, open(preview_path, "wb") as dst:
            dst.write(src.read())
    return success

def generate_wav_sfx(filename, tones, sample_rate=22050):
    total_samples = []
    for freq, duration, vol in tones:
        num_samples = int(duration * sample_rate)
        for i in range(num_samples):
            t = float(i) / sample_rate
            fade_len = int(num_samples * 0.15)
            envelope = 1.0
            if i < fade_len:
                envelope = i / fade_len
            else:
                envelope = 1.0 - ((i - fade_len) / (num_samples - fade_len))
            val = math.sin(2.0 * math.pi * freq * t) * envelope * vol
            total_samples.append(val)

    filepath = os.path.join(OUTPUT_SFX_DIR, filename)
    with wave.open(filepath, "w") as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        for s in total_samples:
            clipped = max(-1.0, min(1.0, s))
            data = struct.pack("<h", int(clipped * 32767))
            wav_file.writeframesraw(data)
    
    preview_sfx = os.path.join(PREVIEW_SFX_DIR, filename)
    with open(filepath, "rb") as src, open(preview_sfx, "wb") as dst:
        dst.write(src.read())

def generate_all_sfx():
    print("Generating UI Sound Effects (SFX)...")
    generate_wav_sfx("click.wav", [(880, 0.04, 0.7), (1320, 0.06, 0.5)])
    generate_wav_sfx("success.wav", [
        (523.25, 0.09, 0.6),
        (659.25, 0.09, 0.7),
        (783.99, 0.11, 0.8),
        (1046.50, 0.28, 0.9)
    ])
    generate_wav_sfx("fanfare.wav", [
        (523.25, 0.12, 0.7),
        (523.25, 0.08, 0.7),
        (523.25, 0.08, 0.7),
        (659.25, 0.25, 0.8),
        (783.99, 0.20, 0.8),
        (1046.50, 0.50, 1.0)
    ])
    generate_wav_sfx("wrong.wav", [
        (350, 0.12, 0.5),
        (260, 0.22, 0.4)
    ])
    print("UI SFX successfully generated!")

async def main():
    files = [
        r"D:\PROJECT GMN\nihao\lib\data\curriculum_xingxing.dart",
        r"D:\PROJECT GMN\nihao\lib\data\curriculum_meihua_lower.dart",
        r"D:\PROJECT GMN\nihao\lib\data\curriculum_meihua_upper.dart"
    ]

    all_vocabs = []
    seen_ids = set()
    for f in files:
        items = parse_vocabs_from_file(f)
        for it in items:
            if it["id"] not in seen_ids:
                seen_ids.add(it["id"])
                all_vocabs.append(it)

    print(f"Total vocabulary words to generate: {len(all_vocabs)}")
    generate_all_sfx()

    success_count = 0
    fail_count = 0

    for i, vocab in enumerate(all_vocabs, start=1):
        ok = await generate_word_audio(vocab)
        if ok:
            success_count += 1
            if i % 20 == 0 or i == len(all_vocabs):
                try:
                    print(f"Progress: [{i}/{len(all_vocabs)}] Generated: {vocab['id']} ({vocab['pinyin']} - {vocab['meaning']})")
                except Exception:
                    print(f"Progress: [{i}/{len(all_vocabs)}] Generated: {vocab['id']}")
        else:
            fail_count += 1
            print(f"Failed: {vocab['id']}")
        await asyncio.sleep(0.05)

    print(f"\nCOMPLETED! Generated {success_count}/{len(all_vocabs)} words (Failed: {fail_count})")

if __name__ == "__main__":
    asyncio.run(main())
