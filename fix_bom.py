"""
Firestoreの全投稿からBOM文字を除去するスクリプト
"""
import sys, json, urllib.request
sys.stdout.reconfigure(encoding='utf-8')

API_KEY    = 'AIzaSyAB_OLK_K5pLIbOkHAztd5k5-NYi7nJth0'
PROJECT_ID = 'hyaku-35692'
ADMIN_EMAIL = 'admin@hyaku.jp'
ADMIN_PASS  = 'Hyaku@2025!'

def sign_in():
    url = f'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={API_KEY}'
    body = json.dumps({'email': ADMIN_EMAIL, 'password': ADMIN_PASS, 'returnSecureToken': True}).encode()
    req = urllib.request.Request(url, data=body, headers={'Content-Type': 'application/json'})
    with urllib.request.urlopen(req) as r:
        return json.loads(r.read())['idToken']

def get_all_posts(token):
    posts, next_token = [], None
    while True:
        url = f'https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents/posts?pageSize=300'
        if next_token:
            url += f'&pageToken={next_token}'
        req = urllib.request.Request(url, headers={'Authorization': f'Bearer {token}'})
        with urllib.request.urlopen(req) as r:
            data = json.loads(r.read())
        posts.extend(data.get('documents', []))
        next_token = data.get('nextPageToken')
        if not next_token:
            break
    return posts

def fix_bom(token, doc_name, title, content):
    url = f'https://firestore.googleapis.com/v1/{doc_name}?updateMask.fieldPaths=content&updateMask.fieldPaths=title'
    body = json.dumps({'fields': {
        'title':   {'stringValue': title},
        'content': {'stringValue': content},
    }}).encode()
    req = urllib.request.Request(url, data=body, method='PATCH', headers={
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json',
    })
    with urllib.request.urlopen(req) as r:
        r.read()

def main():
    print('サインイン中...')
    token = sign_in()
    posts = get_all_posts(token)
    print(f'{len(posts)}件取得')

    fixed = 0
    for doc in posts:
        fields = doc.get('fields', {})
        title   = fields.get('title',   {}).get('stringValue', '')
        content = fields.get('content', {}).get('stringValue', '')

        new_title   = title.lstrip('﻿').strip()
        new_content = content.lstrip('﻿').strip()

        if new_title != title or new_content != content:
            fix_bom(token, doc['name'], new_title, new_content)
            print(f'  修正: {new_title}')
            fixed += 1

    print(f'\n完了: {fixed}件修正しました')

if __name__ == '__main__':
    main()
