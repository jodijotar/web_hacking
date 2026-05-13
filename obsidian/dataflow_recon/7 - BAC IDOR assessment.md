#phase

NEW PHASE. the vulnerability assessment layer. recon ends, BAC testing begins here

pick ONE auth-differential tool based on app shape:
	Autorize (Burp) or Caido Autorize plugin
		fastest. binary admin-vs-user replay. best when you have 2 roles and want broad coverage
	AuthMatrix (Burp) / m4st3rspl1nt3r AuthMatrix port (Caido)
		matrix view. best when you have ≥3 roles and want explicit per-role per-endpoint results
	Auth Analyzer (Burp)
		cleanest UX for API-only Bearer-token apps with multi-tenant headers

JWT pipeline (when JWT is the auth method)
	JWT Editor (Burp/Caido) for manual inspection + re-signing
	`jwt_tool -t <url> -rh "Authorization: Bearer <jwt>" -M at` -> automated attack matrix
	test: alg:none, RS256->HS256 confusion, kid injection (path traversal, SQLi), jku/jwk injection, expired-token acceptance

SAML pipeline (only if SAML in scope)
	SAML Raider (Burp) -> 8 XSW variants out of the box
	test: signature wrapping, assertion replay without NotOnOrAfter, audience-restriction missing

mobile pipeline (when APK in scope)
	already harvested endpoints in phase 5 -> re-feed into the chosen auth-differential tool with each role token

OAuth fuzzing (when OAuth flow present)
	redirect_uri: path bypass (`/callback/../evil`), subdomain bypass (`.evil.com` if regex), open-redirect-on-whitelisted-origin chain
	state: missing/static -> login CSRF
	response_type switching (Frans Rosén Dirty Dancing)
	nOAuth pattern: if "Sign in with Microsoft" -> check whether app trusts unverified email claim

BAC/IDOR matrix — manually applied to every authenticated request:
	[[bac_idor_matrix.md]]

interactsh / Caido collaborator for blind detection on every SSRF candidate

-- input:
	[[feature_map.md]]
	auth_accounts (from phase 3.5)
	api_endpoints.txt + js_endpoints.txt
	tokens

-- output:
	[[bac_findings.md]]
	[[jwt_findings.md]]  (if applicable)
	[[saml_findings.md]] (if applicable)

next phase -> [[8 - chain hunt]]
