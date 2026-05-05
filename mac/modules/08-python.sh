#!/usr/bin/env bash
# shellcheck shell=bash
# Installs Python 3.12 and uv (Astral's modern Python package manager).

invoke_python() {
    log_step "8/8" "Python + uv"

    brew_install formula 'python@3.12' 'Python 3.12'
    brew_install formula 'uv'           'uv'
    load_brew_env

    if have python3; then
        log_success "python3: $(python3 --version)"
    else
        log_warn "python3 not on PATH after install."
    fi

    if have uv; then
        log_success "uv: $(uv --version)"
    else
        log_warn "uv not on PATH after install."
    fi
}
