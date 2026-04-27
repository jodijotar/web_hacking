#phase 

httpx
	cat subdomains_resolved.txt | httpx -status-code -title -content-length -web-server -tech-detect -asn -no-color -follow-redirects -t 10 -ports 80,8080,443,8443,4443,8888 -o live_hosts.csv

gowitness
	`gowitness file -f subdomains_resolved.txt -P ./screenshots` — screenshot every live host for visual review.

-- input:
	subdomains_resolved.txt

-- output:
	[[live_hosts.csv]]
	[[screenshots - directory]]

-- [[checkpoint 1 - manual triage]]

