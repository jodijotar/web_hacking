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

-- input:
	historical_urls.txt
	spidered_urls.txt
	js_endpoints.txt

-- output:
	[[params.txt]]
	[[api_endpoints.txt]]
	[[interesting_params.txt]]

-- [[checkpoint 2 - feature mapping & threat model]]