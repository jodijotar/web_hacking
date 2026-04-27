#phase 

gau + wayckurls
	pull historical URLs for every priority host:
		cat priority_hosts.txt | gau --threads 100 | anew historical_urls.txt

bbot spider
	web spidering web servers that indicates features, links and some kind of navigation
		bbot -t target.com -p spider
		
		complements wayback with current live links

gau -> JS filter -> linkfinder
	gau | grep -iE '\.js' | grep -ivE '(\.jsp|\.json)' | anti-burl | linkfinder

-- input:
	priority_hosts.txt

-- output:
	[[historical_urls.txt]]
	[[spidered_urls.txt]]
	[[js_endpoints.txt]]
	
next phase -> [[5 - parameter and api discovery]]