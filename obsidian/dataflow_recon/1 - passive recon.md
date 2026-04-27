#phase 

*web:

kaeferjaer.gay
	dowload ssl cert snapshots for cloud ips.
		`cat *.txt | grep -F ".target.com" | awk -F'--' '{print $2}' | tr '[' ' ' | sed 's/ //' | sed 's/]//' | grep -F ".target.com" | sort -u`

Caduceus
	active cert scan over port 443 of cloud ip ranges to find hosts sharing the same cert

gungnir
	subscribe to certificate transparency logs for continuous monitoring of new subdomains

Censys / tracxn
	discover acquired companies and related domains -> expand scope.txt accordingly

*network:

smap
	queries shodan existing scan data to return port and banner info for ip ranges

Censys API (paid resource)
	historical scan data with port and protocol information.
		->useful to confirm which ips are currently live before commiting to active scanning

Project Sonar (Rapid7)
	open dataset of forward and reverse DNS mappings collected from internet-wide scans.
		-> Key value: the RDNS dataset maps IPs to hostnames that once resolved to them
			— including decommissioned DNS records. 
			cross-referencing against `ip_ranges.txt` surfaces hosts that were forgotten and removed from DNS but still live on the network.

-- input:
	scope.txt
	ip_ranges.txt
	asns.txt

-- output:
	[[cloud_hosts.txt]]
	[[censys_hosts.txt]]
	[[smap_results.txt]]
	[[sonar_rdns.txt]]

next phase -> [[2 - subdomain enumeration]]