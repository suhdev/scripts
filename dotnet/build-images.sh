find-all-dotnet-projects | while read line; do
  outputdir="$(dirname $line)/bin/Release"
  filename=$(basename $line) 
  filename_no_ext="${filename%.*}" 
  imagename=$(echo "$filename_no_ext" | tr '[:upper:]' '[:lower:]')
  if grep -q '<BuildDocker>true</BuildDocker>' "$line"; then
    build-docker -p $line -v "1.0.0"
  fi
done

build-docker-images-for-all-projects() {
  find-all-dotnet-projects-with-docker | while read line; do
    build-docker $line
  done
}

find-all-dotnet-projects() {
  find . -name '*.csproj' -type f -exec echo {} \;
}

find-all-dotnet-projects-with-docker() {
  find . -name '*.csproj' -type f -exec echo {} \; | while read line; do
    if grep -q '<BuildDocker>true</BuildDocker>' "$line"; then
      echo $line
    fi
  done
}

build-docker() {
  local line=""

  # iterate through parameters and update version
  while getopts "p:v:f:h" opt; do
    case $opt in
      p)
        line=$(realpath $OPTARG)
        ;;
      f)
        dockerfilepath=$OPTARG
        ;;
      h)
        echo "Usage: build-images.sh [-p <project version>] [-v <docker image version>] [-h]"
        exit 0
        ;;
      \?)
        echo "Invalid option: -$OPTARG" >&2
        exit 1
        ;;
    esac
  done

  local outputdir="$(dirname $line)/bin/Release"
  local dockerfilepath="$(dirname $line)/Dockerfile"
  local filename=$(basename $line) 
  local filename_no_ext="${filename%.*}" 
  local imagename=$(echo "$filename_no_ext" | tr '[:upper:]' '[:lower:]')

  dotnet restore "$line"
  dotnet publish "$line" -c Release -o $outputdir
  dotnet nuget push "$outputdir/*.nupkg" --source $registry_name

  echo "Building image $imagename:1.0.0"

  if [ ! -f "$dockerfilepath" ]; then
    echo "Dockerfile not found at $dockerfilepath"
    exit 1
  fi
}

build() {
  local line=$1
  local version="1.0.0"

  # iterate through parameters and update version
  while getopts "p:v:h" opt; do
    case $opt in
      p)
        echo "Updating project version to $OPTARG"
        line=$OPTARG
        ;;
      v)
        echo "Updating docker image version to $OPTARG"
        version=$OPTARG
        ;;
      h)
        echo "Usage: build-images.sh [-p <project version>] [-v <docker image version>] [-h]"
        exit 0
        ;;
      \?)
        echo "Invalid option: -$OPTARG" >&2
        exit 1
        ;;
    esac
  done

  
  dotnet restore "$line"
  dotnet publish "$line" -c Release -o $outputdir
  echo "Building image $imagename:1.0.0"
  dockerfilepath="$(dirname $0)/Dockerfile"
  if [ ! -f "$dockerfilepath" ]; then
    dockerfilepath="$(dirname )
    echo "Dockerfile not found at $dockerfilepath"
    exit 1
  fi
  DOCKER_BUILDKIT=0 docker build -t $imagename:1.0.0 -f "$(dirname $0)/Dockerfile" --build-arg APP=$filename_no_ext $outputdir
}