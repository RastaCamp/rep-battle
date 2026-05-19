# Rep Battle — Cloudflare Pages (web)

Flutter web build deployed to **https://repbattle.rastacamp.com** (no backend; runs fully in the browser).

## Build & deploy

```bash
flutter pub get
npm install
npm run deploy
```

## GitHub auto-deploy

Repo: **RastaCamp/rep-battle**

| Setting | Value |
|--------|--------|
| Build command | `flutter pub get && npm run build` |
| Build output directory | `build/web` |
| Flutter | Install via CI (see Cloudflare build image or use GitHub Actions) |

Cloudflare’s default build image may not include Flutter. Options:

1. **GitHub Actions** builds `build/web`, then `wrangler pages deploy` on push
2. **Pre-built deploy** from your PC: `npm run deploy` after `flutter build web`
3. Add a **`.github/workflows/deploy-pages.yml`** (recommended)

Custom domain: Pages → rep-battle → `repbattle.rastacamp.com`
