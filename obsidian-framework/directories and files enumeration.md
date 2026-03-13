fuzz everything (endpoints, parameters, directories, etc) and use context-adapted word lists instead of generic list(https://wordlists.assetnote.io)

--fuzzing tools: dirsearch, fuff
	---(make a fuzzing framework)---

[[js directory and new urls enumeration]]

testing:
	
bash tip - validation:
1° —> gau -subs <domain> | grep -iE '\.js' | grep -iEv '(\.jsp|\.json)' >> js.txt

2° —> cat js.txt | anti-burl | awk '{print $4}' | anew alive_js.txt

install —linkfinder—

3° —> #xargs -a alive_js.txt -n 2 -I@ bash -c "echo -e '\n[URL]: @\n'; python3 /path/to/linkfinder.py -i @ -o cli”

install —[https://github.com/KingOfBugbounty/Bug-Bounty-Toolz/blob/master/collector.py—](https://github.com/KingOfBugbounty/Bug-Bounty-Toolz/blob/master/collector.py%E2%80%94)

4° —> cat example_js.txt | python3 /path/to/[collector.py](http://collector.py/) example/output