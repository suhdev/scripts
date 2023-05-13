add_dotnet_dockerfile_to_project() {
  local samples_path="$(dirname $0)/../samples"
  local project_path=$1

  if [ -z "$project_path" ]; then
    project_path=$(realpath .)
  fi

  local destination_path="$project_path/Dockerfile"

  if [ -f "$destination_path" ]; then
    echo "Dockerfile already exists at $destination_path"
    exit 1
  fi

  cp "$samples_path/dotnet.Dockerfile" "$destination_path"
}

add_dotnet_silo_dockerfile_to_project() {
  local samples_path="$(dirname $0)/../samples"
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