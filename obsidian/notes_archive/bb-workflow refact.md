# A strategic refactor of your Bugcrowd recon pipeline for 2026

Your pipeline is structurally sound but carries **five tools that duplicate work already covered elsewhere in the funnel**, misses **three high-leverage layers** that BAC/IDOR specialists rely on (authenticated recon, JS bundle preprocessing, custom misconfig templates), and stops short of the **vulnerability assessment + chaining loop** that converts P3s into P1s on Bugcrowd. The AI landscape has also shifted decisively in the last 12 months: Caido's official Claude Code Skill (March 2026), Joseph Thacker's Shift acquisition (July 2025), JXScout's Caido plugin, and Burp's MCP server have collapsed AI-assisted hunting from "experimental" to a deployable layer — but only for specific tasks, and only when paired with deterministic validators. This document refactors your workflow against that reality, with concrete substitutions, a chain-pattern catalog, and five AI integration points that add measurable value rather than theatre.

---

## 1. Where your pipeline duplicates itself

Run any sufficiently broad target through your current pipeline and you will harvest the same Wayback URL three times: once via `gau`, once via `waybackurls`, and a third time inside `bbot`'s endpoint module. The right move is to keep `gau` and drop the others. **`gau` is a strict superset of `waybackurls`** — it pulls Wayback plus AlienVault OTX, Common Crawl, and URLScan — and `waybackurls` was built by Tomnomnom as the predecessor that inspired it. Modern hunter stacks (six2dez's reconftw, the YesWeHack 2024 recon series, and the patterns NahamSec demonstrates on his stream) have largely consolidated to **`katana` (active crawl) + `gau` (passive) + `waymore`** with `waybackurls` retired.

`paramspider` is a similar story. Its sole function is querying the Wayback CDX API for URLs containing `?` — exactly what `gau` already returns. PortSwigger's Daily Swig coverage of paramspider explicitly described it as a Wayback-only tool, and the maintainer has effectively stopped updating it. Replace it with `gau --subs target.com | grep '=' | unfurl keys | sort -u`. **Keep `arjun`**, however — it solves a different problem. Where `gau`/`paramspider` mine the *historical* internet for parameter names that may or may not still exist, `arjun` actively probes the *current* application with a 25,890-name wordlist to find parameters the server accepts but doesn't advertise. The two are complementary, but only `arjun` belongs in the active phase, and only on priority hosts because it's noisy.

Your subdomain permutation layer (`altdns` + `dnsgen`) is **fully obsolete**. 0xPatrik flagged altdns's core limitation back in his "Doing it a Bit Smarter" post: the tool's hardcoded permutation patterns can never include the target-specific words that real subdomain naming actually uses. The 2024–2026 winners are **`alterx -enrich`** (ProjectDiscovery, DSL-based, automatically extracts target-specific word lists), `gotator`, and `Regulator` (which uses ML on existing subdomains to predict siblings). Drop both `altdns` and `dnsgen` and pipe `alterx -enrich` into `puredns resolve` — which brings the second consolidation: your DNS resolution should be `puredns`, not raw `dnsx`. Shubham Tiwari, Trickest, and six2dez all converge on the same point, that "amass | httpx" without proper wildcard-aware DNS resolution is the most common cause of inflated-but-wrong asset lists. Keep `dnsx` for fast PTR/CNAME enrichment of an already-resolved set.

JS analysis is the fourth duplicate. **`linkfinder` is a regex tool from 2018** that misses string-concatenated URLs and emits high false-positive counts on minified bundles. BishopFox's `JSluice` (Tom Hudson, 2023) replaces it with go-tree-sitter AST analysis — it understands when a URL string flows into `fetch()`, `XMLHttpRequest`, `$.ajax`, or `document.location`, infers HTTP method/headers/body parameters, and substitutes unknown variables with a literal `EXPR` token so you get a fuzzable target rather than silent loss. The Critical Thinking podcast playbook puts it bluntly: this is the step that separates real JS analysis from "running LinkFinder and calling it a day."

