
subfinder secrets key
	chaos api key
	github api key -> create a puppet account
	shodan
	facebookCT (https://developers.facebook.com) sign in as facebook(developer)
		go to apps, create app
		create app > your app page
		get apikey
		setting > advance setting > security > client token
		Get Secret
	c99 - https://community.riskiq.com/settings

dns fuzzing
	gobuster dns --domain inlanefreight.com -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-110000.txt

vhosts
	gobuster vhost -u http://<domain> -w /usr/share/wordlists/vhost_wl.txt --append-domain