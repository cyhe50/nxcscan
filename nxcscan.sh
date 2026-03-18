#!/bin/bash

helpFunction() {
  echo "usage: "
  echo "read credential file: ./nxcscan service ip -f credential_files -c 'additional commands'"
  echo "read username and password: ./nxcscan service ip -u username -p password -c 'additional commands'"
  echo "read username and hash: ./nxcscan service ip -u username -H password -c 'additional commands'"

  echo "example: ./nxcscan smb 192.168.138.133 -f creds -c '--users'"
  echo "example: ./nxcscan smb targets -f creds -c '-M lsassy'"

  echo '==================================================='
  echo 'credential_files format: (remember the prefix)'
  echo 'p:username:password for password'
  echo 'h:username:ntlmhash for hash'

  echo '==================================================='
  echo 'arguments:'
  echo '-c: the commands want to run with the nxc'
  echo "--only-success": use fgrep to print only success log
  echo "--with-local": run both domain accounts and local-auth

  exit
}

run() {
  local usernames=$1
  local pass_or_hash=$2
  local mode=$3
  # echo "DEBUG in run(): m='${m}' user='${usernames}' secret='${pass_or_hash}'"

  cmd=(env PYTHONWARNINGS="ignore" nxc "$service" "$ips" -u "$usernames" "$mode" "$pass_or_hash" "$c")

  if [ "$only_success" = true ]; then
    # output with color (unbuffer is required, if not, run `sudo apt install expect)
    if command -v unbuffer &>/dev/null; then
      echo "Executing: unbuffer ${cmd[*]} --continue-on-success | grep -Fv \"[-]\""
      unbuffer "${cmd[@]}" --continue-on-success | fgrep -vi "[-]"
    else
      # fallback: no color
      "${cmd[@]}" --continue-on-success | fgrep -vi "[-]"
    fi
  else
    echo "Executing: ${cmd[*]}"
    "${cmd[@]}"
  fi

  # local-auth
  if [ "$with_local" = true ]; then
    if [ "$only_success" = true ]; then
      if command -v unbuffer &>/dev/null; then
        echo "Executing: unbuffer ${cmd[*]} --local-auth --continue-on-success | grep -Fv \"[-]\""
        unbuffer "${cmd[@]}" --local-auth --continue-on-success | fgrep -vi "[-]"
      else
        # fallback: no color
        "${cmd[@]}" --local-auth --continue-on-success | fgrep -vi "[-]"
      fi
    else
      echo "Executing: ${cmd[*]} --local-auth"
      "${cmd[@]}" --local-auth
    fi
  fi
}

runCredentials() {
  # Read the file line-by-line
  while IFS=':' read -r m usernames pass_or_hash _; do
    # echo "DEBUG in runCredentials(): m='${m}' user='${usernames}' secret='${pass_or_hash}'"

    # Skip empty lines
    [[ -z "$m" || -z "$usernames" || -z "$pass_or_hash" ]] && continue

    if [ "$m" == "p" ] || [ "$m" == "P" ]; then
      mode="-p"
    elif [ "$m" == "h" ] || [ "$m" == "H" ]; then
      mode="-H"
    else
      continue
    fi

    run "$usernames" "$pass_or_hash" "$mode"
  done <"$f"
}

####################################################################################
# main function starts here

# mandatory arguments: services and ips
if [ -z $1 ] || [ -z $2 ]; then
  echo "missing arguments: service: $1, ips: $2\n\n\n"
  helpFunction
fi

# parse all to services array
if [ $1 == "all" ]; then
  services=("smb" "winrm" "rdp" "ldap" "wmi" "mssql")
elif [[ "$1" == *","* ]]; then
  IFS=',' read -ra services <<< "$1"
else
  services=("$1")
fi

ips="$2"

# parse other arguments
shift 2

with_local=false
only_success=false

while [[ $# -gt 0 ]]; do
  case "$1" in
  -u)
    u="$2"
    shift 2
    ;;
  -p)
    p="$2"
    shift 2
    ;;
  -H)
    H="$2"
    shift 2
    ;;
  -f)
    f="$2"
    shift 2
    ;;
  -c)
    c="$2"
    shift 2
    ;;
  --with-local)
    with_local=true
    shift 1
    ;;
  --only-success)
    only_success=true
    shift 1
    ;;
  -h | --help)
    helpFunction
    exit 0
    ;;
  *)
    echo "Unknown option: $1"
    shift
    ;;
  esac
done

# echo "u: $u, p: $p, H: $H, f: $f, c: $c"

# start scanning
for service in ${services[@]}; do
  if [ "$f" != "" ]; then
    runCredentials
  elif [ "$u" != "" ] && [ "$H" != "" ]; then
    run "$u" "$H" "-H"
  else
    run "$u" "$p" "-p"
  fi
done
