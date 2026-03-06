# Dealertrack Developer Workstation Setup

Everything you need to set up a new DTN dev machine. Config files, installers, and an automated setup script — all in one place.

## Quick Start

Open a **Command Prompt as Administrator** (right-click > "Run as administrator"). All steps below should be run from this same Admin prompt.

```
winget install GitHub.GitLFS
```

Close and reopen your Admin command prompt (needed so Git picks up the newly installed LFS — otherwise `git lfs` fails with "lfs is not a git command"), then:

```
mkdir C:\dtnsourcecode
cd C:\dtnsourcecode
git lfs install
git clone https://github.com/vit100-trader/dev-workstation-setup.git
```

> **Note:** Git LFS is required — the repo contains large files (Oracle installers, wwwroot.zip) tracked via LFS. Cloning may take a while as it downloads ~3 GB of LFS content. The `winget` command above installs Git LFS. If `winget` is not available, download from https://git-lfs.com.

> **Important:** All repos must be cloned to `C:\dtnsourcecode`. The IIS sites config (`sites.xml`) has hardcoded physical paths pointing there. If you use a different location, you'll need to update `sites.xml` and re-import the IIS sites manually.

**Install Oracle client before running the script** — this way `tnsnames.ora` gets copied automatically on the first run:

1. Extract `dev-workstation-setup\oracle\win32_11gR2_client.zip` — the 32-bit client is the required one (`win64_11gR2_client.zip` is included just in case someone needs it)
2. Run `setup.exe` from the `client` folder (it may take up to 2 minutes for the setup screen to appear; try running as Administrator if nothing happens)
3. Select **Custom** as the installation type
4. On the language selection screen, leave defaults and click Next
5. Set **Oracle Base** to `C:\Oracle` — the software location will auto-fill as `C:\Oracle\product\11.2.0\client_1` (the script expects this exact path for copying `tnsnames.ora`)
6. Click Next through the remaining screens and let setup finish

See [screenshots on the wiki page](https://trader.atlassian.net/wiki/spaces/DE/pages/4212031615) for each step of the Oracle installer.

Then run the script:

```
cd dev-workstation-setup
setup.bat
```

The script handles: repo cloning, IIS features, app pools, sites, machine.config files, tnsnames.ora, hosts file, wwwroot extraction, `C:\tools` directory, PATH setup, PDF Upload Tool extraction, and Posting Tool extraction.

> **IIS:** The script enables IIS automatically via DISM (takes 5-10 minutes and may appear stuck at certain percentages — just let it run). This requires **Windows Pro or Enterprise** — Windows Home does not support IIS. After the script finishes, verify IIS is running by opening http://localhost in a browser. You should see the IIS Welcome page or one of the configured DTN sites. If the page doesn't load, open **IIS Manager** (`inetmgr`) and check that the sites and app pools are listed.

After the script finishes, follow the manual steps it prints out.

---

## What the Script Does

| Step | What happens |
|---|---|
| Create directories | `C:\dtnsourcecode` (source code) and `C:\tools` (standalone utilities like `nuget.exe` that need to be on PATH) |
| PATH | Adds `C:\tools` to system PATH so utilities placed there are available from any terminal |
| Clone repos | Clones all 48 repos from `tdr-dealertrack` to `C:\dtnsourcecode` (skips existing) |
| IIS + MSMQ | Enables IIS and MSMQ with all relevant features via DISM |
| App pools | Imports `iis/apppools.xml` via appcmd |
| Sites | Removes Default Web Site, imports `iis/sites.xml` |
| wwwroot | Extracts `wwwroot.zip` to `C:\inetpub\` |
| machine.config | Backs up originals (.bak), copies all 3 configs |
| tnsnames.ora | Copies to Oracle client dir (Oracle should already be installed per Quick Start) |
| hosts | Adds `localhostcgw` entry |
| NuGet | Downloads `nuget.exe` to `C:\tools` |
| PDF Upload Tool | Extracts `Tools/PdfUploadTool.zip` to `C:\tools\PdfUploadTool`. Uses aliases from `tnsnames.ora` for different environments |
| Posting Tool | Extracts `Tools/PostingTool.zip` to `C:\tools\PostingTool`. Emulates lender responses for deal submissions during development |

> **machine.config login:** After the script copies the `machine.config` files, open them and replace the `<loginid>` value with your own username. Two commented-out alternatives are also included: `auser8417` (automation testing user) and `dtcndevall` (DTN admin user) — uncomment one of these instead if needed for your scenario.

---

## Manual Steps

These can't be automated — do them after running the script.

### 1. PDF Upload Tool

The script extracts `PdfUploadTool.zip` to `C:\tools\PdfUploadTool`. Inside you'll find `32bits` and `64bits` folders. Use the **32-bit version** unless you know otherwise — the Oracle client is most likely 32-bit, and the tool's architecture must match.

### 2. Posting Tool

The script extracts `PostingTool.zip` to `C:\tools\PostingTool`. This tool emulates lender responses when submitting deals, so you don't have to wait for real lender replies during development. See the [DTN.XMLPostingTool repo](https://github.com/tdr-dealertrack/DTN.XMLPostingTool) for details, or ask QA or another dev for usage tips.

### 3. JFrog NuGet Source

`nuget.exe` is already in `C:\tools` (downloaded by the script). Now configure the JFrog feed:

1. Go to [JFrog](https://traderca.jfrog.io/ui/packages), sign in with SAML SSO
3. Generate API key (top-right > Edit Profile)
4. Run:

```
nuget source add -Name "dtncan-nuget-local" -Source "https://traderca.jfrog.io/artifactory/api/nuget/v3/dtncan-nuget-local" -Username YOUR_EMAIL -Password YOUR_API_KEY
```

### 4. VPN

See the [AWS VPN Transition to Okta](https://trader.atlassian.net/wiki/spaces/CLOUD/pages/4891476045/AWS+Client+VPN+Transition+to+AS24+Okta+Authentication) Confluence page.

1. Install [AWS VPN Client](https://aws.amazon.com/vpn/client-vpn-download/)
2. Download profiles from the [self-service portal](https://self-service.clientvpn.amazonaws.com/)
3. Import `.ovpn` files via File > Manage Profiles

### 5. Oracle SQL Developer

[Download](https://www.oracle.com/ca-en/database/sqldeveloper/technologies/download/) the Windows version with JDK included.

Pre-configured connections for DEV and QA are in `oracle/sqlDeveloperConnections.json`. Import via File > Import Connections, select the JSON file, and enter `123` when prompted for the decryption password.

### 6. Build in Visual Studio

All repos are cloned automatically by `setup.bat`. Open `C:\dtnsourcecode\DTN.Core.Base` in Visual Studio **as Admin** and build. If that works, your setup is good.


