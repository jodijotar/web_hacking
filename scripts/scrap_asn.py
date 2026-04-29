import requests
from bs4 import BeautifulSoup
import re

url = 'http://bgp.he.net' #bgp table url
org_name = #full name related to the asn

r = requests.get(url)
soup = BeautifulSoup(r.text, 'html.parser')

table = soup.tbody
line = '<tr>'

for line in table:
    line = str(line).strip().split('\n')
    if len(line) > 1:
        if re.search(org_name, line[2]):
            m = re.search(r'\bAS[0-9]+\b', line[1])
            if m:
                asn = m.group(0)
                print(asn)







