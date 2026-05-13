#phase

URL and content discovery. SPA-aware: directory bruteforce removed, JS bundle analysis promoted to first-class

gau (passive, historical)
	`cat priority_hosts.txt | gau --threads 50 --subs | anew historical_urls.txt`
	covers Wayback + AlienVault OTX + Common Crawl + URLScan in one call. supersedes waybackurls + paramspider entirely
	high-value patterns to grep from this output:
		leaked tokens in URLs (`?token=`, `?reset=`, `?invite=`)
		old API versions still routable (`/api/v1/...` when current is v3)
		internal hostnames in redirect params
		user IDs / org IDs to seed the BAC matrix

JXScout (JS preprocessing — the centerpiece of this phase)
	`jxscout daemon` running in background. install the `jxscout-caido` plugin in Caido
	browse the priority hosts manually as each role. JXScout passively:
		downloads every HTML + JS asset Caido sees in-scope
		beautifies all JS
		fetches webpack/Vite/Next.js chunks the browser hasn't loaded yet
		reverses .js.map source maps when exposed (gold mine)
		inlines variable references, resolves string concats
	output lives in `~/.jxscout/<target>/` — clean folder structure suitable for both manual VS Code review and AI agent consumption

JSluice on the JXScout folder
	`find ~/.jxscout/<target> -name '*.js' | jsluice urls -i /dev/stdin | jq -r '.url' | sort -u > js_endpoints.txt`
	AST-based: understands fetch/XHR/$.ajax flows, infers method + headers + body params, substitutes unknown vars with EXPR token (fuzzable target)
	`jsluice secrets -i ...` for in-bundle keys/tokens

js-snitch (optional, fast)
	`js-snitch -input priority_hosts.txt` -> runs trufflehog + semgrep on JS bundles. good complement to JSluice secrets

merge into single source of truth
	`cat historical_urls.txt js_endpoints.txt | anew all_urls.txt`

-- removed from previous workflow:
	waybackurls (gau covers it)
	bbot spider (overlaps gau on passive; SPAs aren't crawlable on active)
	linkfinder (JSluice replaces it — AST > regex)
	ffuf directory bruteforce (modern SaaS surface lives in JS, not at /admin /backup.zip)
	katana (SPA crawler returns the static index page; JXScout actually reaches the routes)
	manual js_cache + md5 + xargs curl pipeline (JXScout does this automatically + better)

-- input:
	priority_hosts.txt

-- output:
	[[historical_urls.txt]]
	[[js_endpoints.txt]]
	jxscout folder (`~/.jxscout/<target>/`)
	[[all_urls.txt]]

next phase -> [[5 - parameter and api discovery]]
