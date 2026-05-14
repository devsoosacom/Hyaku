"""
百物語 X(Twitter) 自動投稿スクリプト
Firestore の最新投稿を取得して X に投稿する。
auto_post.py と組み合わせて、記事投稿後に実行する。

必要なライブラリ: pip install tweepy
"""
import sys
import json
import urllib.request
import urllib.parse
from datetime import datetime, timezone, timedelta

sys.stdout.reconfigure(encoding='utf-8')

# ========================================================
# TODO: X Developer Portal で取得したキーを設定してください
# https://developer.x.com → Projects & Apps → Keys and tokens
# ========================================================
X_API_KEY             = 'UpvRaWvj3Fs0LqAZPZWoHQo59'
X_API_SECRET          = 'TsJDFiB36iT7ttr4fQqMWkdCMwGt5ICmbbMwvXCRs8hvLg5m2r'
X_ACCESS_TOKEN        = '2054811077343662081-UvA0kXcap5FEUYsEOcmLwcK2jEp6F8'
X_ACCESS_TOKEN_SECRET = 'szQx7uEB7TlKBQaGoitPRVwkahaADJYOCD59B4BOfFJZ2'
# ========================================================

API_KEY    = 'AIzaSyAB_OLK_K5pLIbOkHAztd5k5-NYi7nJth0'
PROJECT_ID = 'hyaku-35692'
ADMIN_EMAIL = 'admin@hyaku.jp'
ADMIN_PASS  = 'Hyaku@2025!'
BASE_URL    = 'https://hyaku-35692.web.app'
LOG_FILE    = r'O:\Hyaku\x_post.log'


def log(msg):
    now = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    line = f'[{now}] {msg}'
    print(line)
    with open(LOG_FILE, 'a', encoding='utf-8') as f:
        f.write(line + '\n')


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


def get_latest_post(id_token):
    """Firestoreから最新の投稿を1件取得"""
    url = (
        f'https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents/posts'
        f'?pageSize=1&orderBy=createdAt+desc'
    )
    req = urllib.request.Request(url, headers={'Authorization': f'Bearer {id_token}'})
    with urllib.request.urlopen(req) as r:
        data = json.loads(r.read())
    docs = data.get('documents', [])
    if not docs:
        return None
    doc = docs[0]
    fields = doc.get('fields', {})
    doc_id = doc['name'].split('/')[-1]

    def fv(key):
        f = fields.get(key, {})
        return f.get('stringValue') or f.get('integerValue') or ''

    return {
        'id':      doc_id,
        'title':   fv('title'),
        'content': fv('content'),
        'tags':    [v['stringValue'] for v in fields.get('tags', {}).get('arrayValue', {}).get('values', [])],
    }


def build_tweet(post):
    """ツイート文を構成（280文字以内）"""
    title   = post['title']
    content = post['content']
    url     = f"{BASE_URL}/post/{post['id']}"
    tags    = post['tags'][:3]

    # 本文から【解説】より前の部分だけ抜粋（Markdownヘッダーを除去）
    body = content.split('【解説】')[0].strip()
    first_lines = [
        l.strip() for l in body.split('\n')
        if l.strip() and not l.startswith('#') and not l.startswith('---')
    ]
    excerpt = first_lines[0] if first_lines else ''
    if len(excerpt) > 60:
        excerpt = excerpt[:60] + '…'

    hashtags = ' '.join(f'#{t}' for t in tags) + ' #百物語 #怪談'

    tweet = f"【{title}】\n\n{excerpt}\n\n{url}\n\n{hashtags}"

    # 280文字を超える場合は本文を短縮
    if len(tweet) > 280:
        max_excerpt = 280 - len(f"【{title}】\n\n…\n\n{url}\n\n{hashtags}") - 1
        excerpt = excerpt[:max(0, max_excerpt)] + '…'
        tweet = f"【{title}】\n\n{excerpt}\n\n{url}\n\n{hashtags}"

    return tweet


def post_to_x(tweet_text):
    """X API v2 でツイートを投稿（tweepy使用）"""
    try:
        import tweepy
    except ImportError:
        log('ERROR: tweepy がインストールされていません。pip install tweepy を実行してください。')
        return False

    if 'YOUR_API_KEY' in X_API_KEY:
        log('ERROR: X APIキーが設定されていません。x_post.py の冒頭を編集してください。')
        return False

    client = tweepy.Client(
        consumer_key=X_API_KEY,
        consumer_secret=X_API_SECRET,
        access_token=X_ACCESS_TOKEN,
        access_token_secret=X_ACCESS_TOKEN_SECRET,
    )
    response = client.create_tweet(text=tweet_text)
    tweet_id = response.data['id']
    return tweet_id


def main():
    log('=== X 自動投稿 開始 ===')

    id_token = sign_in()
    log('Firestore 認証OK')

    post = get_latest_post(id_token)
    if not post:
        log('投稿が見つかりませんでした')
        return

    log(f'投稿取得: {post["title"]} (id={post["id"]})')

    tweet = build_tweet(post)
    log(f'ツイート内容 ({len(tweet)}文字):\n{tweet}')

    tweet_id = post_to_x(tweet)
    if tweet_id:
        log(f'✅ ツイート成功: https://x.com/i/web/status/{tweet_id}')
    else:
        log('❌ ツイート失敗')


if __name__ == '__main__':
    main()
