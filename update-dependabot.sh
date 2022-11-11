#!/bin/bash
insert_registries(){
    v="version: 2"
    r="registries:"
    dep=$1
    type=$2
    url=$3
    payload=''
    token='${{secrets.NPM_TOKEN}}'
    username='any'
    password='${{secrets.GITLAB_ACCELERATELEARNING_TOKEN}}'
    payload_npm="registries\:\\n  npm-npmjs\:\\n    type\: $dep\-$type\\n    url\: $url\\n    token\: $token"
    payload_composer="registries\:\\n  composer\:\\n    type\: $dep-$type\\n    url\: $url\\n    username\: $username\\n    password\: $password"
    if [[ $dep == "npm" ]]; then
        payload=$payload_npm
    elif [[ $dep == "composer" ]]; then
        payload=$payload_composer
    fi
    # use the sed command to replace the line under "version: 2" with the payload
    sed -i "s/version: 2/$v\\n$payload/g" .github/dependabot.yml
}
insert_updates(){
    pe="- package-ecosystem:"
    d="directory:"
    s="schedule:"
    i="interval: \"weekly\""
    tb="target-branch: \"dev\"" 
            printf '%s "%s"\n' "$pe" "$2">> ./.github/dependabot.yml
            printf '\t%s "%s" \n' "$d" "$1" >> ./.github/dependabot.yml
            printf '\t%s\n' "$s" >> ./.github/dependabot.yml
            printf '\t\t %s\n' "$i" >> ./.github/dependabot.yml
            printf '\t%s\n' "$tb" >> ./.github/dependabot.yml
}

walk_dir () {
    rel_path="$1"
    base_dir="$2"
    
    for pathname in "$1"/*; do
        if [[ $1 =~ ^.*$2 ]]; then
            rel_path="${pathname/${BASH_REMATCH[0]}/""}"
        fi
        b=$(basename $pathname)
        if [ -d "$pathname" ]; then
            walk_dir "$pathname" "$base_dir"
        # npm
        elif [[ $b == "package.json" ]]; then
            echo $rel_path
            echo $(dirname $rel_path)
            insert_updates $(dirname $rel_path) "npm"
            printf '\t%s\n' "allow:" >> ./.github/dependabot.yml
            printf '\t%s\n' "- dependency-type: direct" >> ./.github/dependabot.yml
            printf '\t%s\n' "- dependency-type: production" >> ./.github/dependabot.yml
            insert_registries "npm" "registry" "https\:\/\/registry.npmjs.org"
        # docker
        elif [[ $b == "Dockerfile" ]]; then
            insert_updates $(dirname $rel_path) "docker"
        # nuget
        elif [[ $b =~ \.sln$ ]]; then
            insert_updates $(dirname $rel_path) "nuget"
        # composer
        elif [[ $b == "composer.json" ]]; then
            insert_updates $(dirname $rel_path) "composer"
            insert_registries "composer" "repository" "https\:\/\/satis.acceleratelearning.com"
        # bundler
        elif [[ $b == "Gemfile" ]]; then
            insert_updates $(dirname $rel_path) "bundler"
        # cargo
        elif [[ $b == "Cargo.toml" ]]; then
            insert_updates $(dirname $rel_path) "cargo"
        else 
            true
        fi
    done
}
mkdir .github
touch $PWD/.github/dependabot.yml
printf '%s\n' "version: 2" > ./.github/dependabot.yml
printf '%s\n' "updates:" >> ./.github/dependabot.yml
insert_updates "/" "github-actions"

chmod 755 $PWD/.github/dependabot.yml
   
BASE_DIR=$(basename $PWD)
echo "Base directory is: $BASE_DIR"
DOWNLOADING_DIR=$PWD

walk_dir "$DOWNLOADING_DIR" "$DOWNLOADING_DIR"