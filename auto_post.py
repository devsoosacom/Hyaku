"""
百物語 自動投稿スクリプト
O:\記事作成\ の未投稿 .md ファイルを1件 Firestore に投稿する。
Windows タスクスケジューラで毎日実行する。
"""
import sys
import json
import os
import re
import urllib.request
import urllib.parse
import urllib.error
from datetime import datetime, timezone

sys.stdout.reconfigure(encoding='utf-8')

API_KEY      = 'AIzaSyAB_OLK_K5pLIbOkHAztd5k5-NYi7nJth0'
PROJECT_ID   = 'hyaku-35692'
ADMIN_EMAIL  = 'admin@hyaku.jp'
ADMIN_PASS   = 'Hyaku@2025!'
ADMIN_UID    = 'dRFL5GfO15a0fRbfmfS6uQIshvp1'
ADMIN_NAME   = '百物語編集部'

ARTICLES_DIR     = r'O:\記事作成'
POSTED_DIR       = r'O:\記事作成\投稿済'
REGISTRY         = r'O:\Hyaku\posted_registry.json'
LOG_FILE         = r'O:\Hyaku\auto_post.log'
DISCORD_WEBHOOK  = (
    'https://discord.com/api/webhooks/1500855409018142752/'
    'FTgbN1hBCI3UJXz4or5Qr8gGawJzrGqdKiNgm0iQ2YBNR0JAG6ULJ1fD4dhpEi_d0Z8t'
)

TAG_MAP = {
    '夢':     ['夢', 'ホラー'],
    '声':     ['音', '声', 'ホラー'],
    '影':     ['影', '心霊', 'ホラー'],
    '足音':   ['音', '心霊', 'ホラー'],
    '鏡':     ['鏡', '心霊', 'ホラー'],
    '写真':   ['写真', '怪奇', 'ホラー'],
    '地図':   ['地図', '怪奇', 'ホラー'],
    '手紙':   ['手紙', '怪奇', 'ホラー'],
    '日記':   ['日記', '怪奇', 'ホラー'],
    '検索':   ['インターネット', '怪奇', 'ホラー'],
    '録音':   ['音', '怪奇', 'ホラー'],
    '鍵':     ['鍵', '怪奇', 'ホラー'],
    '間取り': ['家', '怪奇', 'ホラー'],
    '隣人':   ['隣人', '怖い話', 'ホラー'],
    '電話':   ['電話', '怪奇', 'ホラー'],
    '病院':   ['病院', '心霊', 'ホラー'],
    '廃墟':   ['廃墟', '心霊', 'ホラー'],
    '駅':     ['駅', '都市伝説', 'ホラー'],
    'メッセージ': ['SNS', '怪奇', 'ホラー'],
    '遺品':   ['遺品', '実話怪談', 'ホラー'],
    '祖母':   ['実話怪談', '怖い話', 'ホラー'],
    '祖父':   ['実話怪談', '怖い話', 'ホラー'],
    '子供':   ['子供', '心霊', 'ホラー'],
    '地下':   ['地下', '怪奇', 'ホラー'],
    '森':     ['自然', '怪奇', 'ホラー'],
    '海':     ['自然', '怪奇', 'ホラー'],
    '山':     ['山', '怪奇', 'ホラー'],
}

DEFAULT_TAGS = ['実話怪談', 'ホラー', '怖い話']


def log(msg):
    now = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    line = f'[{now}] {msg}'
    print(line, flush=True)
    try:
        with open(LOG_FILE, 'a', encoding='utf-8') as f:
            f.write(line + '\n')
    except (PermissionError, OSError):
        pass


def notify_discord(title, description, success=True):
    try:
        color = 0x2ECC71 if success else 0xCC0000
        payload = json.dumps({
            'embeds': [{
                'title': title,
                'description': description,
                'color': color,
                'footer': {'text': 'hyaku-35692.web.app'},
                'timestamp': datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
            }]
        }, ensure_ascii=False).encode('utf-8')
        req = urllib.request.Request(
            DISCORD_WEBHOOK, data=payload,
            headers={'Content-Type': 'application/json', 'User-Agent': 'HyakuBot/1.0'},
            method='POST',
        )
        urllib.request.urlopen(req, timeout=10)
    except Exception:
        pass


def load_registry():
    if os.path.exists(REGISTRY):
        with open(REGISTRY, encoding='utf-8') as f:
            return set(json.load(f))
    return set()


