# <img src="https://flagcdn.com/20x15/ps.png" alt="Palestine Flag"> Gaza-Recon

Automated reconnaissance framework for bug bounty hunting that integrates multiple tools for subdomain enumeration, URL extraction, parameter discovery, and vulnerability scanning in a single pipeline.

---


## Features

- Subdomain enumeration using multiple sources
- Live host detection (HTTP probing)
- URL gathering from multiple sources:
- Sensitive file detection (JS, PHP, logs, backups, etc.)
- JavaScript file extraction and analysis
- Parameter discovery using Arjun
- Directory & file brute forcing (Dirsearch + FFUF)
- Vulnerability scanning using Nuclei
- Organized structured output per target


---

## Tools Used

- subfinder  
- httpx  
- katana  
- gau  
- gospider  
- waybackurls  
- arjun  
- dirsearch  
- ffuf  
- nuclei  
- jsluice  

---

##  Prerequisites

Before installing the tool, make sure you have the following requirements installed on your system:

### System Dependencies

```bash 
sudo apt update && sudo apt install -y git golang wget ffuf nuclei dirsearch
go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install github.com/projectdiscovery/httpx/cmd/httpx@latest
go install github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest
go install github.com/projectdiscovery/katana/cmd/katana@latest
go install github.com/lc/gau/v2/cmd/gau@latest
go install github.com/tomnomnom/waybackurls@latest
go install github.com/s0md3v/Arjun@latest
```

---


##  Installation

Clone the repository:
```bash
git clone https://github.com/abdelrahman-710/Gaza-Recon.git
cd Gaza-Recon
```


---

##  Usage

Make script executable:
```bash
chmod +x Recon.sh
Run: ./Recon.sh
```
---

##  Input Formats
Single domain: example.com

Wildcard: *.example.com

Domain list: domains.txt

---

##  Output Structure

All results will be stored in a structured folder per target:

```bash
target/
│
├── subdomains.txt          # Discovered subdomains
├── httpx.txt               # All probed hosts
├── live.txt                # Live hosts only
├── allurls.txt             # Collected URLs
│
├── filtered/               # Filtered sensitive files
│   ├── js.txt
│   ├── php.txt
│   ├── json.txt
│   ├── log.txt
│   └── ...
│
├── js_downloaded/          # Downloaded JS files
├── js_analysis/            # JS analysis results
├── parameters/             # Parameter discovery results
├── ffuf/                   # FFUF scan results
├── dirsearch.txt           # Directory brute force results
└── nuclei_output/          # Nuclei scan results
