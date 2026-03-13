—subjs—
- cat <list_domains> | gau | subjs | anew <output_file_name>

→install js beautifier in firefox extensions

—gau—
- echo ‘[domain.com](http://domain.com)’ | gau | grep -E “\.js(?:onp?)?$” | anew

		--- js validation and tech-detect ---
httpx -status-code -title -tech-detect -l <domain_list>

			--- crawling ---
make tools to crawl js files and search for secrets, /paths and ?params=
		secretfinder.py
		linkfinder.py

monitoring for new changes in js files https://github.com/robre/jsmon