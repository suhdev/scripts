get_operating_system() {
  local os=$(uname -s)
  case $os in
    Linux*)   echo "linux" ;;
    Darwin*)  echo "macos" ;;
    CYGWIN*)  echo "windows" ;;
    MINGW*)   echo "windows" ;;
    *)        echo "unknown" ;;
  esac
}

get_architecture() {
  local arch=$(uname -m)
  case $arch in
    x86_64*)  echo "x64" ;;
    i*86)     echo "x86" ;;
    *)        echo "unknown" ;;
  esac
}

install_software() {
  local tool=$1

  local os=$(get_operating_system)

  if [ "$os" = "linux" ]; then
    install_for_linux $tool
  elif [ "$os" = "macos" ]; then
    install_for_macos $tool
  elif [ "$os" = "windows" ]; then
    install_for_windows $tool
  else
    echo "Unknown operating system: $os"
    return 1
  fi
}

install_for_linux() {
  if ! command -v $1 &> /dev/null; then
    sudo apt-get install $1
  else
    echo "$1 is already installed"
  fi 
}

install_for_macos() {
  if ! command -v $1 &> /dev/null; then
    brew install $1
  else
    echo "$1 is already installed"
  fi
}

install_for_windows() {
  choco install $1
}