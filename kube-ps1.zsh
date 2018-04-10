#!/bin/zsh

# Kubernetes prompt helper for bash/zsh
# Displays current context and namespace

# Copyright 2017 Jon Mosco
#
#  Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Debug
[[ -n $DEBUG ]] && set -x

setopt PROMPT_SUBST
autoload -U add-zsh-hook
add-zsh-hook precmd _kube_ps1_load
zmodload zsh/stat

# Default values for the prompt
# Override these values in ~/.zshrc or ~/.bashrc
_KUBE_PS1_DEFAULT="${_KUBE_PS1_DEFAULT:=true}"
_KUBE_PS1_PREFIX="("
_KUBE_PS1_DEFAULT_LABEL="${_KUBE_PS1_DEFAULT_LABEL:="⎈ "}"
_KUBE_PS1_DEFAULT_LABEL_IMG="${_KUBE_PS1_DEFAULT_LABEL_IMG:=false}"
_KUBE_PS1_SEPERATOR="|"
_KUBE_PS1_PLATFORM="${_KUBE_PS1_PLATFORM:="kubectl"}"
_KUBE_PS1_DIVIDER=":"
_KUBE_PS1_SUFFIX=")"
__KUBE_PS1_UNAME=$(uname)
__KUBE_PS1_LAST_TIME=0

_kube_ps1_label() {

	[[ "${_KUBE_PS1_DEFAULT_LABEL_IMG}" == false ]] && return

	if [[ "${_KUBE_PS1_DEFAULT_LABEL_IMG}" == true ]]; then
		local _KUBE_LABEL="☸️ "
	fi

	_KUBE_PS1_DEFAULT_LABEL="${_KUBE_LABEL}"

}

_kube_ps1_split() {

	type setopt >/dev/null 2>&1 && setopt SH_WORD_SPLIT
	local IFS=$1
	echo $2
}

_kube_ps1_file_newer_than() {

	local mtime
	local file=$1
	local check_time=$2
	mtime=$(stat +mtime "${file}")

	[ "${mtime}" -gt "${check_time}" ]

}

_kube_ps1_load() {

	local conf
	# kubectl will read the environment variable $KUBECONFIG
	# otherwise set it to ~/.kube/config
	_PS1_KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"

	for conf in $(_kube_ps1_split : "${_PS1_KUBECONFIG}"); do
		# TODO: check existence of $conf
		if _kube_ps1_file_newer_than "${conf}" "${_KUBE_PS1_LAST_TIME}"; then
			_kube_ps1_get_context_ns
			return
		fi
	done
}

_kube_ps1_get_context_ns() {

	# Set the command time
	_KUBE_PS1_LAST_TIME=$(date +%s)

	if [[ "${_KUBE_PS1_DEFAULT}" == true ]]; then
		local _KUBE_BINARY="${_KUBE_PS1_PLATFORM}"
	elif [[ "${_KUBE_PS1_DEFAULT}" == false ]] && [[ "${_KUBE_PS1_PLATFORM}" == "kubectl" ]]; then
		local _KUBE_BINARY="kubectl"
	elif [[ "${_KUBE_PS1_PLATFORM}" == "oc" ]]; then
		local _KUBE_BINARY="oc"
	fi

	_KUBE_PS1_CONTEXT="$(${_KUBE_BINARY} config current-context)"
	_KUBE_PS1_NAMESPACE="$(${_KUBE_BINARY} config view --minify --output 'jsonpath={..namespace}')"
	# Set namespace to default if it is not defined
	_KUBE_PS1_NAMESPACE="${_KUBE_PS1_NAMESPACE:-default}"

}

# source our symbol
_kube_ps1_label

# Build our prompt
_kube_ps1() {
	local reset_color="%f"
	local blue="%F{blue}"
	local red="%F{red}"
	local cyan="%F{cyan}"

	_KUBE_PS1="${reset_color}$_KUBE_PS1_PREFIX"
	_KUBE_PS1+="${blue}$_KUBE_PS1_DEFAULT_LABEL"
	_KUBE_PS1+="${reset_color}$_KUBE_PS1_SEPERATOR"
	_KUBE_PS1+="${red}$_KUBE_PS1_CONTEXT${reset_color}"
	_KUBE_PS1+="$_KUBE_PS1_DIVIDER"
	_KUBE_PS1+="${cyan}$_KUBE_PS1_NAMESPACE${reset_color}"
	_KUBE_PS1+="$_KUBE_PS1_SUFFIX"

	echo "${_KUBE_PS1}"

}
