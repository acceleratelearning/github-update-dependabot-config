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
    payload_docker="registries\:\\n  ecr-docker\:\\n    type\: $dep-$type\\n    url\: $url\\n    username\: $username\\n    password\: $password"
    if [[ $dep == "npm" ]]; then
        payload=$payload_npm
    elif [[ $dep == "composer" ]]; then
        payload=$payload_composer
    elif [[ $type == "docker" ]]
        payload=$payload_docker
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
            printf '  %s "%s"\n' "$pe" "$2">> ./.github/dependabot.yml
            printf '    %s "%s" \n' "$d" "$1" >> ./.github/dependabot.yml
            printf '    %s\n' "$s" >> ./.github/dependabot.yml
            printf '       %s\n' "$i" >> ./.github/dependabot.yml
            printf '    %s\n' "$tb" >> ./.github/dependabot.yml
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
            insert_updates $(dirname $rel_path) "npm"
            printf '    %s\n' "allow:" >> ./.github/dependabot.yml
            printf '    %s\n' "- dependency-type: direct" >> ./.github/dependabot.yml
            printf '    %s\n' "- dependency-type: production" >> ./.github/dependabot.yml
            printf '    %s\n' "registries: " >> ./.github/dependabot.yml
            printf '    %s\n' "  - npm-npmjs" >> ./.github/dependabot.yml
            npm_reg_flag=true
        # docker
        elif [[ $b == "Dockerfile" ]]; then
            insert_updates $(dirname $rel_path) "docker"
            printf '    %s\n' "registries: " >> ./.github/dependabot.yml
            printf '    %s\n' "  - ecr-docker" >> ./.github/dependabot.yml
            docker_reg_flag=true
        # nuget
        elif [[ $b =~ \.sln$ ]]; then
            insert_updates $(dirname $rel_path) "nuget"
        # composer
        elif [[ $b == "composer.lock" ]]; then
            insert_updates $(dirname $rel_path) "composer"
            printf '    %s\n' "registries: " >> ./.github/dependabot.yml
            printf '    %s\n' "  - composer" >> ./.github/dependabot.yml
            composer_reg_flag=true
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
composer_reg_flag=false
npm_reg_flag=false
docker_reg_flag=false

mkdir .github
touch $PWD/.github/dependabot.yml
printf '%s\n' "version: 2" > ./.github/dependabot.yml
printf '%s\n' "updates:" >> ./.github/dependabot.yml
insert_updates "/" "github-actions"
chmod 755 $PWD/.github/dependabot.yml
   
BASE_DIR=$(basename $PWD)
echo "Base directory is: $BASE_DIR"
DOWNLOADING_DIR=$PWD

walk_dir "$DOWNLOADING_DIR" "$BASE_DIR"

if [[ $composer_reg_flag == true ]]; then
    insert_registries "composer" "repository" "https\:\/\/satis.acceleratelearning.com"
fi
if [[ $npm_reg_flag == true ]]; then
    insert_registries "npm" "registry" "https\:\/\/registry.npmjs.org"
fi
if [[ $docker_reg_flag == true ]]; then
    insert_registries "ecr" "docker" "https\:\/\/669462986110.dkr.ecr.us-east-2.amazonaws.com"
fi