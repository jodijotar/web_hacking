
if finds web servers:
	`comm -23 <(awk -F: '{print $1}' naabu_live_ports.txt | sort -u) <(awk '{print $2}' ../phase2_subdomains/subdomains_resolved.txt | sort -u) > ip_no_dns.txt`

-- output:
	[[ip_no_dns.txt]]