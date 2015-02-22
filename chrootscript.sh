#!/bin/bash

set -x

useradd cisco -G sudo -m -d /home/cisco -s /bin/bash && echo cisco:lab | chpasswd && sed -ri 's/^# (%sudo.+ALL=(ALL).+NOPASSWD: ALL)/\1/' /etc/sudoers
sed -i "s/# deb/deb/g" /etc/apt/sources.list
