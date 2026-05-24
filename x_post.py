"""
百物語 X(Twitter) 自動投稿スクリプト
Firestore の最新投稿を取得して、怪談カード画像付きで X に投稿する。
"""
import sys
import os
import json
import textwrap
import urllib.request
from datetime import datetime

sys.stdout.reconfigure(encoding='utf-8')

X_API_KEY             = 'UpvRaWvj3Fs0LqAZPZWoHQo59'
X_API_SECRET          = 'TsJDFiB36iT7ttr4fQqMWkdCMwGt5ICmbbMwvXCRs8hvLg5m2r'
X_ACCESS_TOKEN        = '2054811077343662081-UvA0kXcap5FEUYsEOcmLwcK2jEp6F8'
X_ACCESS_TOKEN_SECRET = 'szQx7uEB7TlKBQaGoitPRVwkahaADJYOCD59B4BOfFJZ2'

API_KEY    = 'AIzaSyAB_OLK_K5pLIbOkHAztd5k5-NYi7nJth0'
PROJECT_ID = 'hyaku-35692'
ADMIN_EMAIL = 'admin@hyaku.jp'
ADMIN_PASS  = 'Hyaku@2025!'
BASE_URL    = 'https://hyaku-35692.web.app'
LOG_FILE    = r'O:\Hyaku\x_post.log'
CARD_FILE   = r'O:\Hyaku\tweet_card.png'

FONT_TITLE  = r'C:\Windows\Fonts\yumindb.ttf'   # 遊明朝 Bold
FONT_BODY   = r'C:\Windows\Fonts\yumin.ttf'      # 遊明朝
FONT_SMALL  = r'C:\Windows\Fonts\meiryo.ttc'     # Meiryo


def log(msg):
    now = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    line = f'[{now}] {msg}'
    print(line, flush=True)
    try:
        with open(LOG_FILE, 'a', encoding='utf-8') as f:
            f.write(line + '\n')
    except (PermissionError, OSError):
        pass


def sign_in():
    url = f'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={API_KEY}'
    body = json.dumps({'email': ADMIN_EMAIL, 'password': ADMIN_PASS, 'returnSecureToken': True}).encode()
    req = urllib.request.Request(url, data=body, headers={'Content-Type': 'application/json'})
    with urllib.request.urlopen(req) as r:
        return json.loads(r.read())['idToken']


def get_latest_post(id_token):
    url = (f'https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents/posts'
           f'?pageSize=1&orderBy=createdAt+desc')
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


def clean_text(content):
    """本文からMarkdown記号・BOMを除去してプレーンテキストに"""
    content = content.lstrip('﻿').strip()
    lines = [
        l.strip() for l in content.split('【解説】')[0].split('\n')
        if l.strip() and not l.startswith('#') and not l.startswith('---')
    ]
    return '\n'.join(lines)


