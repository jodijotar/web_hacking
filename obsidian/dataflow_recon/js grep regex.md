#reference

grep JXScout-cached bundles for server-side URL fetch patterns. complements JSluice (which catches the structured cases); these regexes catch the messy minified concatenated cases JSluice's AST sometimes misses

grep server-side URL fetch in query string
	`grep -rhE "(fetch|axios|xhr|http|request)\s*\(?\s*['\"]?\s*/[a-z].*[?&](url|src|href|callback|redirect|proxy|load|import|fetch|endpoint)=" ~/.jxscout/<target>/ >> js_post_params.txt`

grep POST calls with url-shaped body params
	`grep -rhE "\.post\s*\(.*['\"]url['\"]|\.post\s*\(.*['\"]src['\"]|\.post\s*\(.*['\"]href['\"]" ~/.jxscout/<target>/ >> js_post_params.txt`

grep verbs that imply server-side outbound connection (the SSRF heuristic)
	`grep -rhE "(webhook|callback|import|export|render|screenshot|pdf|preview|fetch|proxy)\s*[:\(=].*https?://" ~/.jxscout/<target>/ >> js_post_params.txt`

postMessage handlers (for stored XSS+IDOR chain candidates only — skip for pure BAC focus)
	`grep -rhE "window\.addEventListener\s*\(\s*['\"]message['\"]" ~/.jxscout/<target>/`
	check whether handler validates `event.origin` — missing check = cross-origin XSS primitive

dangerous sinks (only if hunting stored XSS for chain into IDOR ATO)
	`grep -rnE "innerHTML\s*=|dangerouslySetInnerHTML|document\.write\(" ~/.jxscout/<target>/`
