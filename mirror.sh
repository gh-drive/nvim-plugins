#!/bin/bash

src_repo="$1"
repo_name=${src_repo##*/}
# create repo
create() {
    curl -s --request POST \
        --url 'https://e.coding.net/open-api/?Action=CreateGitDepot&action=CreateGitDepot' \
        --header "Accept: application/json" \
        --header "Authorization: Bearer $PAT" \
        --header "Content-Type: application/json" \
        --data "{
        \"ProjectId\": \"13394361\",
        \"DepotName\": \"$repo_name\",
        \"Description\": \"Mirror from https://github.com/$src_repo\",
        \"Shared\": true
        }" > /dev/null || true
}

get_repo_id(){
    curl -s --request POST \
        --url 'https://e.coding.net/open-api/DescribeDepotByNameInfo?Action=DescribeDepotByNameInfo' \
        --header 'Accept: application/json' \
        --header "Authorization: Bearer $PAT" \
        --header 'Content-Type: application/json' \
        --data "{
        \"DepotName\": \"$repo_name\",
        \"ProjectName\": \"VIM\",
        \"TeamGk\": \"$CODING_USER\"
        }" | jq -r '.Response.Depot.Id'
}

change_default_branch() {
    local branch="$1"
    local repo_id="$(get_repo_id)"
    curl -s --request POST \
        --url 'https://e.coding.net/open-api/ModifyDefaultBranch?Action=ModifyDefaultBranch' \
        --header 'Accept: application/json' \
        --header "Authorization: Bearer $PAT" \
        --header 'Content-Type: application/json' \
        --data "{
        \"BranchName\": \"$branch\",
        \"DepotId\": \"$repo_id\",
        \"UserId\": \"8385456\"
        }" > /dev/null || true
}

mirror() {
    src_ref=$(git ls-remote "https://github.com/$src_repo.git" HEAD | awk '{ print $1}')
    dst_ref=$(git ls-remote "https://e.coding.net/$CODING_USER/vim/$repo_name.git" HEAD | awk '{ print $1}')
    if [[ "${src_ref}" != "${dst_ref}" ]]; then
        echo "Syncing $src_repo to $repo_name"
        git clone --bare "https://github.com/$src_repo.git" src
        git config --global user.email github-actions@github.com
        git config --global user.name github-actions
        git -C src push --mirror "https://aAWBDMOVjO:$PAT@e.coding.net/$CODING_USER/vim/$repo_name.git"
        default_branch="$(sed 's|ref: refs/heads/||' src/HEAD)"
        change_default_branch "$default_branch"
        /bin/rm -rf src
    else
        echo "No need to sync $src_repo"
    fi
}

create
mirror
