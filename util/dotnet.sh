add_latest_dependency_to_project() {
  local source="https://api.nuget.org/v3/index.json"
  local package=""
  local version=""

  while getopts "p:s:h" opt; do
    case $opt in
      p) package="$OPTARG"
      ;;
      s) source="$OPTARG"
      ;;
      h) 
        echo "Usage"
        echo "  search_for_package [-p <package-name>] [-h]"
        echo "  -p: Name of the package to search for"
        echo "  -h: Show help"
        exit 0
        ;;
      \?) echo "Invalid option -$OPTARG" >&2
      ;;
    esac
  done

  if [ -z "$package" ]; then
    echo "Package name is required"
    return 1
  fi

  IFS=' ' read -r package version <<< $(nuget list "PackageId:$package" -AllVersions -Source $source)

  add_dependency_to_project -p $package -v $version
}


list_remote_nuget_sources() {
  xmlstarlet sel -t -v "//configuration/packageSources/add/@value" ~/.nuget/NuGet/NuGet.Config
}

list_nuget_package_versions() {
  local source_url="https://api.nuget.org/v3/index.json"
  local package_name=""

  while getopts "p:s:h" opt; do
    case $opt in
      p) package_name="$OPTARG"
      ;;
      s) source_url="$OPTARG"
      ;;
      h) 
        echo "Usage"
        echo "  list_nuget_package_versions [-p <package-name>] [-s <source-url>] [-h]"
        echo "  -p: Name of the package to search for"
        echo "  -s: Source url to search for the package, defaults to https://api.nuget.org/v3/index.json"
        echo "  -h: Show help"
        exit 0
        ;;
      \?) echo "Invalid option -$OPTARG" >&2
      ;;
    esac
  done
}

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
        echo "  create_nuget_registry [-d <registry-directory>] [-n <registry-name>] [-h]"
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
      check_exists=$(dotnet nuget list source | grep "$registry_name [Enabled]")
      if [ ! -n "$check_exists" ]; then
        dotnet nuget add source $registry_directory --name $registry_name
      fi
  else
      # Create the folder
      mkdir "$registry_directory"
      echo "Folder '$registry_directory' created."
      check_exists=$(dotnet nuget list source | grep "$registry_name [Enabled]")
      if [ ! -n "$check_exists" ]; then
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

  install_software xmlstarlet &> /dev/null;
  value=$(xmlstarlet sel -t -v "//IsPackable" $project_path)
  if [ "$value" = "true" ]; then
    return 1
  else
    return 0
  fi
}

