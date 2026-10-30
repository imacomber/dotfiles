## User Preferences

<!-- deepagents:onboarding-name:start -->
- The user's preferred name is "Ian".
<!-- deepagents:onboarding-name:end -->

## Triage integration reliability

- Ian has observed agents silently bypass failed/expired authentication and produce under-informed triage reports when integration checks are optional. Preserve mandatory lightweight integration health checks and explicit user-controlled degraded-mode approval; do not recommend making checks optional merely to save work. Distinguish tool readiness from whether deeper investigation is relevant, and surface authentication failures encountered after a successful preflight rather than silently dropping the source.

## Workspace triage context

- A Workspace page flash does not prove an unhandled Rails exception: inspect the failed request's HTTP status and response body first. Production-only failures with no Sentry exception may be edge-security blocks.
- WORKSPACE-1DF investigation: Ian confirmed the affected user used Trix, not Lexxy; verify incident-time feature flags rather than inferring the editor from installed dependencies. Ian reproduced ad-tag submission failure in production but not locally; the chat_blocks POST returned HTTP 403 with a Cloudflare 'Sorry, you have been blocked' page. Cloudflare blocking is confirmed for that reproduction; the exact rule/XSS trigger and retrospective linkage to the July 16 incident require security-event verification. Do not disable XSS protections globally; identify the matched rule before recommending a narrowly scoped exception.
