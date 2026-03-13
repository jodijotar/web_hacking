install : metabigor, hakrevdns, prips

—bash—
	`echo '<company_name>' | ASSUME_NO_MOVING_GC_UNSAFE_RISK_IT_WITH=go1.22 metabigor net --org -v | awk '{print $3}' | sed 's/[[0-9]]\+\.//g' | xargs -I@ sh -c 'prips @' | hakrevdns | anew <file_name>`