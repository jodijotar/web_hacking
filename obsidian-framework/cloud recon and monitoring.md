AWS
    EC2 Reachability Test
cloud internal ips range:
https://github.com/lord-alfred/ipranges/blob/main/all/ipv4_merged.txt

-Active scanning the cloud for certs (Caduceus) - cover all range of ips in the port :443 that shares the same cert
    
-Passive cloud recon backup (http://kaeferjaeger.gay) -> every week they pull down every IPs SSL cert data from all the major cloud providers
        dowload the .txt file
        `cat *.txt|grep -F ".target.com"|awk -F'--''{print$2}'tr'['''|sed's/ //'|sed's/\]//'|grep -F ".target.com"|sort -u`
    continuously monitoring certs (gungnir) -> monitors the certificate transparency