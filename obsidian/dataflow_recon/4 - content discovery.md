#phase 

gau + wayckurls
	pull historical URLs for every priority host:
	`cat priority_hosts.txt | gau --threads 100 | anew historical_urls.txt`
	`cat priority_hosts.txt | waybackurls | anew historical_urls.txt`

bbot spider
	web spidering web servers that indicates features, links and some kind of navigation
	`bbot -t target.com -p spider`

ffuf 
	directory brute force with context-adapted assetnote wordlists adjust command based on target brute forcing policies 
	`ffuf -u https://<domain_example>/FUZZ -w httparchive_apiroutes_date.txt -mc 200 -fw <404_word_count>`

gau -> grep JS filter -> linkfinder
	extract live JS files and pull internal endpoints from them
	`gau domain | grep -iE '.js' | grep -ivE '(.jsp|.json)' > js_files_raw.txt`
	`cat js_files_raw.txt | anti-burl | awk '{print $4}' | anew js_files.txt`
	`xargs -a js_files.txt -n 1 -I@ bash -c "linkfinder -i @ -o cli" >> js_endpoints.txt`
	
merge everything into single source of truth
`cat historical_urls.txt spidered_urls.txt js_endpoints.txt directories.txt | anew all_urls.txt`

-- input:
	priority_hosts.txt

-- output:
	[[historical_urls.txt]]
	[[spidered_urls.txt]]
	[[directories.txt]]
	[[js_files.txt]]
	[[js_cache]]
	[[js_endpoints.txt]]
	[[all_urls.txt]]
	
next phase -> [[5 - parameter and api discovery]]