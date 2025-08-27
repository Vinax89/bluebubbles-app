# Project Thrive (ChatPay v6.1.0) — Patch Bundle

This bundle implements the recommendations we discussed:

1. **`.env.example`** — copy to `.env` and fill values.
2. **Server upgrades** (drop-in):
   - `server/index.js`: JSON persistence, `/api/healthz`, tightened CORS (prod), generic CRUD for `budgets`, `debts`, `goals`, `obligations`, `bnpl`, JWT auth.
   - `server/persistence.js`: atomic JSON writes to `DATA_DIR` (default `./data`).
   - `server/utils/jwt.js`: JWT helpers.
3. **Docker**:
   - `docker/Dockerfile.client` (build Vite → serve with nginx)
   - `docker/Dockerfile.server` (Express API)
   - `docker-compose.yml` (one command to run both)
4. **CI**: `.github/workflows/ci.yml` — lint, typecheck, unit tests, build; Playwright E2E job.
5. **E2E**: `playwright.config.ts`, `tests/smoke.spec.ts`
6. **Health banner**:
   - `src/hooks/useApiHealth.ts`
   - `src/components/system/ApiStatusBanner.tsx`
   - Add `<ApiStatusBanner />` near the top of your `App` component to inform users when the API is down.
7. **Math tests**: `src/logic/__tests__/debtMath.test.ts`, `src/logic/__tests__/bnplSchedule.test.ts`
8. **Package patch**: `package.scripts.patch.json` — merge `scripts`/`devDependencies` into your existing `package.json` (do not replace entirely).

## Apply guide

1. **Copy files** into your repo, preserving paths.
2. `cp .env.example .env` and tweak values.
3. Install Playwright dev dependency (if you don't already have it):
   ```bash
   npm i -D @playwright/test
   npx playwright install --with-deps
   ```
4. Update `package.json` by merging the `scripts` and `devDependencies` from `package.scripts.patch.json`.
5. Start server and client locally:
   ```bash
   # server
   cd server
   npm install
   npm start
   # client (root)
   npm run dev
   ```
6. **Docker (optional)**
   ```bash
   docker compose up --build
   ```

## Add the banner to your UI
In your `App.tsx` (or top-level layout), add:
```tsx
import ApiStatusBanner from './components/system/ApiStatusBanner';

export default function App() {
  return (
    <>
      <ApiStatusBanner />
      {/* rest of your app */}
    </>
  );
}
```

That’s it. You now have persistence, health checks, CI/E2E, Docker, and an offline indicator.
