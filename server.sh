#/bin/sh

inst="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"
trap '{ echo -e "\e[90m$(date '+%H:%M:%S')\e[91m client received interrupt: session closed\e[39m" > $output ; \
      kill $(ps u|grep "nc -l -p $port"|head -n1|awk -v n=2 '"'"'{print $n}'"'"') ; \
      echo "Server-Instance $inst exited by interrupt" ; \
      exit 0 ; \
      }' INT

host_name=host
client_name=client

if [ $# -ge 1 ]; then
  port=$1
else
  port=9999
fi

input=/tmp/chat-receive-$port
output=/tmp/chat-sending-$port

rm -f $input
rm -f $output
mkfifo $input
mkfifo $output

clear_line() {
  printf '\r\033[2K'
}

move_cursor_up() {
  printf '\033[1A'
}

server() {
  echo -e "\e[90m$(date '+%H:%M:%S')\e[32m Starting on port\e[39m $port"
  tail -f $output | nc -l -p $port >$input
  echo -e "\e[90m$(date '+%H:%M:%S')\e[91m server ending\e[39m\n"
}

receive() {
#  echo -ne "\e[90m$(date '+%H:%M:%S')\e[39m"
  printf '%s: ' "$client_name" > $output
  local message
  while IFS= read -r message; do
    clear_line
    echo -ne "\e[90m$(date '+%H:%M:%S') "
    printf '\033[0;35m%s: \033[0;39m%s\n%s: ' "$client_name" "$message" "$host_name"
    move_cursor_up > $output
    clear_line > $output
    echo -ne "\e[90m$(date '+%H:%M:%S') " > $output
    printf '\033[0;94m%s: \033[0;39m%s\n%s: ' "$client_name" "$message" "$client_name" > $output
  done < $input
  echo -e "\e[90m$(date '+%H:%M:%S')\e[91m client received interrupt: session closed\e[39m"
}

chat() {
  echo -ne "\e[90m$(date '+%H:%M:%S')\e[39m "
  printf '%s: ' "$host_name"
  local message
  while [ 1 ]; do
    IFS= read -r message
    clear_line > $output
    echo -ne "\e[90m$(date '+%H:%M:%S') " > $output
    printf '\033[0;35m%s: \033[0;39m%s\n%s: ' "$host_name" "$message" "$client_name" > $output
    move_cursor_up
    clear_line
    echo -ne "\e[90m$(date '+%H:%M:%S') "
    printf '\033[0;94m%s: \033[0;39m%s\n%s: ' "$host_name" "$message" "$host_name"
  done;
  echo -e "\e[90m$(date '+%H:%M:%S')\e[91m chat ending\e[39m"
}

read -p $'\e[94mEnter username:\e[39m ' host_name
server &
echo 'Waiting for client to join...'
printf '\033[0;94m%s \033[0;39m%s%s' "Enter username:" > $output
read -r client_name < $input
echo -e "\e[90m$(date '+%H:%M:%S') \e[32m$client_name has joined the chat\e[39m"
echo -e "\e[90m$(date '+%H:%M:%S') \e[32mJoined $host_name's chat\e[39m" > $output
receive &
chat

