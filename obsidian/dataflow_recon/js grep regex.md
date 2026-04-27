grep cached bundles for server-side URL fetch patterns
	`grep -rhE \`
	  `"(fetch|axios|xhr|http|request)\s*\(?\s*['\"]?\s*/[a-z].*[?&](url|src|href|callback|redirect|proxy|load|import|fetch|endpoint)=" \`
	  `phase4_content/js_cache/ >> js_post_params.txt`

grep POST calls with url-shaped body params
	`grep -rhE \`
	  `"\.post\s*\(.*['\"]url['\"]|\.post\s*\(.*['\"]src['\"]|\.post\s*\(.*['\"]href['\"]" \`
	  `phase4_content/js_cache/ >> js_post_params.txt`

grep verbs that imply server-side outbound connection
	`grep -rhE \`
	  `"(webhook|callback|import|export|render|screenshot|pdf|preview|fetch|proxy)\s*[:\(=].*https?://" \`
	  `phase4_content/js_cache/ >> js_post_params.txt`