Finally, **`bbot` overlaps with at least six other tools in your pipeline**. Its `subdomain-enum` preset replaces subfinder/amass/findomain (Black Lantern Security's face-off shows 44–118% more subdomains found on real targets); its `spider` and `http_endpoints` modules duplicate gau + waybackurls + ffuf; its `paramminer` overlaps arjun. The deeper problem is that bbot is recursive and event-driven, while your pipeline is sequential — the moment you put bbot inside a phased flow, you nullify its core advantage. Pick one mode: either commit to bbot as the recursive engine for phases 1–4, or retain piecemeal tools and remove bbot. Running both is the worst of both worlds.

**Net consolidation:** drop `waybackurls`, `paramspider`, `altdns`, `dnsgen`, `linkfinder`. Add `bbscope` (Bugcrowd scope automation), `puredns` (proper resolution), `alterx` (modern permutations), `JSluice` (modern JS), `katana` (modern active crawler), and **Param Miner** as a Burp/Caido extension for the cache-poisoning and hidden-header layer that your current params phase doesn't touch. That's a net change of −5/+6 tools with significantly less duplicate work, and crucially, it pulls your pipeline into the same shape as what NahamSec, six2dez, and the CTBB community publicly run today.

---

## 2. What top BAC/IDOR hunters do that your pipeline doesn't

The pattern across **NahamSec, Jason Haddix (TBHM v5), Sam Curry, Justin Gardner, Douglas Day, Joel Margolis, Inti De Ceukelaire, and Tomnomnom** is striking: their *recon* methodologies diverge wildly, but their *post-recon* workflow converges on a single discipline — **deep manual feature mapping with multiple authenticated accounts before any fuzzing**. Douglas Day, who is top-50 on HackerOne with 8x best-collab, says explicitly that he is *"not a recon expert"* and that his hunting is *"100% manual — just me and Burp Suite"*; his methodology starts with thirty minutes spent inside the invite/sharing/billing functionality of a SaaS app testing for invite-existing-user PII leaks, auto-acceptance, role-modifiable invite payloads, and expired-invite reuse. Joel Margolis advises spending *"at least 20–30 minutes of your recon devoted to understanding and using the product yourself."* Sam Curry's Subaru and BMW disclosures both began with a manual `nslookup` → subdomain pivot → SSO-style account creation, not with a 10,000-host scan. **Your pipeline has no authenticated phase**, and that is its single biggest gap for BAC/IDOR work.

The minimum addition is a **multi-account, multi-tenant phase between `priority_hosts` and `feature_map`**. Three accounts per role tier (admin, user-A, user-B) and two tenants where the program permits it; PwnFox + Firefox Multi-Account Containers to keep cookie jars isolated; tokens stored in a creds vault and refreshed via Caido session handlers so the role-differential tools (Autorize, AuthMatrix, Auth Analyzer) don't break mid-run. Caido's own AuthMatrix port (m4st3rspl1nt3r) and the Caido Autorize plugin are now mature; AuthMatrix is best when you have ≥3 roles, Autorize is faster for binary admin-vs-user, and Auth Analyzer is the cleanest UX for API-only Bearer-token apps. None of these are substitutes for the manual ID-swap matrix you should run on every authenticated request — horizontal swap, vertical swap, anonymous strip, verb tampering, parameter pollution, mass assignment, UUID swap, tenant header swap, and the often-forgotten *nested-JSON IDOR* where the outer `eventID` is auth-checked but the inner one isn't (the Codii pattern that made Hackerearth's profile-XSS go from self-XSS to mass ATO).

API discovery deserves expansion well past `kiterunner`. **Postman's public workspace network indexes 200,000+ workspaces** and TruffleHog estimates 4,000+ live secrets are leaking through it at any given moment; the fastest entry is `trufflehog postman --workspace <id>` plus Google dorks like `site:postman.com "target.com"`. **Swagger/OpenAPI hunting via Google dorks** (`inurl:swagger.json site:target.com`, `inurl:"/v2/api-docs"`, `intitle:"Swagger UI"`) and GitHub code search (`"openapi": "3" target.com`, `path:swagger.json`) are routinely high-yield. **GraphQL needs its own toolchain**: `graphw00f` for engine fingerprinting, `Clairvoyance` to rebuild schemas when introspection is disabled (it abuses field-suggestion errors), `InQL` inside Burp for introspection + query templating, and the universal probe `{__typename}` to detect endpoints at non-obvious paths like `/api/v1/gql`, `/altair`, `/playground`. **Mobile is the most under-exploited surface for BAC**: APK → `jadx` → `apkleaks` → `MobSF` produces an endpoint inventory that's typically larger than the web's, and mobile backends frequently rely on client-side checks (UI-hide, jailbreak detection) where the web counterpart has proper server-side authorization. Pull the APK from APKMirror, decompile, grep `https?://` and `/api/`, then re-feed those endpoints into AuthMatrix with each of your role accounts.

Subdomain takeover detection should be a **scheduled module**, not a one-shot. The 2024 HackerOne "Guide to Subdomain Takeovers 2.0" includes the canonical workflow: dangling CNAME detection via `dnsx -cname` → parallel `nuclei -t http/takeovers/`, `dnsReaper`, `subzy`, and `BadDNS` → cross-check `can-i-take-over-xyz` for any service not yet templated, then **write a custom Nuclei template for it** (this is where the edge lives — Patrik Hudak's rule #1 of takeovers is "who creates a PoC first, wins"). Critical takeovers chain: cookies scoped `Domain=.target.com` flow to all subdomains, OAuth `redirect_uri` whitelists often allow `*.target.com`, and CSP `script-src` whitelists of sibling subdomains let you bypass the parent's CSP. Arne Swinnen's classic Uber `saostatic.uber.com` chain (HackerOne #219205) is still the textbook example.

Custom **Nuclei templates for misconfig** are non-negotiable in 2026. Default templates are run by everyone, so duplicates are guaranteed; the differentiator is encoding patterns specific to the target — internal hostnames found in JS, framework banners, the customer's CVE-relevant tech stack. Recommended runtime tagging: `-tags exposure,panel,config,token,takeover,cve -severity medium,high,critical -exclude-tags info,tech,ssl`, with `-rl 50` to be a polite neighbor. The `exposed-panels`, `exposures`, `default-logins`, and `token-spray` categories are your highest-yield buckets for misconfig surface; `token-spray` in particular validates which API service a found credential belongs to, which is the bridge between GitHub dorking and exploitation. ProjectDiscovery's `nuclei -ai` flag lets you generate templates from natural-language descriptions for ad-hoc detections, with a 100/day free quota on PDCP.

**GitHub/GitLab dorking** belongs in phase 1. The 2025 GitHub Recon Checklist by Tillson Galloway documents techniques you don't yet exploit: cross-fork object reference (deleted forks' commit objects remain reachable via the parent repo by SHA, accessible via `trufflehog github-experimental --object-discovery`), PR "Files Changed" tabs on stale closed PRs that show secrets "fixed" by deletion but still in history, and the gist/wiki/issue/PR-comment surfaces that most scanners miss. Stack: `trufflehog github --org <ORG> --results=verified --include-wikis --issue-comments --pr-comments` for verified secrets, `noseyparker` for high-throughput cloned-repo scanning, `gitGraber` as a daemon for new commits matching service patterns, and `git-dumper` for any exposed `.git` directory you find on the target. `keyhacks` validates found API keys and tells you which service they belong to.

