#!/bin/sh
# Initialize Default user Script

username="$1"
grpname="$username"

if [ -x /sbin/apk ]; then

    # Alpine default distribution does not contains required packages
    pkgs_to_install=""
    apk info 2>/dev/null | grep shadow >/dev/null || pkgs_to_install="$pkgs_to_install shadow"
    apk info 2>/dev/null | grep sudo >/dev/null || pkgs_to_install="$pkgs_to_install sudo"
    apk info 2>/dev/null | grep openssl >/dev/null || pkgs_to_install="$pkgs_to_install openssl"
    [ -z "$pkgs_to_install" ] || {
        apk update
        apk --no-cache add $pkgs_to_install
    }

    # configure sudo
    grep sudo /etc/group || /usr/sbin/addgroup --gid 65530 sudo
    sed -i 's/# *%sudo/%sudo/' /etc/sudoers

    # Create user
    /usr/sbin/addgroup --gid 1000 $grpname
    /usr/sbin/adduser --disabled-password --gecos '' --uid 1000 -G $grpname  $username
    /usr/sbin/adduser $username sudo

else

    # Ubuntu distributions
    /usr/sbin/addgroup --gid 1000 $grpname
    /usr/sbin/adduser --quiet --disabled-password --gecos '' --uid 1000 --gid 1000 $username
    /usr/sbin/usermod -aG sudo $username

fi

# Initialize user password:
echo "Please create password for user $username"
userencpass="`/usr/bin/openssl passwd -1`"
/usr/sbin/usermod --password $userencpass $username
