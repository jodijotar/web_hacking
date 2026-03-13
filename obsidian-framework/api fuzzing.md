Dowload the JSON datasets and the route-.kite
—[https://github.com/assetnote/kiterunner—](https://github.com/assetnote/kiterunner%E2%80%94)
- `kr scan target.com -w routes.kite -A=apiroutes-210228:20000 -x 10 --ignore-length=34`
- kr brute <domain> -w <route.kite_list_name> -A=apiroutes-210228:20000 -x 10

Dowload the world list https://wordlists.assetnote.io
- ffuf -u https://domain.com/FUZZ -w httparchive_apiroutes_date.txt -mc 200 -t (threads)