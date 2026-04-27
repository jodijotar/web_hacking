cat + anew
	Combine `subdomains_resolved.txt` (Phase 2, DNS track) and `ip_no_dns.txt` (Phase 2.1, IP track) into a single deduplicated input list before running httpx. If Phase 2.1 was skipped, this step is just the DNS track alone — the rest of the pipeline is identical either way.  
	
	cat phase2_subdomains/subdomains_resolved.txt
	phase2.1_network_active/ip_no_dns.txt | anew all_hosts.txt