# util_path="$(dirname $0)/util/*"
export samples_path="$(dirname $0)/samples"
setopt +o nomatch
for file in $(dirname $0)/util/*; do
    source $file
done