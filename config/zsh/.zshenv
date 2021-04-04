# Navigation
alias ~="cd ~"
alias ..="cd .."
alias ...="cd ../../"
alias dl="cd ~/Downloads"
alias dt="cd ~/Desktop"
alias p="cd ~/Projects"

# Shortcuts
alias c="clear"
alias h="history"
alias rr="rm -rf"
alias f="open -a Finder ./"
alias reload=". ~/.zshrc"
alias top="top -o cpu"
alias numFiles="echo $(ls -1 | wc -l)"
alias path="echo -e ${PATH//:/\\n}"
alias grep="grep --color"
alias today="date +'%m-%d-%Y'"
alias aliases="alias | sed 's/=.*//'"
alias functions="declare -f | grep '^[a-z].* ()' | sed 's/{$//'"
alias paths="echo -e ${PATH//:/\\n}"
alias count="find . -type f | wc -l"

# System
alias cleanupDS="find . -type f -name '*.DS_Store' -ls -delete"
alias edit="subl"
alias emptytrash="sudo rm -rfv /Volumes/*/.Trashes; sudo rm -rfv ~/.Trash; sudo rm -rfv /private/var/log/asl/*.asl"
alias flushDNS="dscacheutil -flushcache && killall -HUP mDNSResponder"
alias logoff="/System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspend"
alias update="sudo softwareupdate -i -a; brew update; brew upgrade; npm i npm -g; npm up -g"
alias ip="dig +short myip.opendns.com @resolver1.opendns.com"
alias localip="ipconfig getifaddr en0"
alias path="echo -e ${PATH//:/\\n}"
alias ic="cd ~/Library/Mobile\ Documents/com~apple~CloudDocs"
alias gen_pwd="LC_ALL=C tr -dc '[:alnum:]' < /dev/urandom | head -c 20 | pbcopy"

# Git
alias clone="git clone $1"
alias pull="git pull origin master"
alias push="git pull origin master && git push origin master"
alias gi="git add -A && git commit -m"
alias gm="git push origin master"

# NPM
alias ni="npm install"
alias nr="npm run"
alias dev="npm run dev"
alias build="npm run build"

# Docker
alias docker_stop='docker stop $(docker ps -a -q)'
alias docker_remove='docker rm $(docker ps -a -q)'

# Android
# alias runAndroid="emulator @test"
# alias rmAndroid="avdmanager delete avd -n test"

# Xcode
# alias xcode_reset="sudo xcode-select --reset && sudo xcodebuild -license"

# Serve a directory on a given port
# Example: servedir 8080
servedir() {
  # Allow myself to change the port ($1)
  python -m SimpleHTTPServer "$1"
}

# Scrape images with wget
# Example: scrapeimages https://google.com/
scrapeimages() {
  wget -nd -H -p -A jpg,jpeg,png,gif -e robots=off $1
}

# Remove audio from video
# Example: removeaudio myvideo.webm myvideo-silent.mp4
removeaudio() {
  ffmpeg -i $1 -vcodec copy -an $2
}

startover() {
  echo 'Killing everything'
  rm -rf build/
  docker-compose down
  docker rm -f $(docker ps -a -q)
  docker rmi -f $(docker images -q)
  echo 'Everything killed, my lord'
}
