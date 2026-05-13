#phase

convergence point. DNS-track (phase 2) merges with IP-track (phase 2.1, if run). everything probed identically with httpx

merge tracks
	`cat subdomains_resolved.txt ip_no_dns.txt 2>/dev/null | sort -u > all_hosts.txt`

httpx — tech-detect is critical for downstream template/payload selection
	`cat all_hosts.txt | httpx -status-code -title -content-length -web-server -tech-detect -asn -follow-redirects -t 50 -ports 80,8080,443,8443,4443,8888 -o live_hosts.csv`

cdncheck + tlsx (optional)
	when many hosts return identical generic responses, fingerprint CDN/WAF before fuzzing later phases
	`tlsx -l all_hosts.txt -san -cn -o tls_certs.txt`

gowitness
	`gowitness file -f all_hosts.txt -P ./screenshots`
	screenshot review at checkpoint 1 is the highest-signal time investment in the whole pipeline

-- input:
	subdomains_resolved.txt
	ip_no_dns.txt  (optional)

-- output:
	[[all_hosts.txt]]
	[[live_hosts.csv]]
	[[screenshots]]

-- [[checkpoint 1 - manual triage]]
