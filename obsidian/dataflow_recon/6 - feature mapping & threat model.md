#checkpoint #phase 

document for each feature:
	endpoint hit (URL, method, params)
	role required (anon / user / admin / tenant-admin)
	response shape (IDs returned, sensitive fields)
	state changes (DB write? email? webhook? S3 write?)

map the application's authz model
	auth model: cookie, JWT, OAuth, mTLS, API key?
	multi-tenancy model: header-based, subdomain-based, path-based?
	RBAC roles: enumerate every role observable in the UI
	ID formats: numeric? UUIDv4? UUIDv1 (timestamp leak)? slugs? KSUID? short tokens?
	"points where the app says no" — every 403/401/permission-denied is a candidate for BAC testing

invite / share / billing / export functions are where SaaS BAC bugs cluster

JXScout output -> Claude Code (via Caido Skill)
	point Claude Code at `~/.jxscout/<target>/`
	prompt: enumerate every fetch/axios/XHR call. for each, infer method + path + role hint based on visible permission checks + identifier shape. flag UUID/numeric ID parameters with no visible role check. flag any url= / target= / webhook= parameter
	feed this list back into the BAC matrix in phase 7

threat model question: what is the worst that could happen to this org?
	the answer redirects phase 7 effort. for a banking app -> account funds. for a SaaS -> cross-tenant data. for a marketplace -> seller impersonation. for a healthcare app -> PHI access

-- output:
	[[feature_map.md]]
	[[threat_model.md]]
	endpoint inventory annotated with role hints

next phase -> [[7 - BAC IDOR assessment]]
