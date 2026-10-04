# AKOSH Social

This is a ready-to-deploy AKOSH social network starter.

## What is included
- Premium responsive AKOSH UI
- Login/signup screen
- Home feed
- Stories UI
- Reels UI
- Explore grid
- Create post UI
- Profile UI
- Messages UI
- Supabase integration hook
- Supabase SQL starter schema + RLS
- Vercel-ready static deployment

## 1. Connect Supabase
Open `config.js` and replace:
SUPABASE_URL
SUPABASE_KEY

Use your Supabase Project URL and Publishable key only. Never put a secret/service_role key in the browser.

## 2. Database
Open Supabase Dashboard -> SQL Editor.
Paste `supabase.sql` and run it.

Then create Storage buckets:
avatars
posts
reels
stories
messages

For a fully production-ready media system, add Storage RLS policies appropriate to your privacy requirements.

## 3. Run locally
Because this is a static site, you can simply open `index.html` in a browser for the UI demo.

For a local server, use any static server, for example:
`npx serve .`

## 4. Publish to everyone
Upload this folder to a GitHub repository, then import the repository into Vercel.
No build command is needed for the static version; the project can be served as static files.

## Important
The included UI is functional as a frontend/demo. Real cross-user posts, media uploads, Stories, Reels, follows, comments and realtime DMs require completing the Supabase queries/storage policies in the frontend. This starter intentionally does not contain any secret keys.
