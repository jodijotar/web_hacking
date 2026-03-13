—WAYBACKURLS—
single domain search : echo “<domain>” | waybackurls
list search: cat <domains_list> | waybackurls

—GAU—
use:
$ printf <domain>| gau 
$ cat <domains.txt >| gau --threads 5 
$ gau <domain> google.com 
$ gau <domain> --o output.txt 
$ gau <domain> --blacklist png,jpg,gif