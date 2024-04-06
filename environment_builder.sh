#!/bin/sh
set -e
# Building mandantory environment script.
#
# This script is intended as a convenient way to install git and ansible on venv.
#
# The script:
#
# - Requires `root` or `sudo` privileges to run.
# - Attempts to detect your Linux distribution and version and configure your
#   package management system for you.
# - Updates and upgrades installed-packages without asking for confirmation.
# - Installs dependencies and recommendations without asking for confirmation.
# - Installs git, python3.x.
# - Creates a python3.x venv on venv directory on user's home directory.
# - Installs ansible on the venv.
#
# Source code is available at hogehoge

command_exists() {
	command -v "$@" > /dev/null 2>&1
}

get_distribution() {
	lsb_dist=""
	# Every system that we officially support has /etc/os-release
	if [ -r /etc/os-release ]; then
		lsb_dist="$(. /etc/os-release && echo "$ID")"
	fi
	# Returning an empty string here should be alright since the
	# case statements don't act unless you provide an actual value
	echo "$lsb_dist"
}

get_distribution_version() {
	lsb_dist_ver=""
	# Every system that we officially support has /etc/os-release
	if [ -r /etc/os-release ]; then
		lsb_dist_ver="$(. /etc/os-release && echo "$VERSION_ID")"
	fi
	# Returning an empty string here should be alright since the
	# case statements don't act unless you provide an actual value
	echo "$lsb_dist_ver"
}

get_distribution_version_codename() {
	lsb_dist_codename=""
	# Every system that we officially support has /etc/os-release
	# If debian familly, VERSION_CODENAME exists in /etc/os-release
	if [ -r /etc/os-release ]; then
		lsb_dist_codename="$(. /etc/os-release && echo "$VERSION_CODENAME")"
	fi
	# Returning an empty string here should be alright since the
	# case statements don't act unless you provide an actual value
	echo "$lsb_dist_codename"
}

do_install() {
	user="$(id -un 2>/dev/null || true)"

	sh_c='sh -c'
	if [ "$user" != 'root' ]; then
		if command_exists sudo; then
			sh_c='sudo -E sh -c'
		elif command_exists su; then
			sh_c='su -c'
		elif [ -r /.dockerenv ]; then
		    sh_c='sh -c'
		else
			cat >&2 <<-'EOF'
			Error: this installer needs the ability to run commands as root.
			We are unable to find either "sudo" or "su" available to make this happen.
			EOF
			exit 1
		fi
	else
		echo 'Error: Non-root user can run this installer.'
		echo
		exit 1
	fi

	lsb_dist=$( get_distribution )
	lsb_dist="$(echo "$lsb_dist" | tr '[:upper:]' '[:lower:]')"
	lsb_dist_ver=$( get_distribution_version )

	# Run setup for each distro accordingly
	case "$lsb_dist" in
		ubuntu)
			lsb_dist_codename=$( get_distribution_version_codename )
			case "$lsb_dist_codename" in
				jammy)
					python_version=python3.11
					;;
				focal)
					python_version=python3.9
				*)
					python_version=python3
					;;
			esac

			(
				$sh_c 'apt update -qq >/dev/null'
				$sh_c 'apt upgrade -y -qq >/dev/null'
				$sh_c 'apt install -y -qq git $python_version $python_version-pip python3-venv >/dev/null'
			)
			if [ ! -d $HOME/venv ]; then
				(
					$sh_c '$python_version -m venv $HOME/venv >/dev/null'
					$sh_c 'source $HOME/venv/bin/activate >/dev/null'
					$sh_c 'pip install ansible >/dev/null'
					$sh_c 'deactivate'
				)
			else
				echo 'INFO: venv directiry is already exists.'
				echo
			fi
			exit 0
			;;
		almalinux|rocky)
		    (
				$sh_c 'dnf update -y'
      			$sh_c 'dnf install -y python3.11 python3.11-pip'
			)
			if [ ! -d $HOME/venv ]; then
				(
					$sh_c 'python3 -m venv $HOME/venv >/dev/null'
					$sh_c 'source $HOME/venv/bin/activate >/dev/null'
					$sh_c 'pip install ansible >/dev/null'
					$sh_c 'deactivate'
				)
			else
				echo 'INFO: venv directiry is already exists.'
				echo
			fi
			exit 0
			;;
		*)
			echo "ERROR: Unsupported distribution '$lsb_dist'"
			echo
			exit 1
			;;
	esac
	exit 1
}

do_install