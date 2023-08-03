registry_directory="$HOME/.nuget-registry"
registry_name="newdawn"
CLEAN=false
VERSION=""
PACKAGE_PATH="."
failed_builds=()
semver=$(cat nuget-version.txt 2>/dev/null || echo "1.0.0")
# Split semver into major, minor, and patch components
IFS='.' read -r major minor patch <<< "$semver"

while getopts ":cbv:p:hr:n:" opt; do
  case $opt in
    c)
      CLEAN=true
      ;;
    r)
      registry_directory="$OPTARG"
      ;;
    n)
      registry_name="$OPTARG"
      ;;
    v)
      VERSION="$OPTARG"
      ;;
    p)
      PACKAGE_PATH="$OPTARG"
      ;;
    b)
      VERSION="beta"
      ;;
    h)
      echo "Usage: pack-and-publish.sh [-c] [-v <version>] [-p <package-path>] [-b]"
      echo "  -c: Clean the nuget packages before building"
      echo "  -v: Version to update (major, minor, patch)"
      echo "  -p: Path to the package(s) to build"
      echo "  -b: Build a beta version"
      echo "  -r: Path to the nuget registry"
      echo "  -n: Name of the nuget registry"
      echo "-----------------------------------------------"
      echo "Notes:"
      echo "1. Make sure to add <IsPackable>true</IsPackable> to the csproj file"
      echo "2. The script will create a nuget registry in $registry_directory, defaults to $HOME/.nuget-registry"
      echo "3. The script will add the registry to the nuget sources if it doesn't exist"
      echo "4. The script will delete all nuget packages in the package path before building"
      echo "5. The script will update the version in nuget-version.txt"
      exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done

update_version() {
  echo "Updating $VERSION version"
  if [ "$VERSION" = "minor" ]; then
    minor=$((minor+1))
  elif [ "$VERSION" = "major" ]; then
    major=$((major+1))
  elif [ "$VERSION" = "patch" ]; then
    patch=$((patch+1))
  elif [ "$VERSION" = "beta" ]; then
    patch="$patch-beta"
  fi

  # Update semver variable
  semver="$major.$minor.$patch"
  # Write updated semver to file
  echo "$semver" > nuget-version.txt
}

build_and_publish_package() {
  local line="$1"
  local record_failure=$2

  echo "Project is packable: $line"
  dotnet pack "$line" -c Release -p:PackageVersion=$semver
  dotnet nuget push "$(dirname "$line")/bin/Release/*.nupkg" --source $registry_name
  if [ $? -ne 0 ]; then
    # Check if we should record the failure
    if [ "$record_failure" = true ]; then
      # If the command failed, add the line to the failed_builds list
      echo "Failed to build $line"
      failed_builds+=($line)
    fi
  fi
}

build_and_publish_nuget_packages() {
  find . -name '*.csproj' -type f -exec echo {} \; | while read line; do
    if grep -q '<IsPackable>true</IsPackable>' "$line"; then
      build_and_publish_package "$line" true
    fi
  done

  if [ ${#failed_builds[@]} -ne 0 ]; then
    echo "Retrying failed builds..."
    for line in "${failed_builds[@]}"; do
      build_and_publish_package "$line" false
    done
  fi
}

update_version

create_nuget_registry

delete_nuget_packages

build_and_publish_nuget_packages