JS analysis goes beyond linkfinder via **JSluice + JXScout + source-map exploitation**. JXScout (Francisco Neves, github.com/francisconeves97/jxscout) is the canonical preprocessing layer hunters now feed to AI: it hooks Caido/Burp proxy traffic, downloads every HTML/JS asset, beautifies them, runs AST analysis, **fetches webpack/Vite/Next.js chunks the browser hasn't loaded yet**, automatically reverses `.js.map` files when exposed, inlines variable references and resolves string concatenations to surface endpoints invisible to plain regex, and stores everything in `~/.jxscout/<project>/` — perfect for both VS Code navigation and AI tool consumption. The `jxscout-caido` plugin (April 2025) sends in-scope requests to the daemon. JXScout doesn't *do* AI itself; it produces clean, organized JS that AI consumes well, which is why it has become the standard preprocessing layer in the Caido user community.

Cloud asset enumeration is your final structural gap. `cloud_enum` covers AWS/Azure/GCP simultaneously; `S3Scanner`, `lazys3`, `goblob`, and `MicroBurst`'s `Invoke-EnumerateAzureBlobs` cover provider-specific deep scans; permutations are generated from brand keywords, region/env codes (`prod`, `dev`, `staging`, `eu`, `us`), and function names (`backups`, `logs`, `assets`, `dumps`, `ci`). Each found bucket gets four tests — public read, public write, public list, dangling reference — and the dangling-CloudFront-distribution case is a high-impact finding most hunters skip. `hackingthe.cloud` is the canonical reference for the misconfig patterns and the chain into S3 bucket takeover.

Cache poisoning and web cache deception belong in your post-recon phase. **Param Miner**'s "Guess headers/cookies/params" right-click action probes 65,536 unkeyed-input names per request via binary search; the typical hits are `X-Forwarded-Host`, `X-Forwarded-Scheme`, `X-Original-URL`, `X-Rewrite-URL`. Always toggle `Add 'fcbz' cachebuster` so you don't poison real users. James Kettle's BlackHat USA 2024 paper *"Gotta cache 'em all"* introduced new path-confusion variants that revived web cache deception as a top-tier 2024–2025 chain, and Naglinagli's July 2024 ChatGPT account takeover (cached `/api/auth/session/foo.css` returning the victim's session) is the canonical recent example of how cache + auth chain into ATO.

