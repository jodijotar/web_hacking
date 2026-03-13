--- Web ---
	[[subdomain enumeration]]
	[[bash script - website enumeration]]
	[[github recon]]
	[[historical endpoints]]
	[[directories and files enumeration]]
	[[parameter discovery]]
	[[api fuzzing]]

--- Network ---
	[[ASN]]
	permutation -> altdns, rpgen, dnsgen
	dns resolution -> massdns, pure dns, dnsx
	[[cloud recon and monitoring]]
	[[noisy port scanning]]
	[[invisible port scanning]]
	
--- monitoring ---
	tools: amass, sublert, jsmon
		monitoring for new changes such as http headers, js file changes, new subdomains, opening ports, etc.
		
CVEs + PoC -> https://snyk.io/vuln/

page render:
	eyewitness
        https://github.com/FortyNorthSecurity/EyeWitness
    Snapper
        https://github.com/dxa4481/Snapper.
    gowitness
	    use : gowitness file -f <domain_list> -P <path_screenshots>

framewoks:
	reconFTW
	Osmedeus
	reNgine
	Axiom
