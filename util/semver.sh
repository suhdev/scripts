increment-semver() {
  local version="1.0.0"
  local update_type="patch"
  local patch="0"
  local minor="0"
  local major="0"

  if [[ -p /dev/stdin ]] ; then
    version=$(cat)
    IFS='.' read -r major minor patch <<< "$version"
  fi

  while getopts ":v:t:h" opt; do
    case $opt in
      v) 
        version="$OPTARG"
        IFS='.' read -r major minor patch <<< "$version"
      ;;
      t) 
        update_type="$OPTARG"
      ;;
      h) 
        echo "Usage"
        echo "  update-semver.sh [-v <version>] [-t <update-type>] [-h]"
        echo "  -v: Version to update (major.minor.patch), defaults to 1.0.0"
        echo "  -t: Type of update (major, minor, patch, beta), defaults to patch"
        exit 0
        ;;
      \?) 
        echo "Invalid option -$OPTARG" >&2
      ;;
    esac
  done

  if [ "$update_type" = "minor" ]; then
    minor=$((minor+1))
  elif [ "$update_type" = "major" ]; then
    major=$((major+1))
  elif [ "$update_type" = "patch" ]; then
    patch=$((patch+1))
  elif [ "$update_type" = "beta" ]; then
    patch="$patch-beta"
  fi

  # Update semver variable
  semver="$major.$minor.$patch"
  # Write updated semver to file
  echo "$semver"
}


get-version() {
  local version=""
  local version_file=".version"

  while getopts ":v:f:h" opt; do
    case $opt in
      v) 
        version="$OPTARG"
      ;;
      f)
        version_file="$OPTARG"
      ;;
      h) 
        echo "Usage"
        echo "  get-version.sh [-v <version>] [-h]"
        echo "  -v: Version to update (major.minor.patch), defaults to 1.0.0"
        exit 0
        ;;
      \?) echo "Invalid option -$OPTARG" >&2
      ;;
    esac
  done


  if [ -z "$version" ]; then
    version_files=(
      $version_file 
      "VERSION" 
      "version.txt" 
      "VERSION.txt" 
      "version" 
      "nuget-version" 
      "nuget-version.txt" 
      "nuget_version" 
      "nuget_version.txt"
    )

    for file in "${version_files[@]}"; do
      if [ -f "$file" ]; then
        version=$(cat $file)
        break
      fi
    done
  fi

  if [ -z "$version" ]; then
    version="1.0.0"
  fi

  echo $version
}