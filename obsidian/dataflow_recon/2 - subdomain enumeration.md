#phase

DNS-track host discovery

merge passive sources
	`cat subdomains_raw.txt cloud_hosts.txt censys_hosts.txt sonar_rdns.txt 2>/dev/null | sort -u > subdomains_merged.txt`

puredns resolve (wildcard-aware)
	`puredns resolve subdomains_merged.txt -r resolvers.txt --write subdomains_resolved.txt`
	puredns runs massdns under the hood + handles wildcard DNS responses correctly (massdns/dnsx alone produce inflated lists on wildcard-DNS targets)

alterx permutations (conditional — only if subdomain count is thin, <50)
	`alterx -enrich -l subdomains_resolved.txt -o permutations.txt`
	alterx auto-extracts target-specific word patterns. skip this step on targets where you already have hundreds of resolved subs — diminishing returns
	`puredns resolve permutations.txt -r resolvers.txt --write -- | anew subdomains_resolved.txt`

dnsx enrichment (optional, only for IP-track pivot)
	`dnsx -l subdomains_resolved.txt -ptr -cname -a -resp -o dns_enriched.txt`

cleaning out of scope before surface mapping:
	`grep -vFf out_of_scope.txt subdomains_resolved.txt | sponge subdomains_resolved.txt`

-- input:
	scope.txt
	subdomains_raw.txt, cloud_hosts.txt, censys_hosts.txt

-- output:
	[[subdomains_resolved.txt]]
	[[permutations.txt]]  (optional)

subphase -> [[2.1 - network active scanning]]  (only when IP/ASN scope present)
next phase -> [[3 - surface mapping]]
