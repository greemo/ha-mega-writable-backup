#!/usr/bin/with-contenv bashio
set -euo pipefail

export HOME=/data
export TERM=xterm

_folder_url=$(bashio::config 'folder_url')
_auth_key=$(bashio::config 'auth_key')
_keep=$(bashio::config 'keep')
_sync_minutes=$(bashio::config 'sync_minutes')

if [[ "${_auth_key}" == *":"* && "${_auth_key}" != http* ]]; then
    _token_body="${_auth_key}"
    _auth_key="${_token_body##*:}"
    if [[ -z "${_folder_url}" ]]; then
        _handle_key="${_token_body%:*}"
        _folder_url="https://mega.nz/folder/${_handle_key}"
    fi
fi

_wait_for_credentials() {
    bashio::log.warning "Set the Mega folder URL and auth key in the add-on options, then restart."
    while true; do
        sleep 3600
    done
}

if [[ -z "${_folder_url}" || -z "${_auth_key}" ]]; then
    _wait_for_credentials
fi

_wait_for_server() {
    local _i
    for _i in $(seq 1 45); do
        if mega-help >/dev/null 2>&1; then
            return 0
        fi
        sleep 1
    done
    bashio::log.error "mega-cmd-server did not become ready"
    return 1
}

_ensure_server() {
    if ! pgrep -x mega-cmd-server >/dev/null 2>&1; then
        mega-cmd-server >/data/mega-cmd-server.log 2>&1 &
    fi
    _wait_for_server
}

_logged_in() {
    local _out _rc
    set +e
    _out=$(mega-ls / 2>&1)
    _rc=$?
    set -e
    if [[ "${_rc}" -ne 0 ]]; then
        return 1
    fi
    if grep -qiE 'not logged|login required' <<<"${_out}"; then
        return 1
    fi
    return 0
}

_login() {
    bashio::log.info "Logging into Mega writable folder"
    mega-logout >/dev/null 2>&1 || true
    if ! mega-login "${_folder_url}" --auth-key="${_auth_key}"; then
        bashio::log.error "Mega login command failed"
        return 1
    fi
    local _i
    for _i in $(seq 1 20); do
        if _logged_in; then
            bashio::log.info "Mega login ok"
            printf '%s\n' "${_folder_url}" > /data/last_folder_url
            return 0
        fi
        sleep 1
    done
    bashio::log.error "Mega login did not establish a session"
    return 1
}

_prune() {
    local _date _name _count
    mapfile -t _rows < <(
        mega-ls -l --time-format=ISO6081_WITH_TIME / \
            | awk '
                $1 ~ /^-/ {
                    date=$4
                    name=$5
                    for (i=6; i<=NF; i++) name=name " " $i
                    print date "\t" name
                }' \
            | sort -r
    )
    _count=${#_rows[@]}
    if [[ "${_count}" -le "${_keep}" ]]; then
        return 0
    fi
    local _i
    for ((_i=_keep; _i<_count; _i++)); do
        IFS=$'\t' read -r _date _name <<< "${_rows[_i]}"
        [[ -n "${_name}" ]] || continue
        bashio::log.info "Removing old Mega backup ${_name}"
        mega-rm -f "/${_name}"
    done
}

_sync() {
    local _file _name
    if ! _logged_in; then
        bashio::log.error "Not logged into Mega; skipping sync"
        return 1
    fi
    shopt -s nullglob
    for _file in /backup/*.tar /backup/*.tar.enc; do
        [[ -f "${_file}" ]] || continue
        _name=$(basename "${_file}")
        if mega-ls "/${_name}" >/dev/null 2>&1; then
            continue
        fi
        bashio::log.info "Uploading ${_name}"
        mega-put "${_file}" "/${_name}"
    done
    _prune
}

_ensure_server
_login
bashio::log.info "MEGA writable backup running every ${_sync_minutes} minutes, keeping ${_keep} files"
while true; do
    _sync || bashio::log.warning "Sync failed; will retry"
    sleep $((_sync_minutes * 60))
done
