## What this repo is

Automates Dealertrack (DTN) developer workstation setup on Windows. The main artifact is `setup.bat`, a batch script that configures IIS, clones repos, installs tools, and copies config files. It supposed eventually to replace a SharePoint document as the single source of truth.

**Repo:** hosted at `vit100-trader/dev-workstation-setup` on GitHub.

## Repo structure

```
setup.bat                 — Main setup script (run as Administrator)
README.md                 — User-facing docs and post-setup instructions
iis/apppools.xml          — IIS application pool definitions (imported via appcmd)
iis/sites.xml             — IIS site definitions (imported via appcmd)
dotnet/machine.config_*   — Three machine.config variants (v2.0 32/64-bit, v4.0 32-bit)
oracle/tnsnames.ora       — Oracle TNS names config
oracle/sqlDeveloperConnections.json — SQL Developer connection export
oracle/win32_11gR2_client.zip      — 32-bit Oracle client installer (Git LFS)
oracle/win64_11gR2_client.zip      — 64-bit Oracle client installer (Git LFS)
wwwroot/wwwroot.zip       — Static wwwroot content for IIS (Git LFS, ~1.77 GB)
Tools/PdfUploadTool.zip   — PDF Upload Tool archive
Tools/PostingTool.zip     — XML Posting Tool archive
hosts/hosts-additions.txt — Extra entries appended to Windows hosts file
vpn/README.md             — VPN setup notes
```

## Key conventions

### setup.bat design principles
- **Idempotent:** Every step checks whether its work is already done before acting. The script can be re-run safely.
- **Ordered steps:** Steps are numbered and run sequentially. Some depend on earlier steps (e.g., IIS must be enabled before importing app pools/sites).
- **Admin required:** The script exits immediately if not run as Administrator.
- **winget optional:** If `winget` is missing, the script warns and skips auto-installs (Git, Git LFS, AWS VPN) but continues with everything else.
- **Error counter:** Failures increment `ERRORS`; the summary at the end reports the count.

### Git LFS
Three large files are tracked via Git LFS (see `.gitattributes`). If they appear as small pointer files, the user needs to run `git lfs pull`.

### Hardcoded paths
These paths are baked into `setup.bat` and/or `iis/sites.xml`. Changing them requires updating both places:
- `C:\dtnsourcecode` — all source repos live here; `sites.xml` references this path
- `C:\tools` — added to system PATH; receives `nuget.exe`, PdfUploadTool, PostingTool
- `C:\Oracle\product\11.2.0\client_1` — expected Oracle client install location (`ORA_DIR` in setup.bat)
- `C:\inetpub\wwwroot` — destination for wwwroot.zip extraction

### IIS config files
- `iis/sites.xml` contains physical paths pointing to `C:\dtnsourcecode\<RepoName>` and `C:\inetpub\wwwroot\DTCanada\...`. Any repo rename or path change must be reflected here.
- `iis/apppools.xml` defines all application pools. Pools are imported with `appcmd add apppool /in`.

## How to test changes

There is no automated test suite. To verify changes:

1. **Read through setup.bat** — confirm idempotency (each step checks before acting) and that step numbering stays consistent.
2. **Dry-run review** — trace the batch logic for both first-run and re-run scenarios.
3. **On a real machine** — run `setup.bat` as Administrator on a clean Windows Pro/Enterprise box. Re-run it to confirm idempotency (all steps should report "already exists/installed/configured").
4. **IIS config changes** — after editing `apppools.xml` or `sites.xml`, import them with `appcmd` on a test machine and verify sites load in IIS Manager.

## Known open item

LSA paths in `sites.xml` currently point to `C:\inetpub\wwwroot\DTCanada\LSA\...`. Some devs may run LSA from source at `C:\dtnsourcecode\DTN.ProgramManagement\...`. This may need updating depending on team workflow.

## Confluence reference

The companion wiki page is "Dealertrack Developer Workstation Setup" in the DE space (page ID `4212031615`). The page links back to this repo. For large Confluence edits, create a subpage rather than replacing the main page body via API (the update call replaces the entire body).
