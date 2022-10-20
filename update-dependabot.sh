#!/bin/bash

insert_output(){
    pe="- package-ecosystem:"
    d="directory:"
    s="schedule:"
    i="interval: \"weekly\""
    tb="target-branch: \"dev\"" 
            printf '%s "%s"\n' "$pe" "$2">> ./.github/dependabot.yml
            printf '\t%s "%s/" \n' "$d" "$1" >> ./.github/dependabot.yml
            printf '\t%s\n' "$s" >> ./.github/dependabot.yml
            printf '\t\t %s\n' "$i" >> ./.github/dependabot.yml
            printf '\t%s\n' "$tb" >> ./.github/dependabot.yml
}

walk_dir () {
    rel_path="$1"
    base_dir="$2"

    if [[ $1 =~ ^.*$2 ]]; then
        rel_path="${pathname/${BASH_REMATCH[0]}/""}"
    fi
    for pathname in "$1"/*; do
        b=$(basename $pathname)
        if [ -d "$pathname" ]; then
            walk_dir "$pathname" "$base_dir"
        # npm
        elif [[ $b == "package.json" ]]; then
            insert_output $(dirname $rel_path) "npm"
            printf '\t%s\n' "allow:" >> ./.github/dependabot.yml
            printf '\t%s\n' "- dependency-type: direct" >> ./.github/dependabot.yml
            printf '\t%s\n' "- dependency-type: production" >> ./.github/dependabot.yml
        # docker
        elif [[ $b == "Dockerfile" ]]; then
            insert_output "$rel_path" "docker"
        # nuget
        elif [[ $b =~ \.sln$ ]]; then
            insert_output "$rel_path" "nuget"
        # composer
        elif [[ $b == "composer.json" ]]; then
            insert_output "$rel_path" "composer"
        # bundler
        elif [[ $b == "Gemfile" ]]; then
            insert_output "$rel_path" "bundler"
        # cargo
        elif [[ $b == "Cargo.toml" ]]; then
            insert_output "$rel_path" "cargo"
        else 
            true
        fi
    done
}
mkdir .github
touch $PWD/.github/dependabot.yml
printf '%s\n' "version: 2" > ./.github/dependabot.yml
printf '%s\n' "updates:" >> ./.github/dependabot.yml
insert_output "" "github-actions"
chmod 755 $PWD/.github/dependabot.yml
   
BASE_DIR=$(basename $PWD)
echo "Base directory is: $BASE_DIR"
DOWNLOADING_DIR=$PWD

walk_dir "$DOWNLOADING_DIR" "$BASE_DIR"