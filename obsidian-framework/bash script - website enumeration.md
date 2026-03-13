this script does subdomain enumeration and validate and returns the status code.

--website domains enumerations in csv format
	`while IFS= read -r line; do subfinder -d $line -all | httpx -status-code -title -content-length -web-server -asn -location-no-color -follow-redirects -t 10 -ports 80,8080,443,8443,4443,8888 -no-fallback -probe-all-ips -random-agent -o $line -oa; done < scope.txt`
		put every apex on a line in the text file scope

ADD feat:
	intregrate with amass, sublist3r and findomain
	make a python script that: 
		handles the output and organize directory and analyze the data by status code
		after the script run, put all the subdomains together in an additional txt file.
	technology fingerprint
	
