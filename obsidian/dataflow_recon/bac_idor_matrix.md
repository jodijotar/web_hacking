#reference

apply this matrix to every authenticated request observed in phase 6. each row is a single test mutation

| # | mutation | what it tests |
|---|---|---|
| 1  | replay with userB's cookie/token | horizontal IDOR |
| 2  | replay with no auth header | broken auth (endpoint forgot to check) |
| 3  | swap HTTP verb GET<->POST<->PUT<->DELETE<->PATCH | verb tampering (allowlist-by-verb) |
| 4  | add header `X-HTTP-Method-Override: PUT` | filter bypass via override |
| 5  | HEAD request against admin endpoint | HEAD often skips body-reading auth filters |
| 6  | `?id=1&id=2` and `id[]=1&id[]=2` | HTTP parameter pollution |
| 7  | add `isAdmin=true`, `role=admin`, `verified=true`, `tenant_id=X`, `permissions[]=*`, `is_staff=true` to body | mass assignment |
| 8  | swap UUID with one leaked from gau / referrer / OAuth / GitHub / screenshots | direct UUID IDOR |
| 9  | UUIDv1 check (3rd group starts with `1`) -> sandwich attack | timestamp-based UUID prediction |
| 10 | sequential numeric ID ±10000 / step probe | enumeration / IDOR via predictable IDs |
| 11 | swap `/me/` -> `/<USERID>/` | secondary context bypass (Sam Curry Starbucks pattern) |
| 12 | swap `X-Tenant-ID` / `X-Org-ID` / `X-Account-ID` headers | cross-tenant IDOR |
| 13 | nested-JSON ID mismatch: outer eventID checked, inner not | Codii pattern (mass ATO via stored XSS) |
| 14 | GraphQL: `node(id:"...")` and `nodes(ids:[...])` direct hit | GraphQL root-field bypass of REST authz |
| 15 | GraphQL aliases for rate-limit bypass: `q1:user(id:1) q2:user(id:2) ... q100:user(id:100)` | enumeration via aliases |
| 16 | append `.json`, `.csv`, `.xml`, `;.css`, `/..%2f` to URL | path-extension parser confusion / cache deception entry |
| 17 | path traversal in IDs: `?id=../admin` | path-style IDOR |
| 18 | downgrade Bearer -> remove signature, change `alg` | JWT auth bypass (covered in JWT pipeline) |
| 19 | replay across tenants: userA-tenant1 token against userC-tenant2 resource | multi-tenant boundary failure |
| 20 | check API versioning: `/api/v1/` when current is `/api/v3/` | old version with weaker authz |

priority order
	rows 1, 2, 8, 11, 12, 13 are the highest-yield on modern SaaS targets — start there
	rows 7, 14, 15 are the GraphQL/mass-assignment edges where modern frameworks still fail
	rows 9, 10 only relevant when ID format observation in phase 6 indicates predictability

UUIDv1 sandwich attack
	if observed token = `7c89e9c2-XXXX-1XXX-XXXX-XXXXXXXXXXXX` (3rd group starts with `1`):
		trigger token generation (e.g. password reset on attacker account) immediately before and after victim's action
		decode timestamps from your two known tokens -> defines time window for victim's
		decode node MAC (last group) -> same across all UUIDs from same server
		brute the clock_seq + 100ns ticks between your sandwich tokens
	tooling: `Cyberretta/UUIDv1_Timestamps_Generator`

invite/share-specific tests (Douglas Day discipline)
	invite an already-existing user -> does response leak whether email exists?
	invite -> is invitee auto-added without consent?
	modify invite payload (`role: admin` instead of `role: viewer`)
	expired invite reuse
	invite to a tenant you don't belong to (lookup by ID)

secondary context attacks (Sam Curry Starbucks pattern)
	when app exposes a reverse-proxy endpoint (`/bff/proxy/`, `/api/gateway/`, `/internal-proxy/`):
		try traversal to reach internal services
		`/bff/proxy/../../microsoft-graph/...`
		every reverse proxy is a potential SSRF + secondary context IDOR target
