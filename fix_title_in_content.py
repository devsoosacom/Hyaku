"""
Firestoreの全投稿から本文先頭の「# タイトル」行を除去するスクリプト
"""
import sys, json, re, urllib.request
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

def patch_content(token, doc_name, content):
    url = f'https://firestore.googleapis.com/v1/{doc_name}?updateMask.fieldPaths=content'
    body = json.dumps({'fields': {'content': {'stringValue': content}}}).encode()
    req = urllib.request.Request(url, data=body, method='PATCH', headers={
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json',
    })
    with urllib.request.urlopen(req) as r:
        r.read()

def clean_content(content):
    lines = content.split('\n')
    # 先頭から # で始まる行と空行を除去
    while lines and (lines[0].startswith('#') or lines[0].strip() == ''):
        lines.pop(0)
    return '\n'.join(lines).strip()

def main():
    print('サインイン中...')
    token = sign_in()
    posts = get_all_posts(token)
    print(f'{len(posts)}件取得')

    fixed = 0
    for doc in posts:
        fields = doc.get('fields', {})
        title   = fields.get('title', {}).get('stringValue', '')
        content = fields.get('content', {}).get('stringValue', '')

        new_content = clean_content(content)
        if new_content != content:
            patch_content(token, doc['name'], new_content)
            print(f'  修正: {title}')
            fixed += 1

    print(f'\n完了: {fixed}件修正')

if __name__ == '__main__':
    main()
