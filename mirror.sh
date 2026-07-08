#!/bin/bash

src_repo="$1"
repo_name=${src_repo##*/}

mirror() {
    src_ref=$(git ls-remote "https://github.com/$src_repo.git" HEAD | awk '{ print $1}')
    dst_ref=$(git ls-remote "https://cnb.cool/$CNB_USER/vim/$repo_name.git" HEAD | awk '{ print $1}')
    if [[ "${src_ref}" != "${dst_ref}" ]]; then
        echo "Syncing $src_repo to $repo_name"
        git clone --bare "https://github.com/$src_repo.git" src
        git config --global user.email github-actions@github.com
        git config --global user.name github-actions
        git -C src push --mirror "https://cnb:$PAT@cnb.cool/$CNB_USER/vim/$repo_name.git"
        /bin/rm -rf src
    else
        echo "No need to sync $src_repo"
    fi
}

mirror
