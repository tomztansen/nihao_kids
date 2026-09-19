import os
import re
import sys

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
        if v_id and v_hz:
            vid = v_id.group(1)
            if vid not in seen:
                seen.add(vid)
                vocabs.append({
                    'id': vid,
                    'hanzi': v_hz.group(1),
                    'pinyin': v_py.group(1) if v_py else '',
                    'meaning': v_m.group(1) if v_m else '',
                    'file': f
                })

print(f"Total unique vocabs: {len(vocabs)}")
with open("tools/vocab_list.txt", "w", encoding="utf-8") as out:
    for i, v in enumerate(vocabs, 1):
        line = f"{i:3d}. id={v['id']:<20} hanzi={v['hanzi']:<10} pinyin={v['pinyin']:<15} meaning={v['meaning']}"
        out.write(line + "\n")
        print(line)
