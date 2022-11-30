#!/bin/bash
insert_registries(){
    dep=$1
    type=$2
    url=$3
    password_or_token=$4
    username=$5
    payload=''
    # payload for token based authentication
    payload_token="\\n  $dep\:\\n    type\: $type\\n    url\: $url\\n    token\: $password_or_token"
    # payload for username/password based authentication
    payload_u_p="\\n  $dep\:\\n    type\: $type\\n    url\: $url\\n    username\: $username\\n    password\: $password_or_token"
    if [[ $dep == "npm" ]]; then
        payload=$payload_token
    elif [[ $dep == "composer" || $dep == "ali-gitlab" || $dep == "aristek-gitlab" || $type == "docker-registry" ]]; then
        payload=$payload_u_p
    fi
    # payload="registries\:\\n  test\:\\n    type\: test\\n    url\: test\\n    username\: test\\n    password\: test"
    # use the sed command to replace the line under the first occurence of "registries: " with the payload
    sed -i "0,/^registries\: /s//registries\: $payload/" .github/dependabot.yml
    # sed -i "/registries\: /a $payload" .github/dependabot.yml
    # sed -i "s/registries\:/registries\:\\n$payload/n1" .github/dependabot.yml  
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
            printf '    %s\n' "  - aristek-gitlab" >> ./.github/dependabot.yml
            printf '    %s\n' "  - ali-gitlab" >> ./.github/dependabot.yml
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
if [[ $composer_reg_flag || $npm_reg_flag || $docker_reg_flag ]]; then
    payload="registries: "
    sed -i "s/version: 2/version: 2\\n$payload/g" .github/dependabot.yml 
fi
if [[ $composer_reg_flag == true ]]; then
    insert_registries "composer" "composer-repository" "https\:\/\/satis.acceleratelearning.com" "\${{secrets.GITLAB_ACCELERATELEARNING_TOKEN}}" "any"
    insert_registries "ali-gitlab" "git" "https\:\/\/gitlab.acceleratelearning.com\/acceleratelearning" "\${{secrets.GITLAB_ACCELERATELEARNING_TOKEN}}" "ali-gitlab"
    insert_registries "aristek-gitlab" "git" "https\:\/\/git.aristeksystems.com\/acceleratelearning" "\${{secrets.GIT_ARISTEKSYSTEMS_TOKEN}}" "aristek-gitlab"
fi
if [[ $npm_reg_flag == true ]]; then
    insert_registries "npm-npmjs" "npm-registry" "https\:\/\/registry.npmjs.org" "\${{secrets.NPM_TOKEN}}"
fi
if [[ $docker_reg_flag == true ]]; then
    echo "in docker reg flag"
    insert_registries "ecr-docker" "docker-registry" "https\:\/\/669462986110.dkr.ecr.us-east-2.amazonaws.com" "\${{secrets.DOCKER_ECR_REGISTRY_PASSWORD}}" "\${{secrets.DOCKER_ECR_REGISTRY_USERNAME}}"
fi