create_nuget_registry() {
  local registry_directory="$(realpath $HOME/.nuget-registry)"
  local registry_name="suhdev"

  while getopts ":d:n:h" opt; do
    case $opt in
      d) registry_directory="$OPTARG"
      ;;
      n) registry_name="$OPTARG"
      ;;
      h) 
        echo "Usage"
        echo "  create-nuget-registry.sh [-d <registry-directory>] [-n <registry-name>] [-h]"
        echo "  -d: Path to the nuget registry, defaults to $HOME/.nuget-registry"
        echo "  -n: Name of the nuget registry, defaults to suhdev"
        exit 0
        ;;
      \?) echo "Invalid option -$OPTARG" >&2
      ;;
    esac
  done

  # Check if the folder already exists
  if [ -d "$registry_directory" ]; then
      echo "Folder '$registry_directory' already exists."
  else
      # Create the folder
      mkdir "$registry_directory"
      echo "Folder '$registry_directory' created."
      if grep -q "$2" "$(dotnet nuget list source)"; then
        dotnet nuget add source $registry_directory --name $registry_name
      fi
  fi
}

clear_dotnet_local_cache() {
  dotnet nuget locals -c all 
}

delete_nuget_packages() {
  local package_path="$(realpath ./)"

  while getopts ":p:" opt; do
    case $opt in
      p) package_path="$(realpath $OPTARG)"
      ;;
      \?) echo "Invalid option -$OPTARG" >&2
      ;;
    esac
  done
  delete_all_files_with_extension -p $package_path -e nupkg
}

is_packable_project() {
  local project_path=$1

  install_software xmlstarlet 
  value=$(xmlstarlet sel -t -v "//IsPackable" $project_path)
  if [ "$value" = "true" ]; then
    return 1
  else
    return 0
  fi
}

is_silo_project() {
  local project_path=$1

  install_software xmlstarlet 
  value=$(xmlstarlet sel -t -v "//IsSilo" $project_path)
  if [ "$value" = "true" ]; then
    return 1
  else
    return 0
  fi
}

is_dockerized_project() {
  local project_path=$1

  install_software xmlstarlet
  value=$(xmlstarlet sel -t -v "//IsDockerized" $project_path)
  if [ "$value" = "true" ]; then
    return 1
  else
    if [ -f "$(dirname $project_path)/Dockerfile" ]; then
      return 1
    else 
      return 0
    fi
  fi
}

is_service_project() {
  local project_path=$1

  install_software xmlstarlet
  value=$(xmlstarlet sel -t -v "//IsService" $project_path)
  if [ "$value" = "true" ]; then
    return 1
  else
    return 0
  fi
}

dotnet_build_service() {
  local project_path=$1
  local configuration="Release"
  local outputdir="$(dirname $project_path)/bin/Release"

  if [[ -p /dev/stdin ]]; then
    project_path=$(cat)
  fi

  is_service_project $project_path
  should_build=$?

  if [ $should_build -eq 0 ]; then
    is_silo_project $project_path
    should_build=$?
  fi
  if [ $should_build -eq 0 ]; then
    is_dockerized_project $project_path
    should_build=$?
  fi

  if [ $should_build -eq 1 ]; then
    dotnet restore $project_path
    dotnet publish "$project_path" -c "$configuration" -o $outputdir    
  fi
}

dotnet_pack() {
  local project_path=$1
  local version="1.0.0"
  local configuration="Release"

  while getopts ":v:c:t:h" opt; do
    case $opt in
      v) 
        version="$OPTARG"
      ;;
      c) 
        configuration="$OPTARG"
      ;;
      h)
        echo "Usage"
        echo "  dotnet-build.sh cs-proj-path [-v <version>] [-h]"
        echo "  -v: Version to use (semver)"
        echo "  -c: Configuration to build (Debug, Release)"
        echo "  -h: Show help"
        exit 0
        ;;
      \?) echo "Invalid option -$OPTARG" >&2
      ;;
    esac
  done

  # if stdin has input read that into $project_path
  if [[ -p /dev/stdin ]]; then
    project_path=$(cat)
  fi

  is_packable_project $project_path

  if [ $? -eq 1 ]; then
    dotnet restore $project_path
    dotnet pack "$project_path" -c "$configuration" -p:PackageVersion=$version
  fi
}

find_all_dotnet_projects() {
  find . -name '*.csproj' -type f -exec echo {} \;
}

find_all_dotnet_projects_with_docker() {
  find_all_dotnet_projects | while read line; do
    if grep -q '<BuildDocker>true</BuildDocker>' "$line"; then
      echo $line
    fi
  done
}

build_dotnet_release_docker_image() {
  local csproj_path=$1
  
  # if file does not exist exit 
  if [ ! -f "$csproj_path" ]; then
    echo "Project file could not be found at $csproj_path"
    exit 1
  fi

  local version="1.0.0"
  local docker_file_path="$(dirname $csproj_path)/Dockerfile"
  local csproj_path_no_extension="${csproj_path%.*}"
  local dll_name="$(basename $csproj_path_no_extension).dll"
  local image_name=$(basename $csproj_path_no_extension | tr '[:upper:]' '[:lower:]')

  while getopts ":v:i:h" opt; do
    case $opt in
      v) 
        version="$OPTARG"
        ;;
      i)
        image_name="$OPTARG"
        ;;
      h)
        echo "Usage"
        echo "  build-dotnet-docker-image.sh cs-proj-path [-v <version>] [-h]"
        echo "  -v: Version to update (major, minor, patch)"
        echo "  -h: Show help"
        exit 0
        ;;
      \?) echo "Invalid option -$OPTARG" >&2
        ;;
    esac
  done
  
  if [ ! -f "$docker_file_path" ]; then
    docker_file_path="$(dirname )"
    echo "Dockerfile not found at $docker_file_path"
    exit 1
  fi

  dotnet_build_service $csproj_path -v $version -c Release
  local image_tag="$imagename:$version" 
  DOCKER_BUILDKIT=0 docker build -t $image_tag -f "$(dirname $0)/Dockerfile" \
    --build-arg DLL_NAME=$dll_name \
    $outputdir
}