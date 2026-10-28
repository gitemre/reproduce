# API fetch

## When to use

Use the API when there is no browser tool, the run is headless or in CI, the page hides or truncates the
event, or the user asks. The browser path ([browser-fetch.md](browser-fetch.md)) is preferred. Read tokens
from the environment only; never ask for one in chat, echo it, put it in a URL, or write it to `raw/`.

Every request is a read: `GET` only. Never POST, PATCH, PUT or DELETE, and never resolve, assign, share,
delete or edit the issue. Save bodies verbatim under `raw/`; the reader interprets the crash, not this
step. Use `curl -sS --fail-with-body` or the agent's HTTP tool; never `curl -v` (it prints the
`Authorization` header).

## Crashlytics

A console link is
`https://console.firebase.google.com/project/$PROJECT/crashlytics/app/$PLATFORM:$APP_ID/issues/$ISSUE_ID`;
it may add `?sessionEventKey=<event_id>` or an `events/<event_id>` segment. The path's project id is the
Firebase project id, not the project number the API uses.

1. Get an access token without printing it:

   ```bash
   TOKEN="${REPRODUCE_GOOGLE_TOKEN:-${GOOGLE_OAUTH_ACCESS_TOKEN:-$(gcloud auth print-access-token)}}"
   ```

   If `gcloud` has no active account, ask the user to run `gcloud auth login` (or
   `gcloud auth application-default login`) in their terminal; never ask for a password or token.

2. Find the Firebase app id: `mobilesdk_app_id` in `google-services.json`, or `GOOGLE_APP_ID` in
   `GoogleService-Info.plist`. Otherwise list the project's apps:

   ```bash
   KIND=androidApps   # iosApps for an iOS app
   curl -sS --fail-with-body -H "Authorization: Bearer $TOKEN" -H "x-goog-user-project: $PROJECT" \
     "https://firebase.googleapis.com/v1beta1/projects/$PROJECT/$KIND?pageSize=100"
   ```

   Match `packageName` for `androidApps`, `bundleId` for `iosApps`. The entry's `appId`
   (`1:<projectNumber>:android:<hash>`) is the id the Crashlytics API wants; keep its project number. Read
   every page (`nextPageToken`) before deciding the app is absent.

3. Set the API base and app resource; send both headers on every call:

   ```bash
   API="https://firebasecrashlytics.googleapis.com/v1alpha"
   APP="$API/projects/$PROJECT_NUMBER/apps/$FIREBASE_APP_ID"
   ```

4. Read the issue:

   ```bash
   curl -sS --fail-with-body -H "Authorization: Bearer $TOKEN" -H "x-goog-user-project: $PROJECT" \
     "$APP/issues/$ISSUE_ID" > raw/issue.json
   ```

5. Read one event by id:

   ```bash
   curl -sS --fail-with-body --get -H "Authorization: Bearer $TOKEN" -H "x-goog-user-project: $PROJECT" \
     --data-urlencode "names=projects/$PROJECT_NUMBER/apps/$FIREBASE_APP_ID/events/$EVENT_ID" \
     "$APP/events:batchGet" > raw/event.json
   ```

   The body is `{"events":[...]}`; the event is its first element. A console `sessionEventKey` may be
   `<key>_<suffix>`; if the full key returns no event, try the part before the underscore. Keep the whole
   event, not only `exceptions`.

6. Read the issue's events:

   ```bash
   curl -sS --fail-with-body --get -H "Authorization: Bearer $TOKEN" -H "x-goog-user-project: $PROJECT" \
     --data-urlencode "filter.issue.id=$ISSUE_ID" \
     --data-urlencode "filter.interval.start_time=$START" \
     --data-urlencode "filter.interval.end_time=$END" \
     --data-urlencode "page_size=100" \
     "$APP/events" > raw/issue-events.json
   ```

   Use an interval of at most 90 days (89 days back is safe; the default is 7). `page_size` is at most
   100; follow `page_token=<nextPageToken>` only while needed, and stop at 100 (record the truncation).
   The list is normally newest first, but select the maximum `eventTime`. An issue link with no event id
   needs at least the newest page.

## Sentry

A link is `https://acme.sentry.io/issues/123/` (or `https://sentry.io/organizations/acme/issues/123/`),
optionally with an `events/<event_id>` segment. A self-hosted base keeps its scheme, host and any path
before `organizations` or `issues`.

1. Set the token; it needs `event:read`:

   ```bash
   SENTRY_TOKEN="${SENTRY_AUTH_TOKEN:?set SENTRY_AUTH_TOKEN to a token with event:read}"
   BASE="https://acme.sentry.io"
   ORG="acme"
   ISSUE="123"
   ```

   Never print it. Send `-H "Authorization: Bearer $SENTRY_TOKEN"` on every call.

2. Read the issue:

   ```bash
   curl -sS --fail-with-body -H "Authorization: Bearer $SENTRY_TOKEN" \
     "$BASE/api/0/organizations/$ORG/issues/$ISSUE/" > raw/issue.json
   ```

