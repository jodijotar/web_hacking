#phase

bugcrowd public BBP only

bbscope
	pull in-scope assets directly from Bugcrowd. avoids manual scope copy and tracks scope changes over time
	`bbscope bc -t $BC_TOKEN -b <program> -o t domains > scope.txt`
	re-run weekly per program -> programs add/remove apex domains silently; diff `scope.txt` against last week to surface new attack surface no one else has scanned yet

manually verify
	read the program brief once. note: out_of_scope.txt, severity caps, testing restrictions (no auth flood, no DoS), credit/account creation policy, whether mobile / API / subdomains are explicitly in scope

bgp.he.net / ARIN
	look up ASNs only if program scope is wildcard or includes IP ranges. otherwise skip — most modern BBPs are SaaS apex-domain scopes and ASN enumeration is wasted runtime

-- output:
	[[scope.txt]]
	[[asns.txt]]  (optional, only if ASN/IP scope present)

next phase -> [[1 - passive recon]]
