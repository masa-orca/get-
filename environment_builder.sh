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
# Source code is available at https://github.com/masa-orca/mandantory-cli-environment-builder

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
		else
			cat >&2 <<-'EOF'
			Error: this installer needs the ability to run commands as root.
			We are unable to find either "sudo" or "su" available to make this happen.
			EOF
			exit 1
		fi
       elif [ -r /.dockerenv ]; then
                sh_c='sh -c'
       else
		echo 'Error: Please run this installer as a non-root user.'
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
					python_package=python3.11
					;;
				focal)
					python_package=python3.9
					;;
				*)
					python_package=python3
					;;
			esac

			(
     				echo "INFO: Upgrading apt packages."
				$sh_c 'apt -qq update >/dev/null'
				$sh_c 'DEBIAN_FRONTEND=noninteractive apt -qq upgrade -y >/dev/null'
    			)
         		if [ -r /.dockerenv ]; then
     				echo "INFO: Installing ${python_package}."
                		$sh_c 'apt -qq install -y apt-utils'
       			fi
       			(
     				echo "INFO: Installing ${python_package}"
				$sh_c "DEBIAN_FRONTEND=noninteractive apt -qq install -y git ${python_package} python3-pip ${python_package}-venv"
			)
			if [ ! -d "$HOME/venv" ]; then
				(
	     				echo "INFO: Generating python venv on $HOME."
					$sh_c "${python_package} -m venv $HOME/venv >/dev/null"
	     				echo "INFO: Installing ansible to venv."
	  				$sh_c ". $HOME/venv/bin/activate && pip -q install -U pip"
					$sh_c ". $HOME/venv/bin/activate && pip -q install ansible"
     	     				echo "INFO: Finished building ansible environment!"
	     				echo "If you want to use ansible, please run 'source $HOME/venv/bin/activate'"
				)
			else
				echo 'INFO: venv directiry is already exists.'
				echo
			fi
			exit 0
			;;
		almalinux|rocky)
			(
     				echo "INFO: Updating dnf packages."
				$sh_c 'dnf -q update -y'
     				echo "INFO: Installing python3.11."
      				$sh_c 'dnf -q install -y python3.11 python3.11-pip'
			)
			if [ ! -d "$HOME/venv" ]; then
				(
	     				echo "INFO: Generating python venv on $HOME."
					$sh_c "python3.11 -m venv $HOME/venv >/dev/null"
	     				echo "INFO: Installing ansible to venv."
	  				$sh_c ". $HOME/venv/bin/activate && pip -q install -U pip"
					$sh_c ". $HOME/venv/bin/activate && pip -q install ansible"
	     				echo "INFO: Finished building ansible environment!"
	     				echo "If you want to use ansible, please run 'source $HOME/venv/bin/activate'"
     
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
}

do_install