def save_registry(posted):
    with open(REGISTRY, 'w', encoding='utf-8') as f:
        json.dump(sorted(posted), f, ensure_ascii=False, indent=2)


def get_next_article(posted):
    files = sorted([
        f for f in os.listdir(ARTICLES_DIR)
        if f.endswith('.md') and f not in posted
        and os.path.isfile(os.path.join(ARTICLES_DIR, f))
    ])
    if not files:
        return None, None
    fname = files[0]
    path = os.path.join(ARTICLES_DIR, fname)
    with open(path, encoding='utf-8-sig') as f:
        raw = f.read()
    return fname, raw


def parse_article(fname, raw):
    lines = raw.strip().split('\n')
    title = fname.replace('.md', '')
    content_lines = []
    for line in lines:
        if line.startswith('# '):
            title = line[2:].strip()
        else:
            content_lines.append(line)
    content = '\n'.join(content_lines).strip()
    return title, content


def extract_tags(title, content):
    text = title + content
    for keyword, tags in TAG_MAP.items():
        if keyword in text:
            return tags
    return DEFAULT_TAGS


def sign_in():
    url = f'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={API_KEY}'
    body = json.dumps({
        'email': ADMIN_EMAIL,
        'password': ADMIN_PASS,
        'returnSecureToken': True,
    }).encode()
    req = urllib.request.Request(url, data=body, headers={'Content-Type': 'application/json'})
    with urllib.request.urlopen(req) as r:
        return json.loads(r.read())['idToken']


def post_story(token, title, content, tags):
    url = (f'https://firestore.googleapis.com/v1/projects/{PROJECT_ID}'
           f'/databases/(default)/documents/posts')
    now = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
    body = json.dumps({
        'fields': {
            'userId':       {'stringValue': ADMIN_UID},
            'authorName':   {'stringValue': ADMIN_NAME},
            'authorPhotoUrl': {'nullValue': None},
            'title':        {'stringValue': title},
            'content':      {'stringValue': content},
            'tags':         {'arrayValue': {'values': [{'stringValue': t} for t in tags]}},
            'likedBy':      {'arrayValue': {'values': []}},
            'bookmarkedBy': {'arrayValue': {'values': []}},
            'commentCount': {'integerValue': '0'},
            'createdAt':    {'timestampValue': now},
        }
    }).encode()
    req = urllib.request.Request(url, data=body, headers={
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json',
    })
    with urllib.request.urlopen(req) as r:
        result = json.loads(r.read())
    return result['name'].split('/')[-1]


def main():
    os.makedirs(POSTED_DIR, exist_ok=True)

    posted = load_registry()
    fname, raw = get_next_article(posted)

    if fname is None:
        log('投稿する記事がありません。O:\\記事作成\\ に .md ファイルを追加してください。')
        return

    title, content = parse_article(fname, raw)
    tags = extract_tags(title, content)

    log(f'投稿開始: {fname} -> 「{title}」 タグ:{tags}')

    try:
        token = sign_in()
        post_id = post_story(token, title, content, tags)
        posted.add(fname)
        save_registry(posted)

        # Move to 投稿済 folder
        src = os.path.join(ARTICLES_DIR, fname)
        dst = os.path.join(POSTED_DIR, fname)
        os.rename(src, dst)

        post_url = f'https://hyaku-35692.web.app/post/{post_id}'
        log(f'投稿成功: postId={post_id} title={title}')
        print(f'\n投稿完了: {post_url}')

        # Discord 成功通知
        remaining = len([f for f in os.listdir(ARTICLES_DIR)
                         if f.endswith('.md') and os.path.isfile(os.path.join(ARTICLES_DIR, f))])
        notify_discord(
            f'✅ 投稿完了: {title}',
            f'[記事を読む]({post_url})\nストック残り: **{remaining}件**',
            success=True,
        )

        # X(Twitter) への自動投稿
        try:
            import subprocess
            subprocess.run(
                [sys.executable, r'O:\Hyaku\x_post.py'],
                check=False, timeout=120
            )
        except Exception as xe:
            log(f'X投稿スキップ: {xe}')

        # サイトマップ更新 & デプロイ
        try:
            subprocess.run(
                [sys.executable, r'O:\Hyaku\update_sitemap.py'],
                check=False, timeout=120
            )
        except Exception as se:
            log(f'サイトマップ更新スキップ: {se}')

    except Exception as e:
        log(f'投稿失敗: {e}')
        notify_discord('❌ 投稿失敗', str(e)[:300], success=False)
        sys.exit(1)


if __name__ == '__main__':
    main()
