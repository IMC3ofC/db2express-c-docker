#!/bin/bash
#
#  Configure operation system for DB2 in a Docker container
#
# # Authors:
#   * Leo (Zhong Yu) Wu       <leow@ca.ibm.com>
#
# Copyright 2015, IBM Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# Configure OS for DB2

# Update ulimit on /etc/security/limits.conf
sed -Ei '/\\*\\s+(soft|hard)\\s+(nofile|sigpending|memlock|stack|nproc).*/d' /etc/security/limits.conf
sed -i '/# End of file/d' /etc/security/limits.conf
echo "* soft nofile     65535"     >> /etc/security/limits.conf
echo "* hard nofile     65535"     >> /etc/security/limits.conf
echo "* soft sigpending 1032252"   >> /etc/security/limits.conf
echo "* hard sigpending 1032252"   >> /etc/security/limits.conf
echo "* soft memlock    unlimited" >> /etc/security/limits.conf
echo "* hard memlock    unlimited" >> /etc/security/limits.conf
echo "* soft stack      unlimited" >> /etc/security/limits.conf
echo "* hard stack      unlimited" >> /etc/security/limits.conf
echo "* soft nproc      unlimited" >> /etc/security/limits.conf
echo "* hard nproc      unlimited" >> /etc/security/limits.conf
echo "# End of file"  >> /etc/security/limits.conf

# Update ulimit on /etc/bashrc
sed -Ei '/ulimit\s+\-(n|i|l|s|u)+\s+.*/d' /etc/bashrc
echo "ulimit -n 65535"     >> /etc/bashrc
echo "ulimit -i 1032252"   >> /etc/bashrc
echo "ulimit -l unlimited" >> /etc/bashrc
echo "ulimit -s unlimited" >> /etc/bashrc
echo "ulimit -u unlimited" >> /etc/bashrc

# Disable SELinux immediately
echo 0 > /selinux/enforce
echo "SELINUX=disabled" > /etc/selinux/config

# Disable 'requiretty' in sudoers
sed -Ei 's/^Defaults\\s+requiretty/#Defaults requiretty/g' /etc/sudoers

# Disable ASLR
sysctl -w kernel.randomize_va_space=0
sed -i '/^kernel\\.randomize_va_space\\ =.*/d' /etc/sysctl.conf
echo "kernel.randomize_va_space = 0" >> /etc/sysctl.conf
sysctl -e -p

# Increase semaphomore limits
sed -i '/^kernel\\.sem\\ =.*/d' /etc/sysctl.conf
echo "kernel.sem = 250 256000 32 2048" >> /etc/sysctl.conf
sysctl -e -p


###############################################################
#
#               Download and install DB2 Express-C
#
###############################################################


# Download DB2 Express-C from public bucket on AWS S3
# Note: you can update this script to copy/download image in your manners
cd /tmp && wget https://s3.amazonaws.com/db2-expc105-64bit-centos/v10.5fp5_linuxx64_expc.tar.gz
cd /tmp && tar xvf /tmp/v10.5fp5_linuxx64_expc.tar.gz && chown -R root:root /tmp/expc

# update response file for installation
cp /tmp/expc/db2/linuxamd64/samples/db2expc.rsp /tmp/. && chmod a+w /tmp/db2expc.rsp
sed -ri 's/= DECLINE/= ACCEPT/g' /tmp/db2expc.rsp

# Set up password for db2inst1
sed -ri 's/Replace with your password/db2inst1/g' /tmp/db2expc.rsp

# Set up password for db2sdfe1 user
sed -ri 's/DB2_INST.FENCED_USERNAME  =/\*DB2_INST.FENCED_USERNAME/g' /tmp/db2expc.rsp
sed -ri 's/DB2_INST.FENCED_PASSWORD =/\*DB2_INST.FENCED_PASSWORD/g' /tmp/db2expc.rsp
sed -ri 's/DB2_INST.FENCED_GROUP_NAME =/\*DB2_INST.FENCED_GROUP_NAME/g' /tmp/db2expc.rsp

/tmp/expc/db2setup -r /tmp/db2expc.rsp -l /tmp/db2setup.log

rm -rf /tmp/*
