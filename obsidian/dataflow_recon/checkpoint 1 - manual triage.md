#checkpoint

review gowitness screenshots host-by-host. this is where the highest-leverage time is spent in the entire pipeline

annotate live_hosts.csv with priority. crude scoring rubric:
	+5  admin / internal / dashboard / portal / console panels
	+5  payment, billing, api, oauth, sso endpoints
	+3  multi-tenant indicators (subdomains shaped like customer1.app, tenant slugs)
	+3  SSO redirect targets (login.target.com, auth.target.com)
	+2  non-standard port (anything not 80/443)
	+2  came from ip_no_dns.txt (invisible to other hunters)
	-5  generic WAF cookie-cutter response (Cloudflare 403, Akamai block)
	-3  marketing/landing static site (no functionality, no auth)

ip_no_dns.txt hosts deserve attention. these don't appear in standard subdomain enumeration -> less competition

output `priority_hosts.txt` with hosts scoring >= 5. all subsequent phases operate against this list only

-- output:
	[[priority_hosts.txt]]

next phase -> [[3.5 - authenticated recon]]
