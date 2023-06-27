#!/bin/bash 

env_branchs=("env/uat/uat"
             "env/test/pen"
             "env/test/perf"
             "env/test/test"
             "env/dev/dev")

for branch in ${env_branchs[@]}; do
    if git merge-base --is-ancestor origin/$branch main
    then
        echo "Fast forward merge is possible to branch $branch"
        echo 

        git checkout $branch
        git merge master --ff-only
        git push
        
        echo
    else
        echo "Fast forward merge is not possible to branch $branch"
        echo
    fi
done
