--- subdomain recon resources ---
	--subfinder secrets key
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
        dnsdumpster.com
    --additional tools
	    amass, sublist3r and findomain
    --paid/limited sources
        cisco umbrella - 70k/y
            work with a nonprofit company to provide transparency of DNS data for a nonprofit project
            bug bounty hunter project api for free
        DNSDB - 30k/y
        Zetalytics - 15k/y
        SecurityTrails
        SpiderFootHX
        Netlas.io
    BBOT

--- fuzzing with seclists ---
	ffuf -u <target_domain> -w /usr/share/wordlists/seclists/Discovery/DNS/subdomains-top1million-110000.txt -H "Host: FUZZ.<target_domain>"