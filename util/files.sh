delete_all_files_with_extension() {
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

find_first_file_in_parent_directories_that_match_extension() {
  local extension="$1"
  if [[ "$extension" == "" ]]; then
    extension="txt"
  fi

  local current_dir="$2"
  local sln_file=""

  if [[ "$current_dir" == "" ]]; then
    current_dir="$PWD"
  fi

  local iteration=0

  while [[ "$current_dir" != "" ]]; do
    sln_file=$(ls "$current_dir"/*.$extension 2>/dev/null | head -n 1)
    iteration=$((iteration+1))
    if [[ -n "$sln_file" ]]; then
        break
    fi
    current_dir=${current_dir%/*}
    # break if iteration is greater than 40
    if [[ $iteration -gt 40 ]]; then
      break
    fi
  done

  if [[ ! -z "$sln_file" ]]; then
    echo $sln_file
  fi
}

find_all_files_with_extension() {
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
