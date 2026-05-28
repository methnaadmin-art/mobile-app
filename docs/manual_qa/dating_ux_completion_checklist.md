# Dating UX Completion Manual QA

Use this checklist after any release candidate that touches swiping, matches, chats, notifications, or account settings.

## 1) Swipe -> Match Flow

- Like a user from Home and verify the next profile appears immediately with no loading gap.
- Pass a user from Home and verify the next profile appears immediately with no loading gap.
- Trigger a mutual match from a swipe response and verify the full-screen match splash appears.
- Confirm tapping `Keep Swiping` returns to Home with no grey/blank screen.
- Confirm tapping `Send Message` opens the correct conversation with the matched user's name and photo already hydrated.

## 2) In-App Mutual Match Popup

- Keep the app open on Home, then trigger a mutual match from a swipe response.
- Keep the app open and trigger the same mutual match again from a real-time/socket event.
- Open the Matches tab and refresh after the same mutual match has already been shown.
- Verify the match splash appears only once for that match across all three sources.
- Trigger a different mutual match and verify a new splash appears for the new match.

## 3) Matches Tabs Accuracy

- Open `Liked By Me` and verify it shows users the current user liked.
- Open `Liked Me` and verify it shows users who liked the current user.
- Open `Passed` and verify it shows skipped users.
- Open `Matches` and verify it shows only mutual matches.
- Like a user and verify `Liked By Me` updates immediately.
- Pass a user and verify `Passed` updates immediately.
- Convert a `Liked Me` user into a match and verify they are removed from `Liked Me` and added to `Matches`.
- Unmatch a user and verify they disappear immediately from `Matches`, `Liked Me`, and chats.
- Block a user and verify they disappear from all four tabs without restarting the app.
- Verify each tab shows the correct empty state when it has no users.

## 4) Notifications Routing

- While the app is in the foreground, tap a match notification and verify it opens the matched user's profile.
- While the app is in the foreground, tap a message notification and verify it opens the target conversation.
- Repeat both tests with the app in the background.
- Repeat both tests from a killed/cold-start launch.
- Verify malformed or incomplete notification payloads fall back safely to the notifications list instead of crashing.

## 5) Delete Account

- Open Settings and verify `Delete Account` is visible.
- Start the delete flow and verify the first confirmation dialog appears.
- Confirm again and verify a loading state appears while the request runs.
- On success, verify the app logs out, clears local session/state, and returns to login.
- Sign back in with a different account and verify old chats, matches, and cached user data are not still visible.
- If the delete API fails, verify the user stays signed in and local data is not partially cleared.

## 6) Matched Profile Full View

- Open a matched user from the `Matches` tab.
- Verify the full profile screen opens, not the small grid/card shell.
- Verify all profile images are visible through the gallery/carousel.
- Verify the large-image presentation is used.
- Verify the available actions are `Chat` and destructive `Unmatch`.

## 7) Bottom Navigation Visual Check

- Open Home and confirm the bottom navigation bar no longer shows the heavy drop shadow under it.
- Verify the nav still keeps its blur, border, active state, and tap behavior.
