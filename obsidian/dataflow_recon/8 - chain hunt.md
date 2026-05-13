#phase

NEW PHASE. converts P3/P4 findings into P1/P2 by chaining. before reporting any finding, match against this catalog and hunt the chain partner

chain pattern catalog
	each entry: low-impact bug + chain partner -> elevated impact

subdomain takeover -> cookie scoping -> session hijack
	prereqs: subdomain in scope, cookie not host-only (`Domain=.target.com`)
	test: host JS on taken-over subdomain that reads document.cookie; victim visit -> SSO cookie exfil
	reference: HackerOne #219205 (Arne Swinnen / Uber)

open redirect -> OAuth token theft
	prereqs: missing/static `state`, OR weak redirect_uri validation, OR open redirect on whitelisted origin
	test: chain open redirect URL into OAuth `redirect_uri` value to leak token via Referer
	reference: HackerOne #202781 (Uber, $7,500)

self-stored XSS + IDOR -> account takeover (the case you flagged)
	prereqs: self-XSS in profile/template/note field, authenticated write endpoint accepts userId/email/templateId without ownership check
	test: write XSS payload, then via IDOR set victim's profile field to point at attacker payload, victim visits own profile -> ATO
	reference: HackerEarth (Jefferson Gonzales), Codii (Hackerearth profile-XSS sandwich)

CORS misconfig + sensitive endpoint -> data exfiltration
	prereqs: `Access-Control-Allow-Credentials: true` AND origin reflection/substring-match AND credentials-authenticated JSON endpoint
	test: malicious origin fetches `/api/me`, exfils response
	reference: HackerOne #426147 (X/niche.co)

SSRF -> cloud metadata -> AWS/GCP credentials -> IAM privesc
	prereqs: SSRF with arbitrary host (or DNS-rebind for SSRF behind allowlist)
	test: `169.254.169.254/latest/meta-data/iam/security-credentials/` (AWS IMDSv1, ~93% of EC2 in March 2025)
		for IMDSv2: requires controllable HTTP method (PUT) and header (`X-aws-ec2-metadata-token-ttl-seconds`)
		GCP: `metadata.google.internal/computeMetadata/v1/` with `Metadata-Flavor: Google`
		Azure: `169.254.169.254/metadata/instance?api-version=2021-02-01` with `Metadata: true`
	URL-parser bypass library when allowlist filters present: Orange Tsai's research
		`http://evil.com#@169.254.169.254/`, `http://169.254.169.254\@evil.com/`, decimal-encoded IPs (`2852039166`)

JWT misconfig -> privilege escalation
	prereqs: app doesn't pin algorithm; or reachable JWKS; or `kid` parameter goes to file/DB lookup
	test sequence: `alg:none` -> RS256→HS256 (sign HS256 with public key from /jwks.json) -> kid injection (path traversal, SQLi) -> jku/jwk injection

cache poisoning + auth/header reflection -> mass session theft
	prereqs: cacheable response, unkeyed input reflected (X-Forwarded-Host typically)
	test: `cachebuster=xxx` to scope poisoning; reflect attacker-controlled domain into JS src; all subsequent users get attacker payload
	reference: ladunca's 70+ cache-poisoning bugs ($40k bounty pool)

SSO/OAuth misconfig + IDOR -> cross-tenant ATO (nOAuth)
	prereqs: app uses "Sign in with Microsoft" and trusts unverified email claim
	test: create Microsoft Entra tenant, set user email to victim's address on vulnerable SaaS, sign in -> ATO
	reference: Descope nOAuth disclosure (June 2023, $75k bounty pool)

dependency confusion
	prereqs: internal package name discoverable in JS / package.json / errors, build system using default registry resolution
	test: publish higher-version public package with same name
	reference: Alex Birsan 2021 ($130k+ total Apple/Microsoft/PayPal)

HTTP request smuggling -> session theft
	tools: defparam/Smuggler, Burp HTTP Request Smuggler, Turbo Intruder smuggle mode
	reference: HackerOne #737140 (Slack), #771666 (Eternal/Zomato Akamai)

validator discipline
	for any AI-flagged finding (Claude Code, Shift, hai): re-run via curl-only with no attack-chain context before claiming. XBOW reached top of H1 leaderboard specifically by separating hunter and validator agents

decision rule
	if you have a finding and no chain partner candidate, document it as standalone (its native severity)
	if a chain pattern matches, hunt the partner before reporting. 1 P1 > 2 P3s in Bugcrowd payout terms AND avoids the triager splitting your chain

-- input:
	[[bac_findings.md]]
	[[nuclei_findings.txt]] (from 5.5)
	[[subzy_takeovers.txt]]
	[[cloud_enum_results.txt]]

-- output:
	[[chain_findings.md]]

next -> [[findings/]] -> Bugcrowd report
