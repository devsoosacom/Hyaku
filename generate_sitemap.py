"""
Firestore から全投稿IDを取得して sitemap.xml を生成する。
デプロイ前に実行する。
"""
import sys
import json
import urllib.parse
import urllib.request
import urllib.error
from datetime import datetime, timezone

sys.stdout.reconfigure(encoding='utf-8')

TOKEN_CACHE   = r'O:\Hyaku\.firebase_token.json'
PROJECT_ID    = 'hyaku-35692'
SITEMAP_OUT   = r'O:\Hyaku\app\web\sitemap.xml'
BASE_URL      = 'https://hyaku-35692.web.app'
CLIENT_ID     = '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com'
CLIENT_SECRET = 'j9iVZfS8kkCEFUPaAeJV0sAi'

STATIC_URLS = [
    ('/',        '1.0', 'daily'),
    ('/feed',    '0.9', 'daily'),
    ('/search',  '0.7', 'weekly'),
]


def get_access_token():
    with open(TOKEN_CACHE) as f:
        cached = json.load(f)
    body = urllib.parse.urlencode({
        'refresh_token': cached['refresh_token'],
        'client_id':     CLIENT_ID,
        'client_secret': CLIENT_SECRET,
        'grant_type':    'refresh_token',
    }).encode()
    req = urllib.request.Request('https://oauth2.googleapis.com/token', data=body)
    with urllib.request.urlopen(req) as r:
        return json.loads(r.read())['access_token']


def fetch_all_posts(token):
    docs = []
    url = (
        f'https://firestore.googleapis.com/v1/projects/{PROJECT_ID}'
        f'/databases/(default)/documents/posts?pageSize=300'
        f'&fields=documents.name,documents.updateTime,nextPageToken'
    )
    headers = {'Authorization': f'Bearer {token}'}
    while url:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req) as r:
            data = json.loads(r.read())
        docs.extend(data.get('documents', []))
        page_token = data.get('nextPageToken')
        if page_token:
            base = (
                f'https://firestore.googleapis.com/v1/projects/{PROJECT_ID}'
                f'/databases/(default)/documents/posts?pageSize=300'
                f'&fields=documents.name,documents.updateTime,nextPageToken'
            )
            url = base + f'&pageToken={urllib.parse.quote(page_token)}'
        else:
            url = None
    return docs


def fmt_date(iso):
    try:
        dt = datetime.fromisoformat(iso.replace('Z', '+00:00'))
        return dt.strftime('%Y-%m-%d')
    except Exception:
        return datetime.now(timezone.utc).strftime('%Y-%m-%d')


def build_sitemap(docs):
    lines = ['<?xml version="1.0" encoding="UTF-8"?>',
             '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">']

    for path, priority, freq in STATIC_URLS:
        lines += [
            '  <url>',
            f'    <loc>{BASE_URL}{path}</loc>',
            f'    <changefreq>{freq}</changefreq>',
            f'    <priority>{priority}</priority>',
            '  </url>',
        ]

    for doc in docs:
        doc_id = doc['name'].split('/')[-1]
        lastmod = fmt_date(doc.get('updateTime', ''))
        lines += [
            '  <url>',
            f'    <loc>{BASE_URL}/post/{doc_id}</loc>',
            f'    <lastmod>{lastmod}</lastmod>',
            '    <changefreq>monthly</changefreq>',
            '    <priority>0.6</priority>',
            '  </url>',
        ]

    lines.append('</urlset>')
    return '\n'.join(lines)


if __name__ == '__main__':
    print('アクセストークン取得中...')
    token = get_access_token()

    print('Firestore から投稿一覧を取得中...')
    docs = fetch_all_posts(token)
    print(f'  {len(docs)} 件の投稿を取得')

    xml = build_sitemap(docs)
    with open(SITEMAP_OUT, 'w', encoding='utf-8') as f:
        f.write(xml)
    print(f'sitemap.xml を生成しました ({len(docs) + len(STATIC_URLS)} URL)')
