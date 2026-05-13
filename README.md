# web_hacking

Personal reconnaissance + vulnerability assessment framework for **Bugcrowd public BBPs**, focused on **broken access control, IDOR, server misconfigurations, and SSRF**.

Linear, phased pipeline where each stage consumes the previous stage's output directly. **Intentionally semi-automated** — chaining outputs manually surfaces infrastructure insights and BAC opportunities that fully automated pipelines miss.

Tools are deliberately minimized. Any tool that can't be drawn in two steps from "tool runs" to "manually-inspectable artifact pointing at a BAC-class bug" is excluded. See `obsidian/notes_archive/bb-workflow refact.md` for the full reasoning on each tooling decision.

For the full dataflow notes and per-phase commands, open `/obsidian/dataflow_recon/` in Obsidian.

---

## reconnaissance dataflow

<img src="assets/dataflow_graph.png">

---

## directory structure

```
engagements/
└── target_com/
    ├── scope.txt
    ├── asns.txt                          (optional — only if IP/ASN scope present)
    │
    ├── phase1_passive/
    │   ├── subdomains_raw.txt            (subfinder)
    │   ├── cloud_hosts.txt               (kaeferjaeger SSL snapshots)
    │   ├── smap_results.txt
    │   ├── censys_hosts.txt              (optional)
    │   ├── sonar_rdns.txt                (optional — IP scope only)
    │   └── github_secrets.txt            (trufflehog github)
    │
    ├── phase2_subdomains/
    │   ├── subdomains_merged.txt
    │   ├── subdomains_resolved.txt       (puredns)
    │   └── permutations.txt              (alterx — conditional)
    │
    ├── phase2.1_network_active/          (only when IP scope present)
    │   ├── asnmap_ranges.txt
    │   ├── naabu_live_ports.txt
    │   └── ip_no_dns.txt
    │
    ├── phase3_surface/
    │   ├── all_hosts.txt
    │   ├── live_hosts.csv                (httpx -tech-detect)
    │   └── screenshots/                  (gowitness)
    │
    ├── priority_hosts.txt                (manual triage from checkpoint 1)
    │
    ├── phase3.5_auth/                    NEW
    │   ├── auth_accounts.md              (account roster, seed IDs per role)
    │   └── (tokens live in ~/.bbp_creds/<target>.env — never in repo)
    │
    ├── phase4_content/
    │   ├── historical_urls.txt           (gau — replaces waybackurls + paramspider)
    │   ├── js_endpoints.txt              (jsluice — replaces linkfinder)
    │   ├── all_urls.txt
    │   └── (JXScout cache lives in ~/.jxscout/<target>/)
    │
    ├── phase5_params/
    │   ├── params_passive.txt            (unfurl on gau output)
    │   ├── arjun_raw.txt                 (optional, top priority host only)
    │   ├── api_endpoints.txt
    │   ├── openapi_specs/
    │   ├── graphql_schema.json
    │   ├── js_post_params.txt            (SSRF surface from JXScout bundles)
    │   ├── wellknown_findings.txt
    │   └── interesting/
    │       ├── gf_ssrf.txt
    │       └── gf_redirect.txt
    │
    ├── phase5.5_misconfig/               NEW
    │   ├── nuclei_findings.txt           (tag-restricted: exposure,token,takeover)
    │   ├── subzy_takeovers.txt
    │   └── cloud_enum_results.txt
    │
    ├── feature_map.md                    (manual, ≥30 min per role per tenant)
    ├── threat_model.md
    │
    ├── phase7_assessment/                NEW
    │   ├── bac_findings.md
    │   ├── jwt_findings.md               (when JWT in use)
    │   └── saml_findings.md              (when SAML in scope)
    │
    ├── phase8_chains/                    NEW
    │   └── chain_findings.md             (P3+P3 → P1 candidates)
    │
    └── findings/
        ├── ssrf/
        ├── idor/
        └── access_control/
```

---

## the BAC-focused phase flow

