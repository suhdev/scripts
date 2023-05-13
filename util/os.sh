get-operating-system() {
  local os=$(uname -s)
  case $os in
    Linux*)   echo "linux" ;;
    Darwin*)  echo "macos" ;;
    CYGWIN*)  echo "windows" ;;
    MINGW*)   echo "windows" ;;
    *)        echo "unknown" ;;
  esac
}

get-architecture() {
  local arch=$(uname -m)
  case $arch in
    x86_64*)  echo "x64" ;;
    i*86)     echo "x86" ;;
    *)        echo "unknown" ;;
  esac
}

install-software() {
  local tool=$1

  local os=$(get-operating-system)

  if [ "$os" = "linux" ]; then
    install-for-linux $tool
  elif [ "$os" = "macos" ]; then
    install-for-macos $tool
  elif [ "$os" = "windows" ]; then
    install-for-windows $tool
  else
    echo "Unknown operating system: $os"
    exit 1
  fi
}

install-for-linux() {
  if ! command -v $1 &> /dev/null; then
    sudo apt-get install $1
  else
    echo "$1 is already installed"
  fi 
}

install-for-macos() {
  if ! command -v $1 &> /dev/null; then
    brew install $1
  else
    echo "$1 is already installed"
  fi
}

install-for-windows() {
  choco install $1
}