[[sneaky osint techniques]]

domain and ASN number:
	browser extension to grab ips: instant data scraper
	bgp.he.net
	dnschecker.org -> dnslookup tool
	ARIN and RIPE Regional Registers: https://whois.arin.net/ui/query.do
	tracxn.com 
	
search engines: shodan, cross information with hurricane electric
	waybackurls web for old versions
	ssl certificate enumeration -> find subdomains, apex domains and internal domains
        Common Name
        Organization
        Subject Alt Name
	        Censys
			Cert Spotter

subfinder and httpx results:
	wappalyzer extension -> https://www.wappalyzer.com
	these deves have different environments? - app.* | dev | staging-login
	static pages hiding behind CDN?
	webhooks?
	redirects?
	dynamic servers throwing ou json?
	what technologies is it build?
	see fingerprints
	
	make notes
read all js files that are being fetched
	read and understand the js files of client side looking for:
		fetch requests,
		api endpoints,
		tokens,
		wierd names,
		
github ->leaked config files, environment variables, hard-coded secrets, check public forks that mention internal stuff

[[google dorking]]
