#!/bin/sh
# Initialize Default user Script

username="$1"
userpass="$2"

grpname="$username"

if [ -x /sbin/apk ]; then

    # Alpine default distribution does not contains required packages
    pkgs_to_install=""
    apk info 2>/dev/null | grep shadow >/dev/null || pkgs_to_install="$pkgs_to_install shadow"
    apk info 2>/dev/null | grep sudo >/dev/null || pkgs_to_install="$pkgs_to_install sudo"
    [ -z "$pkgs_to_install" ] || {
        apk update
        apk --no-cache add $pkgs_to_install
    }

    # Create user
    addgroup --gid 1000 $grpname
    adduser --disabled-password --gecos '' --uid 1000 -G $grpname  $username
    grep sudo /etc/group || addgroup sudo
    adduser $username sudo
    sed -i 's/# *%sudo/%sudo/' /etc/sudoers
    echo "$username:$userpass" | chpasswd

else

    # Ubuntu distributions
    /usr/sbin/addgroup --gid 1000 $grpname
    /usr/sbin/adduser --quiet --disabled-password --gecos '' --uid 1000 --gid 1000 $username
    /usr/sbin/usermod -aG sudo $username
    userencpass="`/usr/bin/openssl passwd -1 $userpass`"
    /usr/sbin/usermod --password $userencpass $username

fi
