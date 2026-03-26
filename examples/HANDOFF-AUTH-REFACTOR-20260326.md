# Handoff: Auth Middleware Refactor
**Date**: 2026-03-26
**Session**: Migrated auth from Express middleware to Next.js 16 proxy.ts
**Project**: acme-app (`~/Projects/acme-app/`)

## What Was Done
- Created `proxy.ts` at project root with Clerk middleware integration
- Migrated auth logic from `src/middleware/auth.ts` (deleted) to `proxy.ts`
- Updated 12 route handlers in `app/api/` to use new `auth()` async helper
- Added integration test in `tests/auth.test.ts` covering sign-in, sign-out, and role-based access

## Current State
- Auth working on all routes except `/api/webhooks/*`
- Webhook routes need CSRF exemption — Clerk docs unclear on proxy.ts pattern
- All existing tests pass (`npm test` — 47/47)
- Preview deployment live at `acme-app-git-auth-refactor.vercel.app`

## What's Next
1. Add CSRF exemption for webhook routes in `proxy.ts` line 23
2. Run full E2E suite: `npm run test:e2e`
3. Deploy to production: `vercel --prod`

## Key Decisions
- proxy.ts over middleware.ts: Next.js 16 renames middleware.ts to proxy.ts, gains full Node.js runtime (needed for Clerk SDK calls)
- Kept rate limiting in separate `lib/rate-limit.ts` rather than embedding in proxy: separation of concerns, rate limiting may move to Vercel WAF later

## Constraints & Gotchas
- Clerk middleware must be called before `auth()` works in Server Components — if proxy.ts is bypassed, you get: `Clerk: auth() was called without Clerk middleware`
- Webhook signature verification requires raw body — `app/api/webhooks/stripe/route.ts` uses `export const runtime = 'nodejs'` and reads `req.text()` before JSON parse
- NEXT_PUBLIC_CLERK_SIGN_IN_URL and SIGN_UP_URL are set manually (not auto-provisioned by Clerk integration)

## Files Modified This Session
- `proxy.ts`: New file — auth middleware entry point (31 lines)
- `src/middleware/auth.ts`: Deleted
- `app/api/webhooks/stripe/route.ts`: Updated body parsing for raw access
- `tests/auth.test.ts`: New — 4 test cases
- `package.json`: Added `@clerk/nextjs@^6.2.0`
