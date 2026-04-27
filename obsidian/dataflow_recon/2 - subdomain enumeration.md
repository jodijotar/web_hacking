#phase 

subfinder / amass
	run with other services api keys (github puppet, shodan, facebook CT, c99, security trails) merge and deduplicate with anew

altdns / dnsgen
	generate permutations from the discovered subdomains and feed back into DNS resolution

massdns / dnsx
	resolve the full merged list. Discard NXDOMAIN, keep live hosts

gobuster dns + vhost
	brute force DNS and virtual hosts. Append results to the resolved list

-- input:
	scope.txt
	cloud_hosts.txt

-- output:
	[[subdomains_raw.txt]]
	[[subdomains_resolved.txt]]
	[[permutations.txt]]

subphase -> [[2.1 - network active scanning]]
next phase -> [[3 - surface mapping]]