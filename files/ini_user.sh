#!/bin/sh
# Initialize Default user Script

username="$1"
userpass="$2"

grpname="$username"

if [ -x /sbin/apk ]; then

    # Alpine default distribution does not contains required packages
    apk update
    apk --no-cache add shadow           # to be able to use usermod
    apk --no-cache add --update sudo    # to configure sudoers

    # Create user
    addgroup --gid 1000 $grpname
    adduser --disabled-password --gecos '' --uid 1000 -G $grpname  $username
    echo "$username ALL=(ALL:ALL) ALL" > /etc/sudoers.d/$username
    chmod 0440 /etc/sudoers.d/$username
    echo "$username:$userpass" | chpasswd

else

    # Ubuntu distributions
    /usr/sbin/addgroup --gid 1000 $grpname
    /usr/sbin/adduser --quiet --disabled-password --gecos '' --uid 1000 --gid 1000 $username
    /usr/sbin/usermod -aG sudo $username
    userencpass="`/usr/bin/openssl passwd -1 $userpass`"
    /usr/sbin/usermod --password $userencpass $username

fi
