add_element_with_value_if_not_exist() {
  local element_name=$1
  local element_value=$2
  local xpath_expression=$3
  local file_path=$4


  if [[ -z "$element_name" ]]; then
    echo "element_name is required"
    return 1
  fi

  if [[ -z "$element_value" ]]; then
    echo "element_value is required"
    return 1
  fi

  if [[ -z "$xpath_expression" ]]; then
    echo "xpath_expression is required"
    return 1
  fi

  install_software xmlstarlet &> /dev/null

  local exist_element=$(xmlstarlet sel -t -v "$xpath_expression/$element_name" $file_path)

  if [[ -z "$exist_element" ]]; then
    xmlstarlet ed -L -s "$xpath_expression" -t elem -n "$element_name" -v "$element_value" $file_path
  fi
}