def generate_card(title, body_text, url):
    """怪談カード画像を生成して CARD_FILE に保存"""
    from PIL import Image, ImageDraw, ImageFont

    W, H = 1200, 675
    img = Image.new('RGB', (W, H), color=(8, 8, 8))
    draw = ImageDraw.Draw(img)

    # --- 背景装飾: 右上に薄い赤グロー ---
    for r in range(200, 0, -20):
        alpha = int(18 * (1 - r / 200))
        draw.ellipse([(W - r, -r), (W + r, r)], fill=(120, 0, 0))

    # --- 左端の赤ライン ---
    draw.rectangle([(0, 0), (5, H)], fill=(180, 0, 0))

    # --- サイトロゴ ---
    try:
        f_small = ImageFont.truetype(FONT_SMALL, 28)
    except Exception:
        f_small = ImageFont.load_default()
    draw.text((30, 28), '百物語', font=f_small, fill=(180, 0, 0))
    draw.text((110, 32), '| 怪談投稿コミュニティ', font=f_small, fill=(80, 80, 80))

    # --- タイトル ---
    try:
        f_title = ImageFont.truetype(FONT_TITLE, 62)
    except Exception:
        f_title = ImageFont.load_default()

    title_y = 100
    # タイトルが長い場合は折り返し
    if len(title) <= 14:
        draw.text((30, title_y), title, font=f_title, fill=(238, 238, 238))
        title_bottom = title_y + 80
    else:
        lines = textwrap.wrap(title, width=14)
        for i, line in enumerate(lines[:2]):
            draw.text((30, title_y + i * 72), line, font=f_title, fill=(238, 238, 238))
        title_bottom = title_y + len(lines[:2]) * 72

    # --- 区切り線 ---
    draw.rectangle([(30, title_bottom + 16), (180, title_bottom + 19)], fill=(140, 0, 0))

    # --- 本文抜粋 ---
    try:
        f_body = ImageFont.truetype(FONT_BODY, 34)
    except Exception:
        f_body = ImageFont.load_default()

    body_y = title_bottom + 44
    max_body_h = H - body_y - 80
    lines_available = max_body_h // 52

    def wrap_pil(text, font, max_width):
        """PILフォントで実際の描画幅を計測して折り返す"""
        lines, current = [], ''
        for ch in text:
            test = current + ch
            w = draw.textlength(test, font=font)
            if w > max_width and current:
                lines.append(current)
                current = ch
            else:
                current = test
        if current:
            lines.append(current)
        return lines

    body_lines = []
    max_text_w = W - 60
    for para in body_text.split('\n'):
        body_lines.extend(wrap_pil(para, f_body, max_text_w))
        if len(body_lines) >= lines_available:
            break

    body_lines = body_lines[:lines_available]
    if body_text and len('\n'.join(body_lines)) < len(body_text[:200]):
        if body_lines:
            body_lines[-1] = body_lines[-1].rstrip('…') + '…'

    for i, line in enumerate(body_lines):
        draw.text((30, body_y + i * 52), line, font=f_body, fill=(180, 180, 180))

    # --- URL（下部） ---
    try:
        f_url = ImageFont.truetype(FONT_SMALL, 24)
    except Exception:
        f_url = ImageFont.load_default()
    draw.text((30, H - 44), url, font=f_url, fill=(80, 80, 80))

    img.save(CARD_FILE, 'PNG', optimize=True)
    return CARD_FILE


def build_tweet(post):
    title = post['title']
    url   = f"{BASE_URL}/post/{post['id']}"
    tags  = post['tags'][:3]
    hashtags = ' '.join(f'#{t}' for t in tags) + ' #百物語 #怪談'
    # 画像付きなので本文抜粋はなし → タイトル＋URL＋タグだけシンプルに
    return f"【{title}】\n\n{url}\n\n{hashtags}"


def post_to_x(tweet_text, image_path=None):
    try:
        import tweepy
    except ImportError:
        log('ERROR: tweepy がインストールされていません。')
        return None

    # メディアアップロード (API v1.1)
    media_id = None
    if image_path and os.path.exists(image_path):
        try:
            auth = tweepy.OAuth1UserHandler(X_API_KEY, X_API_SECRET, X_ACCESS_TOKEN, X_ACCESS_TOKEN_SECRET)
            api_v1 = tweepy.API(auth)
            media = api_v1.media_upload(filename=image_path)
            media_id = media.media_id
            log(f'画像アップロード成功: media_id={media_id}')
        except Exception as e:
            log(f'画像アップロード失敗（テキストのみで続行）: {e}')

    # ツイート投稿 (API v2)
    client = tweepy.Client(
        consumer_key=X_API_KEY,
        consumer_secret=X_API_SECRET,
        access_token=X_ACCESS_TOKEN,
        access_token_secret=X_ACCESS_TOKEN_SECRET,
    )
    kwargs = {'text': tweet_text}
    if media_id:
        kwargs['media_ids'] = [media_id]

    response = client.create_tweet(**kwargs)
    return response.data['id']


def main():
    log('=== X 自動投稿 開始 ===')

    id_token = sign_in()
    log('Firestore 認証OK')

    post = get_latest_post(id_token)
    if not post:
        log('投稿が見つかりませんでした')
        return

    log(f'投稿取得: {post["title"]} (id={post["id"]})')

    # カード画像生成
    body_text = clean_text(post['content'])
    url = f"{BASE_URL}/post/{post['id']}"
    try:
        generate_card(post['title'], body_text, url)
        log(f'カード画像生成: {CARD_FILE}')
    except Exception as e:
        log(f'カード生成失敗（テキストのみで続行）: {e}')

    tweet = build_tweet(post)
    log(f'ツイート内容 ({len(tweet)}文字):\n{tweet}')

    tweet_id = post_to_x(tweet, CARD_FILE)
    if tweet_id:
        log(f'✅ ツイート成功: https://x.com/i/web/status/{tweet_id}')
    else:
        log('❌ ツイート失敗')


if __name__ == '__main__':
    main()
