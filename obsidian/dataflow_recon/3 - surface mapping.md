#phase 

convergence point — DNS track (phase 2) and IP track (phase 2.1) merge here
	merge both tracks before probing 
	`cat phase2_subdomains/subdomains_resolved.txt phase2.1_network_active/ip_no_dns.txt | anew all_hosts.txt`

httpx
	`cat subdomains_resolved.txt | httpx -status-code -title -content-length -web-server -tech-detect -asn -no-color -follow-redirects -t 10 -ports 80,8080,443,8443,4443,8888 -o live_hosts.csv`

gowitness
	`gowitness file -f subdomains_resolved.txt -P ./screenshots

-- input:
	subdomains_resolved.txt

-- output:
	[[all_hosts.txt]]
	[[live_hosts.csv]]
	[[screenshots]]

-- [[checkpoint 1 - manual triage]]