is_silo_project() {
  local project_path=$1

  install_software xmlstarlet &> /dev/null;
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

  install_software xmlstarlet &> /dev/null;
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
  local project_paths=()
  local version="1.0.0"
  local configuration="Release"
  local registry_name="suhdev"
  local push=true
  local force_pack=false

  while getopts "v:c:p:r:f:ih" opt; do
    echo "opt $opt";
    case $opt in
      v) 
        version="$OPTARG"
      ;;
      c) 
        configuration="$OPTARG"
      ;;
      p)
        project_paths+=("$OPTARG")
      ;;
      i)
        push=true
      ;;
      r)
        registry_name="$OPTARG"
      ;;
      f)
        force_pack=true
      ;;
      h)
        echo "Usage"
        echo "  dotnet-build.sh cs-proj-path [-v <version>] [-h]"
        echo "  -v: Version to use (semver)"
        echo "  -c: Configuration to build (Debug, Release)"
        echo "  -h: Show help"
        echo "  -i: Push to registry"
        echo "  -r: Registry name"
        echo "  -f: Force pack"
        return 0
        ;;
      \?) echo "Invalid option -$OPTARG" >&2
      ;;
    esac
  done
  # check if standard input has input 
  if [[ -p /dev/stdin ]]; then
    # read each line into an array
    while IFS= read -r line; do
        project_paths+=("$line")
    done
  fi

  # check if project_path is not a file or project_paths is empty 
  if [ ${#project_paths[@]} -eq 0 ]; then
    local project_path=$(find_first_file_in_parent_directories_that_match_extension csproj)
    project_paths=($project_path)
  fi
  # if [ ! -f "$project_path" ]; then
  #   project_path=$(find_first_file_in_parent_directories_that_match_extension csproj)
    
  # fi


  # loop through project_paths and build them
  for project_path in "${project_paths[@]}"; do
    local outputdir="$(dirname $project_path)/bin/Release"
    is_packable_project $project_path
    retval=$?

    # check if either is packable or force_path is true 
    if [[ $force_pack == true ]] || [[ $retval -eq 1 ]]; then
      echo "Building $project_path"
      dotnet restore $project_path
      dotnet pack "$project_path" -c "$configuration" -p:PackageVersion=$version -o $outputdir
      # check if push is true then push to source
      if [[ $push == true ]]; then
        dotnet nuget push "$outputdir/*.nupkg" --source $registry_name
      fi
    fi
  done
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
  local csproj_path=""
  local version="1.0.0"
  local image_name=""
  local registry_name=""
  local outputdir=""

  while getopts "p:v:i:r:o:h" opt; do
    case $opt in
      v) 
        version="$OPTARG"
        ;;
      i)
        image_name="$OPTARG"
        ;;
      r)
        registry_name="$OPTARG"
        echo "Registry name: $registry_name"
        ;;
      o)
        outputdir="$OPTARG"
        ;;
      p)
        csproj_path="$OPTARG"
        ;;
      h)
        echo "Usage"
        echo "  build-dotnet-docker-image.sh cs-proj-path [-v <version>] [-h]"
        echo "  -v: Version to update (major, minor, patch)"
        echo "  -h: Show help"
        return 0
        ;;
      \?) echo "Invalid option -$OPTARG" >&2
        ;;
    esac
  done


  # if file does not exist exit 
  if [ ! -f "$csproj_path" ]; then
    echo "Project file could not be found at $csproj_path"
    return 1
  fi

  csproj_basename=$(basename $csproj_path)
  docker_file_path="$(dirname $csproj_path)/Dockerfile"
  csproj_path_no_extension="${csproj_path%.*}"
  dll_name="$(basename $csproj_path_no_extension).dll"
  if [ -z "$image_name" ]; then
    image_name=$(basename $csproj_path_no_extension | tr '[:upper:]' '[:lower:]')
    image_name=${image_name//./-}
  fi

  if [ -z "$outputdir" ]; then
    outputdir="$(dirname $csproj_path)/bin/Release"
  fi

  if [ ! -f "$docker_file_path" ]; then
    echo "Dockerfile not found at $docker_file_path"
    return 1
  fi

  dotnet_build_service $csproj_path -v $version -c Release
  local image_tag="$image_name:$version" 
  DOCKER_BUILDKIT=0 docker buildx build --platform linux/amd64 -t $image_tag -f $docker_file_path \
    --build-arg DLL_NAME=$dll_name \
    $outputdir
  
  # check if registy isn't empty 
  if [ ! -z "$registry_name" ]; then
    # check if registry isn't local registry 
    docker tag $image_tag "$registry_name/$image_tag"
    docker push "$registry_name/$image_tag"
  fi
}

add_dotnet_dockerfile_to_project() {
  local project_path=$1

  if [ -z "$project_path" ]; then
    project_path=$(realpath .)
  fi

  local destination_path="$project_path/Dockerfile"

  if [ -f "$destination_path" ]; then
    echo "Dockerfile already exists at $destination_path"
    return 1
  fi

  cp "$samples_path/dotnet.Dockerfile" "$destination_path"
}

add_dotnet_silo_dockerfile_to_project() {
  local project_path=$1

  if [ -z "$project_path" ]; then
    project_path=$(realpath .)
  fi

  local destination_path="$project_path/Dockerfile"

  if [ -f "$destination_path" ]; then
    echo "Dockerfile already exists at $destination_path"
    exit 1
  fi

  cp "$samples_path/dotnet.silo.Dockerfile" "$destination_path"
}

make_package_project() {
  local csproj_path=$1

  if [ -z "$csproj_path" ]; then
    csproj_path=$(find_first_file_in_parent_directories_that_match_extension csproj)
  fi

  install_software xmlstarlet

  add_element_with_value_if_not_exist "IsPackable" "true" "/Project/PropertyGroup[last()]" $csproj_path
}

make_silo_project() {
  local csproj_path=$1

  if [ -z "$csproj_path" ]; then
    csproj_path=$(find_first_file_in_parent_directories_that_match_extension csproj)
  fi

  install_software xmlstarlet

  add_element_with_value_if_not_exist "IsSiloe" "true" "/Project/PropertyGroup[last()]" $csproj_path

  add_dotnet_silo_dockerfile_to_project $csproj_path
}

