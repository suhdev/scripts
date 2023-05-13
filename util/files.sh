delete-all-files-with-extension() {
  local package_path="$(realpath ./)"
  local extension="nupkg"

  while getopts ":p:e:h" opt; do
    case $opt in
      p) 
        package_path="$(realpath $OPTARG)"
      ;;
      e) 
        extension="$OPTARG"
      ;;
      h) 
        echo "Usage"
        echo "  delete-all-files-with-extension.sh [-p <path>] [-e <extension>] [-h]"
        echo "  -p: Path to delete files from"
        echo "  -e: Extension of the files to delete"
        exit 0
        ;;
      \?) echo "Invalid option -$OPTARG" >&2
      ;;
    esac
  done

  local file_names="*.${extension}"
  # check if stdin has data
  if [[ -p /dev/stdin ]] ; then
    while read line ; do
      package_path=$line
      find $package_path -type f -name $file_names -delete
    done
  else 
    find $package_path -type f -name $file_names -delete
  fi
}

find-all-files-with-extension() {
  local package_path="$(realpath ./)"
  local extension="nupkg"

  while getopts ":p:e:h" opt; do
    case $opt in
      p) 
        package_path="$(realpath $OPTARG)"
      ;;
      e) 
        extension="$OPTARG"
      ;;
      h) 
        echo "Usage"
        echo "  delete-all-files-with-extension.sh [-p <path>] [-e <extension>] [-h]"
        echo "  -p: Path to delete files from"
        echo "  -e: Extension of the files to delete"
        exit 0
        ;;
      \?) echo "Invalid option -$OPTARG" >&2
      ;;
    esac
  done

  local file_names="*.${extension}"
  if [[ -p /dev/stdin ]] ; then
    while read line ; do
      package_path=$line
      find . -name $file_names -type f -exec echo {} \;
    done
  else 
    find . -name $file_names -type f -exec echo {} \;
  fi
}
