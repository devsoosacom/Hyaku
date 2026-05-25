"""
百物語 サイトマップ自動更新スクリプト
Firestore の全投稿を取得して sitemap.xml を生成し Firebase Hosting にデプロイする。
auto_post.py から呼び出されるほか、単独でも実行可能。
"""
import sys
import json
import os
import subprocess
import urllib.request
from datetime import datetime

sys.stdout.reconfigure(encoding='utf-8')

API_KEY      = 'AIzaSyAB_OLK_K5pLIbOkHAztd5k5-NYi7nJth0'
PROJECT_ID   = 'hyaku-35692'
ADMIN_EMAIL  = 'admin@hyaku.jp'
ADMIN_PASS   = 'Hyaku@2025!'
BASE_URL     = 'https://hyaku-35692.web.app'
# ソース（flutter build で上書きされても残る）
SITEMAP_SRC  = r'O:\Hyaku\app\web\sitemap.xml'
# ビルド済み（Hosting にデプロイされる実体）
SITEMAP_OUT  = r'O:\Hyaku\app\build\web\sitemap.xml'
NODE_EXE     = r'C:\Program Files\nodejs\node.exe'
FIREBASE_JS  = r'O:\Program Files (x86)\Nodist\bin\node_modules\firebase-tools\lib\bin\firebase.js'
LOG_FILE     = r'O:\Hyaku\update_sitemap.log'


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


def fetch_all_posts(id_token):
    posts = []
    page_token = None
    while True:
        url = (f'https://firestore.googleapis.com/v1/projects/{PROJECT_ID}'
               f'/databases/(default)/documents/posts?pageSize=300')
        if page_token:
            url += f'&pageToken={page_token}'
        req = urllib.request.Request(url, headers={'Authorization': f'Bearer {id_token}'})
        with urllib.request.urlopen(req) as r:
            data = json.loads(r.read())
        for doc in data.get('documents', []):
            fields = doc.get('fields', {})
            doc_id = doc['name'].split('/')[-1]
            created_raw = fields.get('createdAt', {}).get('timestampValue', '')
            if created_raw:
                try:
                    created = datetime.fromisoformat(created_raw.replace('Z', '+00:00'))
                    lastmod = created.strftime('%Y-%m-%d')
                except ValueError:
                    lastmod = datetime.now().strftime('%Y-%m-%d')
            else:
                lastmod = datetime.now().strftime('%Y-%m-%d')
            posts.append({'id': doc_id, 'lastmod': lastmod})
        page_token = data.get('nextPageToken')
        if not page_token:
            break
    return posts


def generate_sitemap(posts):
    today = datetime.now().strftime('%Y-%m-%d')
    lines = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">',
        '  <url>',
        f'    <loc>{BASE_URL}/</loc>',
        f'    <lastmod>{today}</lastmod>',
        '    <changefreq>daily</changefreq>',
        '    <priority>1.0</priority>',
        '  </url>',
        '  <url>',
        f'    <loc>{BASE_URL}/feed</loc>',
        f'    <lastmod>{today}</lastmod>',
        '    <changefreq>daily</changefreq>',
        '    <priority>0.9</priority>',
        '  </url>',
        '  <url>',
        f'    <loc>{BASE_URL}/search</loc>',
        f'    <lastmod>{today}</lastmod>',
        '    <changefreq>weekly</changefreq>',
        '    <priority>0.7</priority>',
        '  </url>',
    ]
    for post in sorted(posts, key=lambda p: p['lastmod'], reverse=True):
        lines += [
            '  <url>',
            f'    <loc>{BASE_URL}/post/{post["id"]}</loc>',
            f'    <lastmod>{post["lastmod"]}</lastmod>',
            '    <changefreq>monthly</changefreq>',
            '    <priority>0.6</priority>',
            '  </url>',
        ]
    lines.append('</urlset>')
    return '\n'.join(lines)


def deploy_hosting():
    result = subprocess.run(
        [NODE_EXE, FIREBASE_JS, 'deploy', '--only', 'hosting'],
        cwd=r'O:\Hyaku',
        capture_output=True,
        timeout=120,
    )
    output = result.stdout.decode('utf-8', errors='replace') + result.stderr.decode('utf-8', errors='replace')
    if result.returncode == 0:
        log('Firebase Hosting デプロイ成功')
    else:
        log(f'デプロイ失敗 (code={result.returncode}): {output[-300:]}')


def main():
    log('=== サイトマップ更新 開始 ===')

    id_token = sign_in()
    posts = fetch_all_posts(id_token)
    log(f'投稿取得: {len(posts)}件')

    sitemap = generate_sitemap(posts)

    # ソースと build 両方に書く
    for path in [SITEMAP_SRC, SITEMAP_OUT]:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(sitemap)
    log(f'sitemap.xml 書き込み完了 (投稿 {len(posts)}件)')

    deploy_hosting()
    log('=== サイトマップ更新 完了 ===')


if __name__ == '__main__':
    main()