make_service_project() {
  local csproj_path=$1

  if [ -z "$csproj_path" ]; then
    csproj_path=$(find_first_file_in_parent_directories_that_match_extension csproj)
  fi

  install_software xmlstarlet

  add_element_with_value_if_not_exist "IsService" "true" "/Project/PropertyGroup[last()]" $csproj_path

  add_dotnet_dockerfile_to_project $csproj_path
}

make_dockerized_project() {
  local csproj_path=$1

  if [ -z "$csproj_path" ]; then
    csproj_path=$(find_first_file_in_parent_directories_that_match_extension csproj)
  fi

  install_software xmlstarlet

  add_element_with_value_if_not_exist "IsDockerized" "true" "/Project/PropertyGroup[last()]" $csproj_path

  add_dotnet_dockerfile_to_project $(dirname $csproj_path)
}

create_solution_build_directory() {
  local solution_directory=$1

  if [ -z "$solution_directory" ]; then
    solution_directory=$(realpath .)
  fi

  local build_directory_sample_path="$samples_path/Directory.Build.props"

  cp $build_directory_sample_path "$solution_directory/Directory.Build.props"
}

add_dependency_to_project() {
  local dependency_name="" 
  local dependency_version=""

  while getopts "p:v:h" opt; do
    case $opt in
      v) 
        dependency_version="$OPTARG"
        ;;
      p)
        dependency_name="$OPTARG"
        ;;
      h)
        echo "Usage"
        echo "  add-dependency-to-project.sh dependency-name [-v <version>] [-h]"
        echo "  -v: Version to update (major, minor, patch)"
        echo "  -h: Show help"
        return 1
        ;;
      \?) echo "Invalid option -$OPTARG" >&2
        ;;
    esac
  done
  
  local sln_file_path=$(find_first_file_in_parent_directories_that_match_extension sln)
  if [ -z $sln_file_path ]; then
    echo "Could not find sln file"
    return 1
  fi
  local solution_directory=$(dirname $sln_file_path)

  local csproj_path=$(find_first_file_in_parent_directories_that_match_extension csproj)
  local variable_name=${dependency_name//./}

  if [ -z $csproj_path ]; then
    echo "Could not find csproj file"
    return 1
  fi

  local project_path=$(dirname $csproj_path)
  local directory_build_props_path="$solution_directory/Directory.Build.props"

  if [ ! -f "$directory_build_props_path" ]; then
    create_solution_build_directory "$solution_directory"
  fi

  install_software xmlstarlet &> /dev/null

  local exist_version=$(xmlstarlet sel -N x="http://schemas.microsoft.com/developer/msbuild/2003" -t -v "/x:Project/x:PropertyGroup/x:$variable_name" $directory_build_props_path)

  exist_version=${exist_version//[[:space:]]/}
  if [ -n "$exist_version" ]; then
    dependency_version=$exist_version
  else 
    xmlstarlet ed -L -N x="http://schemas.microsoft.com/developer/msbuild/2003" -s "/x:Project/x:PropertyGroup[last()]" -t elem -n "$variable_name" -v "$dependency_version" $directory_build_props_path
  fi

  local exist_dependency=$(xmlstarlet sel -t -v "//PackageReference[@Include='$dependency_name']/@Version" $csproj_path)
  
  if [ -z "$exist_dependency" ]; then
    # add PackageReference to csproj
    add_element_with_value_if_not_exist "ItemGroup" "" "/Project" $csproj_path
    xmlstarlet ed -L -s "/Project/ItemGroup[last()]" -t elem -n "PackageReference" -v "" $csproj_path
    xmlstarlet ed -L -s "/Project/ItemGroup[last()]/PackageReference[last()]" -t attr -n "Include" -v $dependency_name $csproj_path
    xmlstarlet ed -L -s "/Project/ItemGroup[last()]/PackageReference[last()]" -t attr -n "Version" -v "\$($variable_name)" $csproj_path
  else 
    xmlstarlet ed -L -u "/Project/ItemGroup/PackageReference[@Include='$dependency_name']/@Version" -v "\$($variable_name)" $csproj_path
  fi

}

get_dependencies_version() {
  local $csproj_path=$1

  xmlstarlet sel -t -v "/Project/ItemGroup/PackageReference/@Include" $csproj_path -i 
}