#phase

slimmed from previous version. paramspider gone, kiterunner gone, param miner gone. arjun retained but conditional. focus shifts to API discovery for BAC, not generic param mining

unfurl on collected URLs (passive, fast)
	`cat all_urls.txt | grep '=' | unfurl keys | sort -u > params_passive.txt`
	supersedes paramspider — same data source (Wayback via gau), one fewer tool

arjun (optional, single run on top priority host only)
	`arjun -u https://app.target.com -oT arjun_raw.txt --headers "Cookie: <session>"`
	authenticated arjun finds parameters the server accepts but doesn't advertise. occasional mass-assignment surface (isAdmin, role, verified, tenant_id)
	hit rate on modern frameworks (Rails/NestJS/Spring with DTOs) is low — run once, don't make it a phase

API discovery — the real value here
	openapi/swagger probe
		probe each priority host for schema at common paths:
			`/api-docs /swagger.json /openapi.json /v1/api-docs /v2/api-docs /redoc /docs /swagger-ui.html /api/swagger.json /api/v1/swagger.json`
		`nuclei -t exposures/apis/ -l priority_hosts.txt -o openapi_findings.txt`
		web search outside the target too: `site:github.com "target.com" openapi`, `inurl:swagger.json site:target.com`
		any openapi spec found = complete API inventory for BAC matrix in phase 7

	graphql
		`{__typename}` probe on common paths: `/graphql /api/graphql /v1/graphql /altair /playground /gql`
		if found, introspection:
			`graphw00f -t target.com` -> engine fingerprint
			InQL (Caido extension) -> introspection + query templating
			if introspection disabled: Clairvoyance to rebuild via field-suggestion errors
		log mutations/fields with arguments named: url, webhookUrl, callbackUrl, importUrl (SSRF candidates), id/userId/orgId (IDOR candidates)

	mobile API extraction (when in scope)
		pull APK from APKMirror
		`jadx -d unpacked/ app.apk`
		`apkleaks -f app.apk`
		`grep -rhE "https?://[^\"']+|/api/[^\"']+" unpacked/ | sort -u >> api_endpoints.txt`
		mobile backends frequently rely on client-side checks where the web counterpart has proper server-side authz -> high BAC yield

	postman OSINT (revisit if not done in phase 1)
		web search: `site:postman.com "target.com"`
		`trufflehog postman --workspace <id>`

well-known probing
	`/.well-known/openid-configuration` -> OAuth/OIDC endpoints, issuer, scopes
	`/.well-known/security.txt`
	`/.well-known/assetlinks.json` -> mobile app package names (feed back into mobile pipeline)
	`/.well-known/change-password`, `/.well-known/mta-sts.txt`

gf filtering (light usage now — most filtering happens at phase 7 against authenticated traffic)
	`cat all_urls.txt | gf ssrf >> interesting/gf_ssrf.txt`
	`cat all_urls.txt | gf redirect >> interesting/gf_redirect.txt`
	skip gf_xss given your stated focus

js post params (your existing SSRF surface technique — keep)
	grep cached JXScout bundles for server-side URL fetch patterns. see [[js grep regex]]

-- removed from previous workflow:
	paramspider (Wayback-only, gau already covers)
	kiterunner (low hit rate vs openapi/swagger when accessible; the better surface comes from leaked specs)
	Param Miner (cache-poisoning/host-header tool — wrong target for BAC focus)
	gf xss (not your bug class)

-- input:
	all_urls.txt
	priority_hosts.txt
	jxscout folder

-- output:
	[[params_passive.txt]]
	[[arjun_raw.txt]] (if run)
	[[api_endpoints.txt]]
	[[openapi_specs]]
	[[graphql_schema.json]]
	[[js_post_params.txt]]
	[[wellknown_findings.txt]]
	[[interesting/]]

next phase -> [[5.5 - misconfig sweep]]