```
phase 0  scope          bbscope, manual brief review
phase 1  passive        subfinder, kaeferjaeger, trufflehog (github + postman), smap
phase 2  subdomains     puredns + alterx (conditional)
phase 2.1 network       naabu + asnmap (only if IP/ASN scope)
phase 3  surface        httpx -tech-detect, gowitness
─── checkpoint 1: manual screenshot review + priority scoring ───
phase 3.5 auth          3 accounts × 2 tenants, PwnFox, Caido sessions      [NEW]
phase 4  content        gau + JXScout + jsluice
phase 5  params/api     unfurl, arjun (optional), openapi/graphql probe, mobile APK
phase 5.5 misconfig     nuclei tag-restricted, subzy, cloud_enum            [NEW]
phase 6  feature map    manual ≥30 min per role × per tenant (Douglas Day)
phase 7  BAC assessment Autorize/AuthMatrix/Auth Analyzer + BAC matrix      [NEW]
phase 8  chain hunt     match against catalog, chain low → critical         [NEW]
findings → Bugcrowd report with VRT pre-pick + chain narration
```

---

## what changed in this refactor

**dropped** (no longer in pipeline):
- `waybackurls` — `gau` is a strict superset
- `paramspider` — duplicates `gau` Wayback queries; replaced by `gau | unfurl keys`
- `altdns`, `dnsgen` — obsolete patterns; `alterx -enrich` replaces both
- `linkfinder` — regex; replaced by `jsluice` (AST-based, follows fetch/XHR flows)
- `ffuf` directory bruteforce — modern SaaS surface lives in JS, not at `/admin` `/backup.zip`
- `katana` — SPA crawler returns static index; JXScout actually reaches the routes
- `kiterunner` — for BAC focus, leaked openapi/swagger > API wordlist
- `bbot` (when run alongside the piecemeal tools — pick one mode)
- `Param Miner` — cache-poisoning/host-header tool; wrong target for BAC focus

**added**:
- `bbscope` — Bugcrowd-native scope tracking
- `trufflehog github + postman` — first-class secret discovery
- `puredns` — wildcard-aware DNS resolution (replaces raw massdns/dnsx)
- `alterx` — modern target-aware subdomain permutations
- `JXScout` + `jxscout-caido` plugin — JS preprocessing layer (the AI-consumable folder)
- `jsluice` — AST-based JS endpoint + secret extraction
- `nuclei` with tight tags (`-tags exposure,token,takeover -severity high,critical`)
- `subzy` + `nuclei takeovers/` for subdomain takeover detection
- `cloud_enum` for AWS/Azure/GCS misconfig
- Caido auth-differential plugins (Autorize port, AuthMatrix port, Auth Analyzer)
- `jwt_tool`, `JWT Editor` (Caido extension)

**new phases**:
- **3.5 authenticated recon** — multi-account, multi-tenant. without this phase, no BAC testing happens
- **5.5 misconfig sweep** — runs in background during phase 6/7, doesn't pull focus
- **7 BAC/IDOR assessment** — auth-differential tools + 20-row BAC matrix applied manually
- **8 chain hunt** — match findings against chain catalog before reporting (turns P3+P3 into P1)

---

## AI integration touchpoints

Five high-leverage AI touchpoints. Each adds measurable value; everything else is theatre.

1. **Caido Skill for Claude Code** (caido.io/blog/2026-03-06-caido-skill) — HTTPQL queries, replay orchestration, match-and-replace synthesis. Highest-leverage available today
2. **JXScout → Claude Code for JS bundle analysis** — point Claude at `~/.jxscout/<target>/` with explicit prompt: enumerate every fetch/axios/XHR call, infer method + path + role, flag UUID/numeric ID params with no visible role check
3. **Shift inside Caido** for wordlist generation + natural-language Replay modification. Bring-your-own API key (Anthropic preferred for code reasoning, or local Ollama for sensitive engagements)
4. **Separate validator agent** in any `/hunt` workflow — re-runs every Claude-flagged finding via curl-only with no attack-chain context. Addresses the ~20% false-positive rate problem (XBOW's H1 leaderboard architecture)
5. **Report drafting** — Claude takes repro steps + VRT entry + observed business consequence and drafts the executive summary + chain narration in Bugcrowd's submission format

**Skip**: black-box autonomous "find me bugs" agents, generic LLM XSS scanning, any "agentic continuous AI pentesting" SaaS without disclosed deterministic-validator architecture, HackerOne Hai for hunters (it's primarily a triager-side product).

---

## kali docker

Kali Linux container. Good for using clouds as infrastructure and fuzzing with clusters. Container does NOT run JXScout — that daemon runs on the host alongside Caido.

**setup**

```bash
cd kali-docker
chmod +x run.sh
./run.sh
```

**re-attaching**

```bash
docker start kali && docker attach kali
```

See `kali-docker/tools` for the current required tool list.
