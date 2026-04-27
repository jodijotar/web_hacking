#phase

paramspider + arjun
	paramspider mines wayback for param URLs. arjun actively discovers hidden params on each endpoint. merge outputs.

unfurl
	cat historical_urls.txt spidered_urls.txt js_endpoints.txt | unfurl keypairs | anew to extract key=value pairs

gf
	cat historical_urls.txt spidered_urls.txt js_endpoints.txt | gf ssrf

kiterunner
	`kr scan target.com -w routes.kite -A=apiroutes-210228:20000 -x 10` — brute force API routes using the assetnote dataset.

/.well-know/ probing
	check openid-configuration, security.txt, assetlinks.json, mta-sts.txt 
		-> often leaks auth endpoints and OAuth flows

js bundle analysis (SSRF):
	- download all live JS files
		`cat phase5_params/js_files.txt | xargs -P10 -I@ bash -c \ 'curl -sk "@" -o "phase4_content/js_cache/$(echo @ | md5sum | cut -d" " -f1).js"'`
	- grep the cached bundle for SSRF url patterns
		`grep -rhE \ "(fetch|axios|xhr|http|request)\s*\(?\s*['\"]?\s*/[a-z].*[?&](url|src|href|callback|redirect|proxy|load|import|fetch|endpoint)=" \ phase4_content/js_cache/ >> phase5_params/js_post_params.txt`
	- POST calls with url-shaped body params
		`grep -rhE \ "\.post\s*\(.*['\"]url['\"]|\.post\s*\(.*['\"]src['\"]|\.post\s*\(.*['\"]href['\"]" \ phase4_content/js_cache/ >> phase5_params/js_post_params.txt`
	- look for string patterns suggesting SSRF
		`grep -rhE \ "(webhook|callback|import|export|render|screenshot|pdf|preview|fetch|proxy)\s*[:\(=].*https?://" \ phase4_content/js_cache/ >> phase5_params/js_post_params.txt`
	
-- input:
	historical_urls.txt
	spidered_urls.txt
	js_endpoints.txt

-- output:
	[[params.txt]]
	[[api_endpoints.txt]]
	[[interesting_params.txt]]
	[[js_post_params.txt]]

-- [[checkpoint 2 - feature mapping & threat model]]