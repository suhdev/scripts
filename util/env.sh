add-to-global-path() {
  local p="$1"

  # check if the path is not empty 
  if [ -z "$p" ]; then
    p="$(realpath)"
  fi

  if [ -d "$p" ]; then # check if the folder exists
    if [[ $PATH != *"$p"* ]]; then # check if the path is already in the PATH
      echo "" >> $HOME/.zshrc
      echo "# Updating PATH" >> $HOME/.zshrc
      echo "export PATH=\"\$PATH:${p}\"" >> $HOME/.zshrc
      export PATH="$PATH:${p}"
    fi
  fi
}

add-source-file() {
  local p="$1"

  # check if the path is not empty 
  if [ -z "$p" ]; then
    echo "please specify a source file to source in your zshrc"
    exit 1
  fi

  p=$(realpath $p)

  if [ -f "$p" ]; then # check if the folder exists
    if ! grep -iq "source ${p}" $HOME/.zshrc; then # check if the path is already in the PATH
      echo "" >> $HOME/.zshrc
      echo "# Adding source file" >> $HOME/.zshrc
      echo "if [ -f \"${p}\" ]; then" >> $HOME/.zshrc
      echo "  source ${p}" >> $HOME/.zshrc
      echo "fi" >> $HOME/.zshrc
      source ${p}
    fi
  fi
}