3. Read one event, or the latest when the link names none:

   ```bash
   curl -sS --fail-with-body -H "Authorization: Bearer $SENTRY_TOKEN" \
     "$BASE/api/0/organizations/$ORG/issues/$ISSUE/events/$EVENT_ID/" > raw/event.json
   ```

   Use `latest` as `$EVENT_ID` when the link names no event. Sentry also accepts `recommended`; if the
   `recommended` request returns 404, try `latest` once. A link that names an id which returns 404 is
   unknown: stop with an empty `event_id` and a reason.

4. List the issue's events:

   ```bash
   curl -sS --fail-with-body -H "Authorization: Bearer $SENTRY_TOKEN" \
     "$BASE/api/0/organizations/$ORG/issues/$ISSUE/events/?full=true" > raw/issue-events.json
   ```

   Follow a `Link` header with `rel="next"` only to the same host; stop at 100 events. Select the newest
   `dateCreated` (then `dateReceived`), not the first array entry. `full=true` includes stacks.

5. 401/403 means the token or scope is wrong; 404 means the org, issue or event id is wrong.

## Mozilla crash-stats

crash-stats is public and needs no token. A report link is
`https://crash-stats.mozilla.org/report/index/<crash_id>`; a Bugzilla/about:crashes id may be
`bp-<crash_id>`.

```bash
curl -sS --fail-with-body \
  "https://crash-stats.mozilla.org/api/ProcessedCrash/?crash_id=$CRASH_ID" > raw/event.json
```

`ProcessedCrash` is the processed report (stack, threads, modules, environment). A 404 means the id is
wrong or the report expired. A 429 carries `Retry-After`; wait that long once (at most 60 seconds) and
retry once, else stop and say the service is rate-limiting. The crash id is the event id.

## Tokens

- Crashlytics: `REPRODUCE_GOOGLE_TOKEN`, else `GOOGLE_OAUTH_ACCESS_TOKEN`, else the output of
  `gcloud auth print-access-token`.
- Sentry: `SENTRY_AUTH_TOKEN` with `event:read`.
- crash-stats: none.

Never ask for a password or token in chat, print one, write one to `raw/` or `source.json`, or put one in
a query string. If missing, name the environment variable and stop; use the browser or an exported event.

## Issue links

Apply the selection rule before writing anything:

- The link names an event (Crashlytics `sessionEventKey` or an `events/<id>` segment; Sentry
  `events/<id>`) and the service returns it: `selected: named`.
- The link names no event: select the event with the newest service time, `selected: latest`.
- The link names an event the service does not return: stop with `event_id: ""`, `selected: none`, and a
  reason that includes the id. Never silently pick the latest event.
- The issue has no events, or none has a time: stop the same way.

For an issue link, save the issue and up to 100 events plus the selected event; the list is not the
target. Keep the whole selected event (threads, breadcrumbs, logs, keys, tags, contexts, device/app, issue
block). Do not edit it.

## Write raw/

Create `raw/` and write:

- `raw/event.json`: the selected event exactly as returned (verbatim bytes, no reformatting or truncation).
- `raw/issue.json`: the issue resource, when the service has one.
- `raw/issue-events.json`: the issue's events, when read (at most 100).
- `raw/source.json`: the selection record below.

### source.json

One UTF-8 JSON object; extra keys are allowed, these are required:

| Field | Type | Notes |
|---|---|---|
| `url` | string | the link as given; empty only when `transport` is `paste` |
| `service` | string | `crashlytics`, `sentry` or `crash-stats` |
| `project` | string | Firebase project id; Sentry project slug/id or crash-stats product when known; else empty |
| `app_id` | string | package name or bundle id; empty when the service does not name it |
| `issue_id` | string | issue/group id; empty for crash-stats or when `transport` is `paste` |
| `event_id` | string | the selected event's service id; empty when none was selected |
| `selected` | string | `named`, `latest` or `none` |
| `reason` | string | one non-empty line: the link named the event, the latest event by time, or why nothing was selected |
| `transport` | string | `browser`, `api`, `saved-json` or `paste` |
| `fetched_at` | string | RFC 3339 UTC, e.g. `2026-10-27T16:29:52Z` |

`event_id` is the service's own id (`eventId` / `eventID`), not prose. A `none` selection leaves it empty
and still records the issue id and reason.

## Failure modes

- Missing token or app id: say which, stop, and use the browser or a pasted/exported event.
- 401/403: the token is invalid, lacks the scope/role, or the API is disabled; say which and stop.
- 404: the project, app, issue or event id is wrong; a named event that 404s is unknown, not a reason to
  pick another.
- 429: wait once as the service asks, then stop.
- Network or sandbox refusal: stop and tell the user; never retry outside the sandbox without their yes.
- Truncated or hidden response: use the JSON/export view or the API; if neither shows the whole event,
  record what is missing and ask for an export. Never substitute a repository fixture.
- This step writes `raw/` and `raw/source.json` only; never `crash.json`, `analysis.json` or a verdict.
