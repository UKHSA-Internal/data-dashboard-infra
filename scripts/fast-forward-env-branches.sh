#!/bin/bash 

env_branches=("env/dev/dev"
              "env/dev/dpd"
              "env/test/test"
              "env/test/perf"
              "env/uat/uat"
              "env/uat/staging"
              "env/auth-dev/auth-dev"
              "env/auth-test/auth-test"
              "env/auth-test/auth-perf"
              "env/auth-uat/auth-uat")

for branch in ${env_branches[@]}; do 
    env=$(echo $branch | cut -d : -f 1 | xargs basename)
    
    if git merge-base --is-ancestor origin/$branch main
    then
        echo "Fast forward merge is possible to branch $branch"
        echo 

        git checkout $branch
        git merge main --ff-only
        git push
        echo

        if [ $CI ]; then
            echo "deploy_$env=true" >> "$GITHUB_OUTPUT"
        fi
    else
        echo "Fast forward merge is not possible to branch $branch"
        echo

        if [ $CI ]; then
            echo "deploy_$env=false" >> "$GITHUB_OUTPUT"
        fi
    fi
done