Auth flow analysis closes the loop. **JWT** misconfig still pays — `alg: none`, RS256→HS256 algorithm confusion, `kid` injection (path traversal or SQLi in the lookup), `jku`/`jwk` injection (point at attacker JWKS), and ECDSA Psychic Signatures (CVE-2022-21449) on un-patched Java apps. **OAuth** chains include redirect_uri path bypasses (the Booking.com Salt Labs case), missing/static `state` enabling login CSRF, `response_type` switching (Frans Rosén's "Dirty Dancing"), token leakage via `Referer` to third-party JS, and the **nOAuth pattern** documented by Descope where Microsoft Entra apps trust the unverified email claim and a tenant admin can set arbitrary email values on a user → "Sign in with Microsoft" → cross-tenant ATO at any vulnerable SaaS ($75k bounty pool). **SAML** retains XML Signature Wrapping (8 distinct XSW variants in SAML Raider), assertion replay without `NotOnOrAfter`/`OneTimeUse`, audience-restriction-missing relay, and 2025's PortSwigger "Fragile Lock" research adds new XSW classes against open-source libraries.

---

## 3. The AI landscape, honestly

The AI tooling for bug bounty hunters has crossed a maturity threshold in the last twelve months, but it has also produced a parallel wave of theatre. Three things matter strategically: **what's installable now**, **what works**, and **what to skip**.

**Caido + Claude Code is the marquee integration.** There are three components that get conflated under "Caido AI." First, **Caido Assistant** is Caido's native, server-hosted GPT-4o-class LLM available to paid subscribers, providing traffic explanation and PoC drafting. Second, **Shift** — originally Joseph Thacker's third-party plugin, **acquired by Caido on July 16, 2025** and now free for paid users — provides natural-language Replay modification, HTTPQL query generation, match-and-replace generation, wordlist generation, and a "Shift Agents" micro-framework with bring-your-own API key (OpenAI/Anthropic/Google/OpenRouter, or local via Ollama/LiteLLM). Third, the **official Caido Skills package for Claude Code** released **March 6, 2026** (caido.io/blog/2026-03-06-caido-skill, github.com/caido/skills), built collaboratively with Joseph Thacker. Skills give AI agents complete programmatic control of Caido — replay sessions, findings, requests/responses search, automate/fuzzing sessions, environments, match-and-replace rules — via the `@caido/sdk-client` package. Caido deliberately chose Skills over MCP because Skills give finer-grained context control and lower token use; rez0 reports finding **15 vulnerabilities in 6 weeks (mostly High/Critical)** using the Caido Skill plus his hackbot.

There is no official Caido MCP server, but the community has produced `c0tton-fluff/caido-mcp-server` (Go-based, 42 tools, OAuth/PAT auth, header redaction for credential safety, RFC 6265 cookie jar). PortSwigger's official **Burp MCP Server** (released April 3, 2025, github.com/PortSwigger/mcp-server) is mature and works on Burp Community Edition, but the consensus from CTBB-side hunters is that Caido Skills give better agent control because Caido is fully drivable by GraphQL SDKs while Burp's MCP requires the Java extension shim.

**JXScout is not an AI tool, but it is the preprocessing layer that makes AI useful.** The pattern hunters publicly report (Critical Thinking HackerNotes Ep. 147, rez0's blog) is: JXScout produces a clean folder of beautified JS in `~/.jxscout/<project>/` → point Claude Code at the folder → ask for endpoint extraction, IDOR candidates, sensitive sinks, postMessage handlers, and `dangerouslySetInnerHTML`/`innerHTML` flows. Pro tier adds shipped agent skills.

**HackerOne Hai is platform-side and primarily for triagers**, not hunters. Its components — Hai Chat, Hai Insight Agent (claims 20→5 minute validation time reduction), Triage, Prioritization Agent, Agentic Validation, Report Assistant — are built into the H1 platform with an API for embedding (`hackerone.com/blog/introducing-hackerones-hai-api`). "Hai for Hackers" launched June 11, 2025, with a closed cohort of 100 hackers and is largely a report-drafting assistant. "H1 Brain" is community shorthand, not an official product. Community concerns are real: **540% increase in valid prompt-injection reports and 210% increase in valid AI-vuln reports in 2025** has flooded triagers with AI slop, Daniel Stenberg of curl has been publicly hostile, and the early-2026 HackerOne Section 3.1 controversy (covered in CTBB Ep. 161+) over AI training on submitted reports has not fully settled. **Bugcrowd's AI is buyer-side**: AI Connect (read-only MCP server exposing program data to enterprise AI stacks, GA Q4 2025), AI Triage Assistant, AI Analytics — none hunter-facing. Their "Inside the Mind of a Hacker 2025" report shows 82% of surveyed hackers used GenAI in their workflows in 2025, but Bugcrowd's CAIO David Brumley publicly bans AI in parts of his CMU classes with the line *"if you don't know the basics, you won't know when the AI is lying to you."*

The use cases that **actually work**, per CTBB, NahamSec, Wiz Bug Bounty Masterclass, and rez0's blog, are narrow but high-leverage. JS bundle deobfuscation and endpoint extraction is the strongest signal — beautify with JXScout/prettier, then ask Claude Code to enumerate every `fetch`/`axios`/`XHR` call with its method, path, and inferred role. OpenAPI spec analysis (pull `/openapi.json` or Swagger and ask "what's not authenticated, what looks privileged, what's IDOR-prone") is high signal. Custom wordlist generation tailored to the target's tech stack, payload generation tailored to discovered tech (SSTI for Jinja2, GraphQL probes for Apollo), report writing for impact narrative, threat modeling, and protobuf encoding/decoding (CTBB Ep. 165) are all reportedly time-saving. Self-improving `CLAUDE.md` loops where the model writes lessons learned back into the project context demonstrably reduce token burn over time. Source-code review of leaked repos via vulnhuntr (protectai/vulnhuntr — LLM-driven Python source analysis with whole-call-chain context) hits 78% true-positive rate on IDOR per Semgrep's 2025 evaluation, but with high false-positive noise.

What **doesn't work** is equally clear. Black-box autonomous "find me bugs" without scoping produces slop; Wiz's internal study showed agents drop sharply when given broad multi-target scope. When Claude declares a "CRITICAL FINDING," CTBB hunters report a **~20% true-positive rate** — XBOW reached the top of the US H1 leaderboard in 2025 specifically because they paired LLM exploration with **deterministic, non-AI validators** that re-run findings before claiming them, and most public tooling lacks this layer. Semgrep's 2025 study documented Codex producing 0% TPR on XSS and false-positive rates of 53–95% depending on vuln class, with complete non-determinism between runs. End-to-end SSRF discovery via LLM hallucinates plausible-but-non-existent SSRF surface in JS bundles. *"AI acting as an echo chamber and amplifier for individuals that believe they might be onto something, luring them into a downwards spiral of confirmation bias"* — Inti De Ceukelaire's framing is the right mental model.

The **context engineering patterns** that work follow Joseph Thacker's "AI Hackbots, Part 1" essay: prime the system prompt with related research vocabulary (for SSRF, terms like "URL parser confusion, redirect chains, metadata service IPs, DNS rebinding, gopher://, IPv6 zero-suppression"); micro-scope agents (don't build "a SQLi bot," build separate error/blind/union agents with their own context packs); use clean RAG (normalize bug bounty writeups to a consistent schema before feeding); separate hunter and validator agents where the validator gets evidence-only and no attack-chain context; and for JS-bundle-to-IDOR specifically, provide the beautified bundle + the user's known authenticated routes from Caido proxy history + an explicit instruction to map every fetch/axios call to API path + method + classify each as public/authenticated/admin based on naming and visible role checks + flag endpoints taking a numeric or UUID identifier with no visible role check. Use Caido's progressive-disclosure Skills format (~100 tokens per skill name+description, full SKILL.md only on invoke) rather than dumping full program rules into every subagent.

For **sensitive engagements**, a working local-only path exists: **Caido + Shift + Ollama** (Llama 3.1 70B or Qwen 2.5 Coder 32B) with Shift configured against an OpenAI-compatible endpoint at `localhost:11434/v1/chat/completions`. Scott Murray's 2026-02-13 writeup demonstrates working SQLi exploitation on Juice Shop with this exact stack. The trade-off is reasoning quality on multi-hop chains, but it eliminates the compliance issue of sending program data to Anthropic/OpenAI. Disable Anthropic training in account settings before feeding any program data.

---

## 4. From recon to exploitation to chaining

Your pipeline ends at `findings`, which is the wrong place to stop for HIGH/CRITICAL severity work. The phases that convert P3s into P1s are **vulnerability assessment**, **chain hunting**, and **report craft** — and each has its own tooling and discipline.

The vulnerability assessment phase begins with **tech fingerprinting per host** (httpx `-tech-detect`, Wappalyzer, Nuclei `-tags tech`) which drives template selection, then **auth boundary mapping** (the multi-account setup from Section 2), then a systematic **endpoint inventory per host** combining katana crawl + JS extraction (JSluice, xnLinkFinder) + Wayback (gau) + GraphQL introspection. Every endpoint then runs through the BAC/IDOR matrix in Burp/Caido with role differentials enforced by Autorize (binary admin/user), AuthMatrix (≥3 roles), or Auth Analyzer (multi-tenant Bearer tokens), with **Param Miner** firing on cacheable origins and **JWT Editor** + `jwt_tool` firing on any JWT-bearing request.

For **BAC/IDOR exploitation specifically**, the matrix you should run on every authenticated request is: replay with User-B cookie (horizontal); replay without auth (broken); replay with admin verb GET→PUT/DELETE (verb tampering); add `?id=2&id=1` and `[id]=1` array (param pollution); add `isAdmin`, `role`, `verified`, `tenant_id`, `permissions[]` (mass assignment); swap UUID with one leaked from referrers/Wayback/OAuth/GitHub/screenshots; if UUIDv1, run the time-sandwich attack (decode the version digit, generate UUIDs adjacent to the victim's action, brute the gap with `Cyberretta/UUIDv1_Timestamps_Generator`); test sequential numeric IDs ±10000; swap `/me/` for `/USERID/` (Sam Curry's "secondary context" attack — the Starbucks `app.starbucks.com/bff/proxy/...` reverse-proxy traversal hit internal Microsoft Graph and exposed ~100M records); swap `X-Tenant-ID`/`X-Org-ID`/`X-Account-ID` headers; test nested-JSON `eventID`/`ownerId` mismatches; try `X-HTTP-Method-Override: PUT`; HEAD requests against admin endpoints (HEAD often skips body-reading auth filters); and for GraphQL, hit the `node(id:"...")` and `nodes` root fields directly while using aliases (`q1: user(id:1) q2: user(id:2)`) to bypass rate limits.

For **SSRF**, every URL-like parameter (`url`, `target`, `redirect`, `webhook_url`, `image_url`, `feed`, `callback`, `next`, `proxy_url`, `import_from`) gets the cloud-metadata test set: AWS IMDSv1 `169.254.169.254/latest/meta-data/` and IMDSv2 with controllable headers/methods (Yassine Aboukir's Atlassian Gadgets pattern); GCP `metadata.google.internal/computeMetadata/v1/` with `Metadata-Flavor: Google`; Azure `169.254.169.254/metadata/instance?api-version=2021-02-01` with `Metadata: true`. F5 Labs' March 2025 analysis confirms ~93% of EC2 instances still don't enforce IMDSv2, so the legacy path is far from dead. Add `gopher://` (Gopherus for Redis CONFIG SET → SSH key write), `file://`, `dict://`, and Java's `jar:`/`netdoc:` schemes when `http://` is filtered. Use DNS rebinding (Singularity, rebind.it, `lock.cmpxchg8b.com`) when the app re-resolves on the actual fetch. Always pair with `interactsh` or Burp Collaborator for blind detection; common SSRF sources are PDF generators, screenshot services, link previews, webhook destinations, profile-image-from-URL fetchers, and OAuth `redirect_uri` validators. Orange Tsai's URL-parser-inconsistency research (`http://evil.com#@169.254.169.254/`, `http://169.254.169.254\\@evil.com/`, IDN encoding, decimal-encoded IPs `2852039166`) is still the canonical bypass library.

The chain pattern catalog for HIGH/CRITICAL impact, with at least one disclosed example each:

**Subdomain takeover → cookie scoping → session hijack** is HackerOne #219205 (Arne Swinnen / Uber `saostatic.uber.com`): take over the dangling resource, host JS that reads `Domain=.uber.com` SSO cookies, victim visits the takenover subdomain, exfil cookies. Prereqs: cookie not host-only, subdomain in scope, ability to claim the dangling service.

**Open redirect → OAuth token theft** is HackerOne #202781 (Uber, $7,500 chained): permissive `redirect_uri` + `next_url` + `login.uber.com/logout` open redirect → leaked Facebook OAuth token. Twitter Critical #131202 (Microsoft Outlook OAuth misconfig) and pixiv #1861974 ($2,000 path traversal in `redirect_uri`) are sibling patterns. Prereqs: missing/unenforced `state`, weak `redirect_uri` validation, or open redirect on a whitelisted origin.

**IDOR on UUIDv1 → enumeration via timestamp leak** ("sandwich attack") is documented by Realize Security and IBM PTC Security: app uses UUIDv1 for password-reset/share-link tokens; attacker triggers tokens before and after victim's action; timestamps and node MAC extracted from any leaked UUIDv1; brute the gap. Prereqs: confirm version digit `1xxx` in the third group of a sample token, attacker can generate adjacent tokens.

**Self-stored XSS + IDOR → account takeover** — your specific case — has multiple disclosed templates. Jefferson Gonzales's HackerEarth report wrote XSS payloads into other users' profiles via `/api/sprint/v1/setup-profile/` accepting an `email` parameter without ownership check; Codii's email-template editor had outer `eventID` auth-checked and inner JSON `eventID` not checked, delivering stored XSS to all users via numeric IDs; HackerOne #632017 (Eternal/Zomato) chained self-stored XSS with WAF bypass and login/logout CSRF for ATO via stolen FB/Google OAuth tokens; #892289 (Imgur) used self-XSS + clickjacking. Prereqs: a profile/template field reflects unsanitized input, an authenticated write endpoint accepts a `userId`/`email`/`templateId` parameter without ownership check.

**SSRF → cloud metadata → AWS/GCP credentials → privesc** is Capital One 2019 (canonical), the Fortinet 2024–25 Grafana CVE-2020-13379 mass-exploit harvesting AWS keys, Yassine Aboukir's Atlassian gadgets `gadgets.io.makeRequest()` SSRF with controllable HTTP method/headers → IMDSv2 token PUT → creds exfil, and Sam Curry et al's Apple iCloud "Open in Pages" SSRF reaching internal AWS env (samcurry.net/hacking-apple). Prereqs: SSRF with arbitrary host (or DNS-rebind), IMDSv1 or controllable headers for IMDSv2, over-permissioned IAM role attached to instance.

**CORS misconfig + sensitive endpoint → data exfiltration** is HackerOne #426147 (X / niche.co — `//niche.co` substring match with `Access-Control-Allow-Credentials: true` → ATO), with siblings at #1707616 (Yelp), #758785 (Nord Security), #1199527 (UPchieve). Prereqs: credentials-true CORS flaw + session-authenticated JSON endpoint + victim logged in.

**JWT misconfig → privilege escalation** spans `alg: none` (still works on many libs), RS256→HS256 algorithm confusion (sign HS256 with the server's public key from `/.well-known/jwks.json`), `kid` injection (path traversal `kid:"../../../../dev/null"`, SQLi in DB-backed lookups, file-pointing as in Ishara Abeythissa's writeup with `kid` pointing to `localhost:7070/privKey.key`), `jku`/`x5u` SSRF spoofing, `jwk` injection embedding attacker public key in token header, and ECDSA `r=0,s=0` Psychic Signatures (CVE-2022-21449) on un-patched Java. Prereqs: app doesn't pin algorithm; lib accepts `none`; reachable JWKS endpoint.

**Cache poisoning + auth/header reflection → mass session theft** follows James Kettle's "Practical Web Cache Poisoning" and "Web Cache Entanglement" papers: unkeyed header (`X-Forwarded-Host`, `X-Forwarded-Scheme`) reflected into JS/HTML, poison shared cache, all users get attacker payload. ladunca's research yielded 70+ cache-poisoning bugs across Apache Traffic Server, GitHub, GitLab, HackerOne, Cloudflare with $40k bounty. Prereqs: cacheable response, unkeyed input reflected, repeatable response.

**HTTP request smuggling chains** include HackerOne #737140 (Slack mass cookie theft via CL.TE on slackb.com), #771666 (Eternal/Zomato Akamai desync → bulk X-Access-Token theft), and the New Relic login.newrelic.com smuggling for password theft ($3,000). Tooling is `defparam/Smuggler`, Burp HTTP Request Smuggler, and Turbo Intruder's `smuggle attack` modes.

**Dependency confusion** is Alex Birsan's 2021 work that hit Apple, Microsoft, PayPal, Tesla, Uber, Yelp, Netflix, Shopify ($30k each, $130k+ total) by publishing higher-version public packages with names matching internal ones. Landh.tech's 2025 Netflix dependency confusion via Assetnote/Depi recon proves the pattern is alive. Prereqs: internal name discoverable in JS/`package.json`/error messages; build system using `--extra-index-url` or default registry resolution; program permits the test.

**SSO misconfig + IDOR → cross-tenant ATO** is the **nOAuth pattern** documented by Descope (June 2023, $75k bounty pool): Microsoft Entra ID OAuth apps key user lookup on the email claim, but a Microsoft tenant admin can set arbitrary unverified email values on a user, so "Sign in with Microsoft" produces full ATO at any vulnerable SaaS. Microsoft mitigated with the `xms_edov` claim and `RemoveUnverifiedEmailClaim`. Sam Curry's BMW/Rolls-Royce SSO compromise → access any employee app as any employee is a sibling pattern, and AppOmni Labs documented Okta SSO compromise via path-traversal API + IDOR + hardcoded service account → 200k user read/write. Prereqs: SaaS using social/OIDC login that trusts mutable email without verification flag.

The **report craft** layer is where Bugcrowd specifically rewards or punishes you. Bugcrowd's VRT (Vulnerability Rating Taxonomy) v1.11 expanded IDOR variants with explicit P1 for "Read PII via Iterable Object Identifiers," P2 "Modify/Delete Sensitive – Iterable," P2 "Read PII – GUID/Complex," P3 "Modify/Delete – GUID/Complex," P4 "Read Sensitive – GUID/Complex" — meaning **GUID-based IDORs still pay P4 on Bugcrowd**, just less. Pre-pick the VRT entry before writing the report and quote it explicitly: *"VRT: Insecure Direct Object References → Read Personal Data (PII) → Iterable Object Identifiers — P1."* Reports that land share a pattern: **a title that sells impact in one line** ("Stored XSS in user profile leading to ATO via session hijacking on app.target.com," not "XSS vulnerability"); a 30-second executive summary; numbered copy-pasteable repro with curl commands and test creds; a demonstrated-impact section that explicitly states business consequence (PII exposure to N users, financial theft path, GDPR/HIPAA implications); a 60–120 second OBS video PoC for chained or hard-to-believe issues; explicit chain narration ("Bug A P4 + Bug B P3 → P1 because…") to pre-empt the triager splitting your chain into two P3s; and a custom CVSS string when the chain crosses a tenant or scope boundary (`CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:N` — the `S:C` for changed scope is high-leverage). Reports get downgraded for self-XSS without chain, IDOR with UUIDv4 and no leak path, CORS reflection without `Access-Control-Allow-Credentials: true`, open redirect alone (P4 by VRT 1.4), missing repro for race/timing issues, and theoretical impact without PoC.

---

## 5. Concrete additions, AI touchpoints, and the refactored tree

Here is the consolidated workflow in the form your README currently uses.

```
phase0_scope:
  - bbscope poll bc          # Bugcrowd scope automation + change tracking
  - hacker-scoper            # Filter all subsequent output against parsed scope

phase1_passive:
  - kaeferjaeger SNI ranges
  - Censys/Shodan favicon-hash + cert.subject.CN pivots
  - smap
  - subfinder OR bbot subdomain-enum (CHOOSE ONE)
  - github-search + trufflehog --org + noseyparker      # NEW: GitHub/GitLab dorking
  - postleaks / postmaniac / trufflehog postman         # NEW: Postman OSINT

phase2_subdomains:
  - alterx -enrich           # REPLACES altdns + dnsgen
  - puredns resolve          # NEW: wildcard-aware resolution
  - dnsx -ptr -cname -asn    # KEEP for enrichment only

phase2.1_network_active:
  - asnmap → mapcidr
  - naabu
  - dnsx -ptr on resolved CIDRs

phase3_surface:
  - httpx (with -tech-detect)
  - gowitness (or httpx -screenshot)
  - cdncheck + tlsx          # NEW: fingerprint CDN/WAF before fuzzing

priority_hosts:
  # Score: +5 admin/internal/portal/dashboard, +5 payment/billing/api,
  # +3 multi-tenant indicators, +3 SSO redirect target, +2 non-standard port,
  # -5 WAF cookie-cutter response

phase3.5_authenticated:        # NEW PHASE
  - Create 3 accounts × 2 tenants where permitted
  - PwnFox + Firefox containers for cookie isolation
  - Caido Sessions / Burp session handlers for auto-token-refresh
  - Document IDs, slugs, role markers per account

phase4_content:
  - katana (active crawl)              # NEW: replaces bbot spider
  - gau                                # KEEP — drop waybackurls + paramspider
  - JXScout daemon + jxscout-caido     # NEW: JS preprocessing layer
  - getJS / subjs → JSluice            # REPLACES linkfinder
  - js-snitch                          # NEW: Trufflehog+Semgrep on JS bundles
  - ffuf (priority hosts only)

phase5_params:
  - gau --subs | grep '=' | unfurl keys     # REPLACES paramspider
  - arjun (priority hosts only)
  - Param Miner (Burp/Caido extension)       # NEW

phase5.5_misconfig_sweep:                    # NEW PHASE
  - nuclei -tags exposure,panel,config,token,takeover,cve \
           -severity medium,high,critical -rl 50
  - subdomain takeover: subzy + nuclei -t takeovers/ + dnsReaper + BadDNS
  - cloud_enum + S3Scanner + goblob + MicroBurst on brand permutations
  - custom Nuclei templates for target-specific signatures

phase6_feature_map:
  - Manual product use as each role for ≥30 minutes (Douglas Day discipline)
  - Document: auth model, multi-tenancy model, RBAC roles, ID formats,
    "points where the app says no", invite/share/export functions
  - JXScout output → Claude Code (via Caido Skill) for endpoint inventory + IDOR candidates

phase7_assessment:                           # NEW PHASE
  - Autorize / AuthMatrix / Auth Analyzer (binary, matrix, multi-tenant)
  - BAC/IDOR matrix on every authenticated request (Section 4)
  - JWT Editor + jwt_tool on every JWT
  - SAML Raider on every SAML flow
  - OAuth fuzzing: redirect_uri, state, response_type
  - Param Miner cache-poisoning sweep on cacheable origins
  - Mobile: jadx → apkleaks → MobSF → re-feed endpoints into AuthMatrix

phase8_chain_hunt:                           # NEW PHASE
  - Match each found low-impact bug against chain catalog (Section 4)
  - Hunt the chain partner before reporting
  - Validator-agent re-runs every Claude-flagged finding via curl

findings:
  - gf patterns
  - Bugcrowd VRT-aware report drafts
  - PoC video, impact narrative, chain narration
```

The **ten concrete changes** in priority order: (1) drop `waybackurls`, `paramspider`, `altdns`, `dnsgen`, `linkfinder` and add `gau`-only, `alterx`, `puredns`, `JSluice`; (2) add `bbscope` for Bugcrowd scope automation and change tracking; (3) insert a `phase3.5_authenticated` phase with multi-account/multi-tenant setup before any feature mapping; (4) add `JXScout` + `jxscout-caido` as the JS preprocessing layer feeding both VS Code and AI agents; (5) add `phase5.5_misconfig_sweep` running Nuclei with `exposure,panel,config,token,takeover,cve` tags plus subdomain takeover and cloud enumeration; (6) add `phase7_assessment` with Autorize/AuthMatrix/Auth Analyzer, JWT Editor + `jwt_tool`, SAML Raider, Param Miner cache-poisoning, and mobile APK pipeline; (7) add `phase8_chain_hunt` matching findings against the chain catalog before reporting; (8) build a personal **custom Nuclei template library** for target-specific signatures (this is where unique edge lives); (9) make GitHub/GitLab dorking and Postman OSINT first-class citizens of phase 1, not afterthoughts; (10) adopt VRT-aware report drafts that pre-pick the exact VRT entry and quote it in the submission.

The **five AI touchpoints** that add value rather than theatre: (1) **install the official Caido Skill for Claude Code** (caido.io/blog/2026-03-06-caido-skill, github.com/caido/skills) — generated PAT, native skills install — and use it for HTTPQL query generation, replay tab orchestration, and match-and-replace synthesis; this is the highest-leverage AI integration available today and the one most aligned with your manual-analysis-with-assistance philosophy; (2) **JXScout → Claude Code for JS bundle analysis**, where JXScout produces the clean folder and Claude reads it with a prompt that includes your Caido proxy history and asks specifically for endpoint mapping, role classification, and IDOR/SSRF candidates with `EXPR` placeholders flagged as injection targets — this is the use case CTBB hunters publicly cite as their #1 force multiplier; (3) **Shift inside Caido for wordlist generation and natural-language Replay modification** when you've fingerprinted the tech stack but lack a target-specific wordlist; bring your own API key (Anthropic preferred for code reasoning, or local Ollama for sensitive engagements); (4) **a separate Validator agent in your `/hunt` workflow** that re-runs every Claude-flagged finding via curl-only with no attack-chain context — this addresses the 20% TPR problem and is the architecture XBOW used to reach the H1 leaderboard; (5) **report writing for impact narrative**, where Claude takes your repro steps + VRT entry + observed business consequence and drafts the executive summary and chain narration in Bugcrowd's submission format. **Skip**: black-box autonomous "find me bugs" agents, generic LLM XSS scanning, and any "agentic continuous AI pentesting" SaaS without a disclosed deterministic-validator architecture.

## Closing perspective

Your pipeline's structure is correct — passive → resolution → surface → priority → content → params → mapping → findings is the same skeleton six2dez, NahamSec, and Jason Haddix run. The deltas are not architectural; they are **substitution of obsolete tools, insertion of three missing phases (authenticated recon, misconfig sweep, vulnerability assessment), and the addition of a chain-hunting discipline that converts the low-hanging fruit your recon already finds into the P1/P2 reports that Bugcrowd actually pays for**. The AI layer accelerates specific tasks — JS bundle comprehension, wordlist generation, report drafting — but it does not replace the multi-account manual feature mapping that Douglas Day, Joel Margolis, and Sam Curry all cite as their actual differentiator. The hunters at the top of public Bugcrowd leaderboards in 2026 are running a smaller toolset than yours, deeper authenticated workflows, and a tighter chain-hunting loop. Match those three properties, layer Caido + Claude Code on the cognitive parts that benefit most, and your pipeline will be aligned with the actual frontier of public-program bug bounty work.

phase0: bbscope                          # scope tracking on Bugcrowd
phase1: subfinder | trufflehog org | postman OSINT | censys/smap | kaeferjaeger
phase2: alterx (only if sub count thin) | puredns | dnsx -ptr -cname
phase3: naabu (light, web ports) | httpx -tech-detect | gowitness
priority_hosts: manual screenshot review, scoring
phase3.5: 3 accounts × 2 tenants | PwnFox | Caido session handlers
phase4: gau (ID/URL samples, leaked tokens in URLs) | JXScout daemon |
        JSluice on the bundle folder
phase5: arjun once on top priority host (optional)
phase5.5: nuclei -tags exposure,token,takeover -severity high,critical
          subzy on resolved subs
phase6: manual feature mapping, ≥30 min per role × per tenant
phase7: pick ONE of Autorize / AuthMatrix / Auth Analyzer based on app shape |
        JWT Editor + jwt_tool when JWT present |
        APK pipeline (jadx + apkleaks) when mobile in scope |
        BAC/IDOR matrix manually applied to every authed request
phase8: chain match against catalog | report