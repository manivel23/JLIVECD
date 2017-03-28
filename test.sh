#!/bin/bash
msg_out(){
	printf "\n*** $*\n" > /dev/stdout
}

err_out(){
	printf "\nE: $*\n" > /dev/stderr
}

wrn_out(){
	printf "\nW: $*\n" > /dev/stderr
}

err_exit(){
	err_out "$*"
	exit 1
}

get_yn(){
	#$1: msg
	#$2: timeout
	local msg="
	=== $(printf "$1")"
	msg=$(echo "$msg" |sed -e 's/^[[:blank:]]*//')
	local yn
    local timeout="$2"
	if [ "$2" = "" ]; then
		read -p "$msg" yn >/dev/null
	else
	    if ! echo "$timeout" |grep -E '^[0-9]+$' >/dev/null; then
	        err_exit "invalid timeout value: $timeout"
	    fi
		read -t "$2" -p "$msg" yn >/dev/null
	fi
	if [ "$yn" = y ]; then
		echo y > /dev/stdout
    else
        echo "$yn" > /dev/stdout
	fi
}


get_prop_val(){
	prop="$1"
	cf="$2"
	grep -isoP "(?<=^$prop=).*" "$cf" > /dev/stdout
}

chk_conf_prop(){
	local prop="$1"
	local cf="$2"
	if grep -isq "^[[:blank:]]*$prop=" "$cf";then
		return 0
	else
		return 1
	fi
}


update_prop_val(){
	local prop="$1"
	local val="$2"
	local cf="$3"
	local h="$4"
	if chk_conf_prop "$prop" "$cf"; then
		# sed -E -i.bak "s/^[[:blank:]]*(RetainHome=).*/\1$val/I" "$cf"
		echo "$(awk "BEGIN{IGNORECASE=1} {sub(/^[[:blank:]]*$prop=.*$/,\"$prop=$val\");print}" "$cf")" > "$cf"
	else
		printf "\n#$h\n$prop=$val\n" >> "$cf"
	fi
}

export a=uiouio

fun(){
	b=a
	echo ${!b}
}

insert_into_fstab(){
	if [ "$edit" = "" ]; then
		err_exit "\$edit can not be empty"
	fi
	proc="proc $edit/proc proc defaults 0 0"
	sys="sysfs $edit/sys sysfs defaults 0 0"
	devpts="devpts $edit/dev/pts devpts defaults 0 0"
	#dev="devtmpfs $edit/dev devtmpfs defaults 0 0"
	arr=("$proc" "$sys" "$devpts")
	cp /etc/fstab /etc/fstab.bkp
	for mp in "${arr[@]}"; do
		echo "$(grep -v "$mp" /etc/fstab)" >/etc/fstab
		sed -i.bak -e "$ a $mp" /etc/fstab
	done
}

remove_from_fstab(){
	if [ "$edit" = "" ]; then
		err_exit "\$edit can not be empty"
	fi
	proc="proc $edit/proc proc defaults 0 0"
	sys="sysfs $edit/sys sysfs defaults 0 0"
	devpts="devpts $edit/dev/pts devpts defaults 0 0"
	arr=("$proc" "$sys" "$devpts")
	cp /etc/fstab /etc/fstab.bkp
	for mp in "${arr[@]}"; do
		echo "$(grep -v "$mp" /etc/fstab)" >/etc/fstab
	done
}


abs_path(){
    if [ -d "$1" ]; then
        cd "$1"
        echo "$(pwd -P)" >/dev/stdout
    else
        cd "$(dirname "$1")"
        echo "$(pwd -P)/$(basename "$1")" >/dev/stdout
    fi
}

chk_edit(){
	if [ "$edit" = "" ]; then
		err_exit "\$edit can not be empty"
	fi
}

mountfs(){
	mount  proc "$edit"/proc -t proc && echo '*** mounted proc'
	mount  sysfs "$edit"/sys -t sysfs && echo '*** mounted sysfs'
	mount  devpts "$edit"/dev/pts -t devpts && echo '*** mounted devpts'
}

umount_fs(){
	umount "$edit"/proc || umount -lf "$edit"/proc
	umount "$edit"/sys
	umount "$edit"/dev/pts
}

# edit=edit
# insert_into_fstab
# remove_from_fstab

f(){
	trap 'echo fdkls' EXIT
}
f
