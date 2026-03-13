use this tools with gau/waybackmachine that naturally querys historycal endpoints to filter them.

—paramspider—( check wayback machine and store all the url with endpoints)
- paramspider -l <list>

param miner:
	enumerating hidden http parameters and request headers -> burp suite extention


—arjun—(parameter discovery)
- arjun -i <list_domains> -oT <result_file>

obs: the flag -t add processor threads, so this tool can work fastly








				---filters---
—gf—(works like a grep with vulnerabilities patters, such as xss, sqli)

—unfurl—(works like a grep, but better than gf because this tool search for ‘=’ and ‘&’, intead of comum patterns)
	cat domains | gau | unfurl keypairs | anew