curr_dir=$(dirname $0)
template=$(cat $curr_dir/k8s/service.yaml)
chartname="${imagename//./-}"
template="${template//imagename/$imagename}"
template="${template//chartname/$chartname}"

echo "${template//imagename/$imagename}" | kubectl apply -f -

# ------ 
curr_dir=$(dirname $line)
kubectl apply -f $(dirname $line)/chart.yaml