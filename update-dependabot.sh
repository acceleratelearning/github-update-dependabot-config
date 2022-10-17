#!/bin/bash

insert_output(){
    pe="package-ecosystem:"
    d="directory:"
    s="schedule:"
    i="interval: weekly"
    tb='target-branch: dev' 
            printf '\t%s "%s"\n' "$pe" "$2">> ./.github/dependabot.yml
            printf '\t%s "%s/" \n' "$d" "$1" >> ./.github/dependabot.yml
            printf '\t%s\n' "$s" >> ./.github/dependabot.yml
            printf '\t\t %s\n' "$i" >> ./.github/dependabot.yml
            printf '\t%s\n' "$tb" >> ./.github/dependabot.yml
}

walk_dir () {

    for pathname in "$1"/*; do
        b=$(basename $pathname)
        echo $b
        if [ -d "$pathname" ]; then
            walk_dir "$pathname"
        # npm
        elif [[ $b == "package.json" ]]; then
            insert_output $(dirname $pathname) "npm"
            printf '\t%s\n' "allow:" >> ./.github/dependabot.yml
            printf '\t%s\n' "- dependency-type: direct" >> ./.github/dependabot.yml
            printf '\t%s\n' "- dependency-type: production" >> ./.github/dependabot.yml
        # docker
        elif [[ $b == "Dockerfile" ]]; then
            insert_output $(dirname $pathname) "docker"
        # npm
        elif [[ $b == "Dockerfile" ]]; then
            insert_output $(dirname $pathname) "docker"
        # nuget
        elif [[ $b =~ \.sln$ ]]; then
            insert_output $(dirname $pathname) "nuget"
        # composer
        elif [[ $b == "composer.json" ]]; then
            insert_output $(dirname $pathname) "composer"
        # bundler
        elif [[ $b == "Gemfile" ]]; then
            insert_output $(dirname $pathname) "bundler"
        # cargo
        elif [[ $b == "Cargo.toml" ]]; then
            insert_output $(dirname $pathname) "cargo"
        else 
            true
        fi
    done
}
mkdir -m .github
touch $PWD/.github/dependabot.yml
printf '%s\n' "version: 2" > ./.github/dependabot.yml
printf '%s\n' "updates:" >> ./.github/dependabot.yml
insert_output "" "github-actions"
chmod 755 $PWD/.github/dependabot.yml

DOWNLOADING_DIR=$PWD

walk_dir "$DOWNLOADING_DIR"
