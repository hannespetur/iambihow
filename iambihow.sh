# displays files in $1 not in $2
_cmp_dirs(){
    rsync --exclude '.*' -avunc "$1" "$2" | tail -n +3 | head -n -3
}

_get_current_branch(){
    readlink .iambihow/HEAD | xargs basename
}

_get_current_commit(){
    readlink -f .iambihow/HEAD | xargs basename
}

# Initialize iambihow in current directory. Takes no arguments.
iambihow_init() {
    timestamp=$(date +"%y%m%d-%H%M%S")
    mkdir -p .iambihow/{branches,staging_area} .iambihow/history/${timestamp}
    ln --force -s ../history/${timestamp} .iambihow/branches/master
    ln --force -s branches/master .iambihow/HEAD
    echo "iambihow directory initialized."
}

# Takes in one argument which is the file or a folder to add to the staging area
iambihow_add(){
    if [[ ! -d .iambihow/staging_area ]]; then echo "Not a iambihow project." >&2; return; fi
    if [[ $(dirname "$1") != "." ]]; then echo "Only add from current directory." >&2; return; fi
    if [[ -z $1 ]]; then 1="." >&2; return; fi

    rsync -a "$1" --exclude '.iambihow' ./.iambihow/staging_area/
}

iambihow_commit(){
    n_files=$(_cmp_dirs .iambihow/staging_area/ ./ | wc -l)
    if [[ "$n_files" -eq 0 ]]; then echo "Nothing added to commit but untracked files are:"; echo ""
                                    _cmp_dirs ./ .iambihow/staging_area/;
                                    return; fi
    timestamp=$(date +"%y%m%d-%H%M%S")
    rsync -a .iambihow/staging_area/ .iambihow/history/${timestamp}
    rm -f .iambihow/HEAD && ln --force -s history/${timestamp} .iambihow/HEAD
}

iambihow_status(){
    branch=$(_get_current_branch)
    commit=$(_get_current_commit)
    echo "You are on commit: $commit"

    if [[ "${branch}" -eq "${commit}" ]]; then echo "You are not on a branch"
    else echo -e "You are on branch: ${branch}"
    fi

    echo ""
    echo "Stuff in working directory:"
    find . -maxdepth 1 | grep -v '^\./\.\|^\.$'

    echo ""
    echo "Stuff in staging area:"
    find .iambihow/staging_area/ -maxdepth 1 | grep -v '^\.iambihow/staging_area/$'
    #find .iambihow/staging_area/ -maxdepth 1 | grep -v 'iambihow/staging_area/'

    echo ""
    echo "Stuff in history (at HEAD)"
    find .iambihow/HEAD/ -maxdepth 1 | grep -v '^\.iambihow/HEAD/$'

    echo ""
    echo "Stuff in working directory that is different from the staging area."
    rsync -avunc .iambihow/staging_area/ .iambihow/HEAD/ | tail -n +3 | head -n -3

    echo ""
    echo "Stuff in staged area that is different from the history."
    rsync -avunc .iambihow/staging_area/ .iambihow/HEAD/ | tail -n +3 | head -n -3
}
