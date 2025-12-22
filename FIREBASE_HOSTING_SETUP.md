# Firebase Hosting & Custom Domain Setup Guide

This guide will help you host your `app-ads.txt` file at `http://worbix.zenithsyntax.com/app-ads.txt`.

## Prerequisites
- You must own `zenithsyntax.com` (which you do).
- You must have access to your DNS provider (where you bought the domain, e.g., GoDaddy, Namecheap, Route53).

## Phase 1: Initialize Firebase in Project

Run these commands in your project terminal:

1.  **Install Firebase Tools** (if not installed):
    ```powershell
    npm install -g firebase-tools
    ```

2.  **Login to Google**:
    ```powershell
    firebase login
    ```

3.  **Initialize Hosting**:
    ```powershell
    firebase init hosting
    ```
    *   **Project Setup**: Select "Use an existing project" (Choose your Worbix firebase project).
    *   **Public Directory**: Type `build/web` (Important!).
    *   **Single Page App**: Type `No` (we are just hosting static files for now, or Yes if you want a full flutter web app, but `No` is safer for just app-ads.txt).
    *   **Automatic Builds**: `No`.

## Phase 2: Deploy the File

1.  **Build the Web Files**:
    This generates the `build/web` folder containing your `app-ads.txt`.
    ```powershell
    flutter build web --release
    ```
    *Note: This will verify `app-ads.txt` is copied to `build/web/app-ads.txt`.*

2.  **Deploy to Firebase**:
    ```powershell
    firebase deploy --only hosting
    ```

    At this point, your file is live at `https://your-project-id.web.app/app-ads.txt`.

## Phase 3: Connect Custom Domain (worbix.zenithsyntax.com)

1.  Open the [Firebase Console](https://console.firebase.google.com/).
2.  Select your project.
3.  Go to **Hosting** in the left sidebar.
4.  Click **Add Custom Domain**.
5.  Enter `worbix.zenithsyntax.com`.
6.  **Verification**:
    *   Firebase will give you a **TXT Record** or **CNAME Record**.
    *   **Copy** these values.

## Phase 4: Update DNS (The Technical Part)

Go to your Domain Registrar's website (where you manage `zenithsyntax.com`):

1.  Find **DNS Management** or **Name Server Settings**.
2.  **Add a New Record**:
    *   **Type**: `TXT` (if asked for verification) or `CNAME` (for the subdomain connection).
    *   **Host/Name**: `worbix` (This creates `worbix.zenithsyntax.com`).
    *   **Value/Target**: Paste the value from Firebase (usually looks like `firebase1.google.com` or a verification string).
    *   **TTL**: Leave as default (e.g., 3600 or Automatic).

3.  **Save**.

## Final Verification
1.  Wait 5-60 minutes for DNS to propagate.
2.  Visit `http://worbix.zenithsyntax.com/app-ads.txt` in your browser.
3.  If you see your ID (`google.com, pub-9698718721404755, DIRECT, f08c47fec0942fa0`), you are done!
4.  Adding the link to Play Console: Enter `http://worbix.zenithsyntax.com` as your website.
