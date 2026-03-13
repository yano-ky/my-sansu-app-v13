# 1. ソースコードの更新
Write-Host "--- 1/3: ソースコードをGitHub(main)にプッシュ中... ---" -ForegroundColor Cyan
git add .
git commit -m "Update: $(Get-Date -Format 'yyyy/MM/dd HH:mm:ss') の更新"
git push origin main

# 2. Web版のビルド
Write-Host "--- 2/3: Web版をビルド中... ---" -ForegroundColor Cyan
flutter build web --release --base-href "/my-sansu-app-v13/"

# 3. Web公開用ブランチへのプッシュ
Write-Host "--- 3/3: Web版をGitHub Pagesに公開中... ---" -ForegroundColor Cyan
cd build/web

# もしGitが初期化されていなければ初期化
if (!(Test-Path .git)) {
    git init
}

# 接続先(origin)が既にある場合は削除して登録し直す
git remote remove origin 2>$null
git remote add origin https://github.com/yano-ky/my-sansu-app-v13.git

git add .
git commit -m "Web deploy: $(Get-Date -Format 'yyyy/MM/dd HH:mm:ss')"
git branch -M main

# 強制上書きプッシュ
git push -f origin main:gh-pages

# 元の場所に移動
cd ../..

Write-Host "--- すべての更新が完了しました！ ---" -ForegroundColor Green
Pause