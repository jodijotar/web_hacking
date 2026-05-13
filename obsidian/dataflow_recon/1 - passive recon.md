#phase

zero-footprint intelligence gathering. all subdomain sources collapsed into subfinder (consolidates across amass/assetfinder/findomain APIs). bbot retained only if running its full recursive pipeline; otherwise the pieces below are sufficient and faster

subfinder
	`subfinder -dL scope.txt -all -recursive -o subdomains_raw.txt`
	configure API keys: GitHub, Shodan, Censys, SecurityTrails, VirusTotal, Chaos, BinaryEdge, BeVigil. without keys recall drops ~40%

kaeferjaeger SSL snapshots
	weekly cloud-provider SSL cert dumps. surfaces hosts that won't appear in passive DNS sources
	`cat *.txt | grep -F ".target.com" | awk -F'--' '{print $2}' | tr '[' ' ' | sed 's/ //' | sed 's/]//' | grep -F ".target.com" | sort -u >> cloud_hosts.txt`

gungnir
	subscribe to certificate transparency for continuous monitoring of new subdomains across long engagements

github recon
	`trufflehog github --org=<org> --include-wikis --issue-comments --pr-comments --results=verified > github_secrets.txt`
	verified-only flag suppresses unreliable matches. covers wikis, issue/PR comments — surfaces most secrets miss
	supplement with a few targeted dorks via web UI for org-specific patterns:
		`"target.com" filename:.env`
		`"target.com" "api_key"`
		`"internal.target.com"`

postman OSINT
	postman public workspaces leak production endpoints + tokens at scale
	web search: `site:postman.com "target.com"` -> open workspaces and harvest collections
	`trufflehog postman --workspace <workspace_id>` on any returned workspace

smap (passive shodan-backed)
	`smap -iL scope.txt -oS smap_results.txt`

censys / shodan
	favicon hash + cert.subject.CN pivots for asset attribution. only invoke when subdomain count is thin or to discover related infrastructure not in BBP scope but in scope

project sonar RDNS (optional)
	useful only when ASNs/IP ranges are in scope. cross-reference RDNS dataset against `ip_ranges.txt` to surface hosts removed from DNS but still live

-- removed from previous workflow:
	noseyparker (redundant with trufflehog when no local repo clone)
	gitdorker / gitrob (effectively superseded by trufflehog github with comments/wikis flags)

-- input:
	scope.txt
	asns.txt (optional)

-- output:
	[[subdomains_raw.txt]]
	[[cloud_hosts.txt]]
	[[smap_results.txt]]
	[[censys_hosts.txt]]
	[[sonar_rdns.txt]]  (optional)
	[[github_secrets.txt]]

next phase -> [[2 - subdomain enumeration]]
