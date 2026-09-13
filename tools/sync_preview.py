import re
import json

def parse_lessons(filename):
    with open(filename, 'r', encoding='utf-8') as f:
        content = f.read()
    
    chunks = content.split('LessonTopic(')[1:]
    results = []
    for chunk in chunks:
        v_idx = chunk.find('vocabs: [')
        if v_idx == -1:
            continue
        header = chunk[:v_idx]
        vocabs_str = chunk[v_idx:]
        
        tid = re.search(r"id:\s*'([^']+)'", header)
        title = re.search(r"title:\s*'([^']+)'", header)
        emoji = re.search(r"emoji:\s*'([^']+)'", header)
        sub = re.search(r"subtitle:\s*'([^']+)'", header)
        unlocked = 'isUnlocked: true' in header
        
        v_items = vocabs_str.split('VocabItem(')[1:]
        v_list = []
        for v in v_items:
            end_v = v.find('),')
            if end_v == -1:
                end_v = v.find(')')
            v_body = v[:end_v]
            
            vid = re.search(r"id:\s*'([^']+)'", v_body)
            hz = re.search(r"hanzi:\s*'([^']+)'", v_body)
            py = re.search(r"pinyin:\s*'([^']+)'", v_body)
            m = re.search(r"meaningId:\s*'([^']+)'", v_body)
            t = re.search(r"tone:\s*(\d+)", v_body)
            e = re.search(r"emoji:\s*'([^']+)'", v_body)
            ex_hz = re.search(r"exampleSentenceHanzi:\s*'([^']+)'", v_body)
            ex_py = re.search(r"exampleSentencePinyin:\s*'([^']+)'", v_body)
            ex_id = re.search(r"exampleSentenceId:\s*'([^']+)'", v_body)
            
            if hz and py and m:
                item = {
                    'id': vid.group(1) if vid else '',
                    'hanzi': hz.group(1),
                    'pinyin': py.group(1),
                    'meaning': m.group(1),
                    'tone': int(t.group(1)) if t else 1,
                    'emoji': e.group(1) if e else '✨'
                }
                if ex_hz and ex_py and ex_id:
                    item['sentence'] = ex_hz.group(1)
                    item['sentencePy'] = ex_py.group(1)
                    item['sentenceId'] = ex_id.group(1)
                v_list.append(item)
                
        if tid and title:
            results.append({
                'id': tid.group(1),
                'title': title.group(1),
                'subtitle': sub.group(1) if sub else '',
                'emoji': emoji.group(1) if emoji else '📚',
                'starsEarned': 3 if unlocked else 0,
                'locked': not unlocked,
                'cards': v_list
            })
    return results

xing = parse_lessons(r'D:\PROJECT GMN\nihao\lib\data\curriculum_xingxing.dart')
paud_lessons = xing[:8]
tk_lessons = xing[8:]
m_low = parse_lessons(r'D:\PROJECT GMN\nihao\lib\data\curriculum_meihua_lower.dart')
m_up = parse_lessons(r'D:\PROJECT GMN\nihao\lib\data\curriculum_meihua_upper.dart')

curriculum_dict = {
    'paud': {
        'title': 'Bintang Cilik (PAUD & Nursery)',
        'lessons': paud_lessons
    },
    'tk': {
        'title': 'Tunas Ceria (TK-A & TK-B)',
        'lessons': tk_lessons
    },
    'sdLower': {
        'title': 'Penjelajah (SD Kelas 1 - 3)',
        'lessons': m_low
    },
    'sdUpper': {
        'title': 'Pendekar YCT (SD Kelas 4 - 6)',
        'lessons': m_up
    }
}

total_lessons = len(paud_lessons) + len(tk_lessons) + len(m_low) + len(m_up)
total_words = sum(len(x['cards']) for x in paud_lessons) + sum(len(x['cards']) for x in tk_lessons) + sum(len(x['cards']) for x in m_low) + sum(len(x['cards']) for x in m_up)

# Inject into preview/index.html
preview_path = r'D:\PROJECT GMN\nihao\preview\index.html'
with open(preview_path, 'r', encoding='utf-8') as f:
    html_content = f.read()

start_marker = "// DATABASE KURIKULUM LENGKAP"
end_marker = "function showScreen("

s_idx = html_content.find(start_marker)
e_idx = html_content.find(end_marker)

if s_idx != -1 and e_idx != -1:
    new_js = f"// DATABASE KURIKULUM LENGKAP (45 UNIT, {total_words} KATA)\n"
    new_js += f"    const gradeCurriculum = {json.dumps(curriculum_dict, ensure_ascii=False, indent=6)};\n\n    "
    html_content = html_content[:s_idx] + new_js + html_content[e_idx:]
    with open(preview_path, 'w', encoding='utf-8') as f:
        f.write(html_content)
    print(f"Successfully re-synced clean curriculum into {preview_path}!")
else:
    print("Could not find markers in index.html!")
