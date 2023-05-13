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