!/bin/bash

clear
echo -e "\e[1;31m
   ██████╗   █████╗ ███████╗ █████╗ 
  ██╔════╝  ██╔══██╗╚══███╔╝██╔══██╗
  ██║  ███╗ ███████║  ███╔╝ ███████║
  ██║   ██║ ██╔══██║ ███╔╝  ██╔══██║
  ╚██████╔╝ ██║  ██║███████╗██║  ██║
   ╚═════╝  ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝
   🇵🇸  GAZA RECON TOOL - FREE PALESTINE
\e[0m"

read -p "📌 Enter target domain or domains list (*.example.com OR domains.txt): " target

if [[ "$target" == *.txt ]]; then
  if [[ ! -f "$target" ]]; then
    echo "❌ File not found: $target"
    exit 1
  fi
  folder_name="${target%.txt}"
else
  folder_name="$target"
fi

mkdir -p "$folder_name" && cd "$folder_name" || exit

# ------------------ Subdomain Enumeration Logic --------------------
echo -e "\e[1;31m[*] Subdomain Enumeration...\e[0m"

if [[ "$target" == *.txt ]]; then
  echo -e "\e[1;31m[*] Using domain list from file: $target \e[0m"
  cat "../$target" > subdomains.txt

elif [[ "$target" == \** ]]; then
  clean_target="${target#*.}"
  echo -e "\e[1;31m[*] Wildcard detected, running Subfinder on $clean_target...\e[0m"
  subfinder -d "$clean_target" -all --recursive -o subdomains.txt
  [ ! -s subdomains.txt ] && echo "$clean_target" > subdomains.txt

else
  echo -e "\e[1;31m[*] Single domain detected. Skipping Subfinder. \e[0m"
  echo "$target" > subdomains.txt
fi
echo -e  "\n========================================================================="

# ------------------------ Live Hosts Check ------------------------------
echo -e "\e[1;31m[*] Running httpx to find live hosts...\e[0m"
httpx  -l subdomains.txt -o httpx.txt 
httpx -mc 200 -l httpx.txt -o live.txt 

echo -e  "\n========================================================================="

# ---------------- URL Gathering ----------------
echo -e "\e[1;31m[*] Gathering URLs using multiple tools...\e[0m"
katana -list httpx.txt -o katana.txt &
waybackurls < httpx.txt > wayback.txt &
gau < httpx.txt > gau.txt &
gospider -S httpx.txt | sed -n 's/.*\(https\?:\/\/[^ ]*\)]*.*/\1/p' > gospider.txt &
wait

cat wayback.txt gospider.txt gau.txt katana.txt | sort -u > allurls.txt

# ---------------- Sensitive URL Filtering ----------------
echo -e "\e[1;31m[*] Filtering sensitive file types...\e[0m"
mkdir -p filtered
grep -iE "\.asp" allurls.txt > filtered/asp.txt
grep -iE "\.php" allurls.txt > filtered/php.txt
grep -iE "\.jsp" allurls.txt > filtered/jsp.txt
grep -iE "\.js\b" allurls.txt > filtered/js.txt
grep -iE "\.pdf" allurls.txt > filtered/pdf.txt
grep -iE "\.docx?" allurls.txt > filtered/doc.txt
grep -iE "\.xlsx?" allurls.txt > filtered/xls.txt
grep -iE "\.csv" allurls.txt > filtered/csv.txt
grep -iE "\.xml" allurls.txt > filtered/xml.txt
grep -iE "\.json" allurls.txt > filtered/json.txt
grep -iE "\.log" allurls.txt > filtered/log.txt
grep -iE "\.bak" allurls.txt > filtered/bak.txt
grep -iE "\.zip" allurls.txt > filtered/zip.txt
grep -iE "\.rar" allurls.txt > filtered/rar.txt
grep "=" allurls.txt > filtered/param.txt

# ---------------- Download JS Files THEN Analyze ----------------
echo -e "\e[1;31m[*] Downloading JavaScript files...\e[0m"
mkdir -p js_downloaded
cd js_downloaded || exit
for js_url in $(cat ../filtered/js.txt); do
  wget --no-check-certificate --timeout=10 -q "$js_url"
done
cd ..

# ---------------- JS Analysis ----------------
if compgen -G "js_downloaded/*.js" > /dev/null; then
  echo -e "\e[1;31m[*] Analyzing JavaScript files...\e[0m"
  mkdir -p js_analysis
  cat filtered/js.txt | mantra > js_analysis/output.txt
  jsluice secrets js_downloaded/*.js > js_analysis/jsluice_secrets.txt
  jsluice urls js_downloaded/*.js > js_analysis/jsluice_urls.txt
else
  echo -e "\e[1;31m❌ No JS files downloaded. Skipping JS analysis.\e[0m"
fi

# ---------------- Parameter Discovery ----------------
echo -e "\e[1;31m[*] Extracting parameters with Arjun (looping through all filtered files)...\e[0m"
mkdir -p parameters

for file in filtered/*.txt; do
  if [ -s "$file" ]; then
    echo -e "\e[1;34m[+] Running Arjun on $file\e[0m"
    arjun -i "$file" -m GET,POST -o "parameters/arjun.txt"
  fi
done
# ---------------- Dirsearch ----------------
echo -e "\e[1;31m[*] Running Dirsearch...\e[0m"
dirsearch -l "$(pwd)/httpx.txt" -o dirsearch.txt -i 200,403,401 --full-url --random-agent -e conf,config,bak,backup,swp,old,db,sql,asp,aspx,aspx~,asp~,py,py~,rb,rb~,php,php~,bak,bkp,cache,cgi,conf,csv,html,inc,jar,js,json,jsp,jsp~,lock,log,rar,old,sql,sql.gz,http://sql.zip,sql.tar.gz,sql~,swp,swp~,tar,tar.bz2,tar.gz,txt,wadl,zip,.log,.xml,.js.,.json

# ---------------- FFUF ----------------
echo -e "\e[1;31m[*] Running FFUF on live hosts...\e[0m"
mkdir -p ffuf
DIR_WORDLIST="/home/kali/Downloads/SecLists/Discovery/Web-Content/raft-large-directories.txt"
FILE_WORDLIST="/home/kali/Downloads/SecLists/Discovery/Web-Content/raft-large-files.txt"

for url in $(cat live.txt); do
  clean_name=$(echo "$url" | sed 's|https\?://||g' | tr '/' '_')
  ffuf -w "$DIR_WORDLIST" -u "$url/FUZZ"  -recursion -t 50 -timeout 15 | ../bugbounty/uni.sh  > "ffuf/${clean_name}_dirs.txt"
  ffuf -w "$FILE_WORDLIST" -u "$url/FUZZ" -t 50 -timeout 15 | ../bugbounty/uni.sh  >  "ffuf/${clean_name}_files.txt"
done

# ---------------- Nuclei ----------------
echo -e "\e[1;31m[*] Running Nuclei (Full Templates)...\e[0m"
mkdir -p nuclei_output
nuclei -l live.txt -t ~/nuclei-templates/http -rl 80 -c 20 -o nuclei_output/domains_full_scan.txt

# Nuclei on parameter URLs
echo -e "\e[1;31m[*] Running Nuclei on parameterized URLs...\e[0m"
[ -s filtered/param.txt ] && nuclei -l filtered/param.txt -t ~/nuclei-templates/ -rl 80 -c 20 -o nuclei_output/urls_param_scan.txt

# ---------------- Done ----------------
echo -e "\n✅ \e[1;32mGAZA Recon Completed. All outputs saved in ./$folder_name/\e[0m"
