#phase

paramspider + arjun
	paramspider mines wayback for param URLs
	arjun actively discovers hidden params on each endpoint
	merge outputs into params_merged.txt
		`paramspider -l priority_hosts.txt -o paramspider_raw.txt`
		`arjun -i priority_hosts.txt -oT arjun_raw.txt`
		`cat paramspider_raw.txt arjun_raw.txt | anew params_merged.txt`

unfurl
	`extract key=value pairs from all collected URLs` 
	`cat all_urls.txt | unfurl keypairs | anew params_merged.txt`

gf
	filter params_merged.txt and all_urls.txt by vulnerability pattern
	`cat all_urls.txt | gf ssrf >> interesting/gf_ssrf.txt`
	`cat all_urls.txt | gf redirect >> interesting/gf_redirect.txt`
	`cat all_urls.txt | gf xss >> interesting/gf_xss.txt`

kiterunner
	`kr scan target.com -w routes.kite -A=apiroutes-210228:20000 -x 10`

/.well-know/ probing
	check openid-configuration, security.txt, assetlinks.json, mta-sts.txt 
		-> often leaks auth endpoints and OAuth flows

openapi / swagger discovery
	probe each priority host for schema at common paths:
		/api-docs, /swagger.json, /openapi.json, /v1/api-docs, /redoc, /docs

graphql introspection
	`POST {"query":"{ __schema { types { name fields { name } } } }"} to /graphql -> look for mutations/fields with argument names: url, webhookUrl, callbackUrl, importUrl`

js bundle analysis (SSRF surface) 
	download all live JS files from js_files.txt into js_cache/ named by md5 hash 
	`cat js_files.txt | xargs -P10 -I@ bash -c  'curl -sk "@" -o "phase4_content/js_cache/$(echo @ | md5sum | cut -d" " -f1).js"'`
	[[js grep regex]]

-- input:
	all_urls.txt
	js_files.txt
	priority_hosts.txt

-- output:
	[[params_merged.txt]]
	[[api_endpoints.txt]]
	[[wellknow_findings.txt]]
	[[openapi_specs]]
	[[graphql_schema.json]]
	[[js_post_params.txt]]
	[[interesting_params.txt]]

-- [[checkpoint 2 - feature mapping & threat model]]