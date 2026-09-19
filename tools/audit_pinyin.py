import sys
import re
from pypinyin import pinyin, Style, pinyin_dict

try:
    sys.stdout.reconfigure(encoding='utf-8')
except Exception:
    pass

files = [
    r"lib\data\curriculum_xingxing.dart",
    r"lib\data\curriculum_meihua_lower.dart",
    r"lib\data\curriculum_meihua_upper.dart"
]

vocabs = []
seen = set()
for f in files:
    with open(f, 'r', encoding='utf-8') as fp:
        c = fp.read()
    chunks = c.split('VocabItem(')[1:]
    for ch in chunks:
        end = ch.find('),')
        if end == -1:
            end = ch.find(')')
        body = ch[:end]
        v_id = re.search(r"id:\s*'([^']+)'", body)
        v_hz = re.search(r"hanzi:\s*'([^']+)'", body)
        v_py = re.search(r"pinyin:\s*'([^']+)'", body)
        v_m = re.search(r"meaningId:\s*'([^']+)'", body)
        v_t = re.search(r"tone:\s*(\d+)", body)
        if v_id and v_hz:
            vid = v_id.group(1)
            if vid not in seen:
                seen.add(vid)
                vocabs.append({
                    'id': vid,
                    'hanzi': v_hz.group(1),
                    'pinyin': v_py.group(1) if v_py else '',
                    'meaning': v_m.group(1) if v_m else '',
                    'tone': v_t.group(1) if v_t else '',
                    'file': f
                })

print(f"Total vocabulary items: {len(vocabs)}")

def normalize_py(s):
    return s.lower().replace(" ", "").replace("'", "").replace("’", "").replace("-", "").strip()

mismatches = []
polyphone_warnings = []

for v in vocabs:
    hz = v['hanzi']
    curr_py = v['pinyin']
    
    # Get standard pinyin with tone marks
    py_standard_list = pinyin(hz, style=Style.TONE)
    std_py_joined = "".join([p[0] for p in py_standard_list])
    
    # Get all heteronym (polyphone) readings
    heteronyms = pinyin(hz, style=Style.TONE, heteronym=True)
    has_poly = any(len(h) > 1 for h in heteronyms)
    
    # Normalize for comparison
    norm_curr = normalize_py(curr_py)
    norm_std = normalize_py(std_py_joined)
    
    if norm_curr != norm_std:
        # Check if curr_py matches any heteronym combination
        matched_hetero = False
        mismatches.append({
            'id': v['id'],
            'hanzi': hz,
            'curr_pinyin': curr_py,
            'std_pinyin': std_py_joined,
            'heteronyms': heteronyms,
            'meaning': v['meaning'],
            'file': v['file']
        })
    elif has_poly:
        polyphone_warnings.append({
            'id': v['id'],
            'hanzi': hz,
            'curr_pinyin': curr_py,
            'heteronyms': heteronyms,
            'meaning': v['meaning']
        })

with open("tools/mismatches.txt", "w", encoding="utf-8") as out:
    out.write(f"=== FOUND {len(mismatches)} PINYIN MISMATCHES ===\n")
    for m in mismatches:
        out.write(f"ID: {m['id']:<10} | Hanzi: {m['hanzi']:<8} | Curr Pinyin: '{m['curr_pinyin']:<15}' | Std: '{m['std_pinyin']:<15}' | Mean: {m['meaning']}\n")
        out.write(f"   Heteronyms: {m['heteronyms']}\n")

print(f"\n=== FOUND {len(mismatches)} PINYIN MISMATCHES written to tools/mismatches.txt ===")
for p in polyphone_warnings:
    print(f"ID: {p['id']} | Hanzi: {p['hanzi']} | Pinyin: {p['curr_pinyin']} | Options: {p['heteronyms']} | Mean: {p['meaning']}")
