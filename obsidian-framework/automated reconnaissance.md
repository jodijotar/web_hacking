[[subdomain enumeration]]
[[bash script - website enumeration]]
permutation -> altdns, rpgen, dnsgen
dns resolution -> massdns, puredns, dnsx
[[historical endpoints]]
[[directories and files enumeration]]
[[parameter discovery]]




---cloud recon---
    AWS
        EC2 Reachability Test
    cloud ips range:
        https://github.com/lord-alfred/ipranges/blob/main/all/ipv4_merged.txt
    Active scanning the cloud for certs (Caduceus) - cover all range of ips in the port :443 that shares the same cert
    Passive cloud recon backup (http://kaeferjaeger.gay) -> every week they pull down every IPs SSL cert data from all the major cloud providers
        dowload the .txt file
        `cat *.txt|grep -F ".target.com"|awk -F'--''{print$2}'tr'['''|sed's/ //'|sed's/\]//'|grep -F ".target.com"|sort -u`
    continuoulsy monitoring certs (gungnir) -> monitors the certificate transparency

--- Network---
	 active scanning -> tries to connect to the host port
		asnmap ->  asn number to ip ranges
			export PDCP_API_KEY=(project discovery api)
	    naabu
	    rustscan -> fast
	    `echo AS394161 | asnmap -silent | naabu -nmap-cli 'nmap -sV'` 
	passive scanning -> third-party resources
		smap
		Censys
		Project Sonar
		
CVEs + PoC -> https://snyk.io/vuln/

page renderers:
	eyewitness
        https://github.com/FortyNorthSecurity/EyeWitness
    Snapper
        https://github.com/dxa4481/Snapper.
    gowitness
	    use : gowitness file -f <domain_list> -P <path_screenshots>


[[github recon]]
