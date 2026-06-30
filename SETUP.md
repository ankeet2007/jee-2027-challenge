# How to Get Your JEE 2027 App APK

## Step 1 — Create a free GitHub account
Go to: https://github.com/signup
Use any email, create a free account.

## Step 2 — Create a new repository
1. After login, click the "+" button (top right) → "New repository"
2. Name it: jee-2027-challenge
3. Set it to "Public"
4. Do NOT check "Add README"
5. Click "Create repository"
6. COPY the repository URL shown (looks like: https://github.com/YOURNAME/jee-2027-challenge.git)

## Step 3 — Run these commands in Termux (one by one)

cd "/mnt/sdcard/180 DAYS CHALLENGE APP"

git init
git add lib/ pubspec.yaml .github/ .gitignore
git commit -m "Initial JEE 2027 Challenge app"
git branch -M main
git remote add origin PASTE_YOUR_REPO_URL_HERE
git push -u origin main

(Replace PASTE_YOUR_REPO_URL_HERE with the URL you copied in Step 2)

## Step 4 — Wait ~5 minutes for the APK to build
1. Go to your GitHub repository in the browser
2. Click "Actions" tab
3. You'll see "Build Android APK" running
4. Wait for it to turn green ✓
5. Click on it → scroll down → click "JEE-2027-Challenge-APK" to download

## Step 5 — Install the APK
1. Open the downloaded APK file
2. Android will ask "Allow installation from unknown sources" → Allow
3. Install it
4. Done! The app appears in your app drawer like any normal app.

## To update the app later
After making changes, just run:
  git add lib/ pubspec.yaml
  git commit -m "Update"
  git push

The APK will rebuild automatically in ~5 minutes.
