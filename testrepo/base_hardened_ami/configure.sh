#!/bin/bash


sudo yum -y update

# Set up new file system with separate /var, /var/log, /var/tmp, /var/log/audit, /home, and /tmp partitions

sudo rm -rfv /home/*
sudo rm -rfv /var/*
sudo rm -rfv /tmp/*

sudo sed -i '/^tmpfs/c\tmpfs       /dev/shm    tmpfs   defaults,nodev,nosuid,noexec  0   0' /etc/fstab
sudo mount -o remount /dev/shm

cat >> /etc/fstab << 'EOF'

LABEL=/home             /home           ext4    defaults,nodev  0 0
LABEL=/var              /var            ext4    defaults        0 0
LABEL=/var/log          /var/log        ext4    defaults        0 0
LABEL=/var/log/audit    /var/log/audit  ext4    defaults        0 0
LABEL=/tmp              /tmp            ext4    defaults,nodev,nosuid    0 0
LABEL=/var/tmp          /var/tmp        ext4    defaults,nodev,nosuid,noexec    0 0

EOF

sudo mount -a

sleep 5

# Enable single user mode authentication

sudo sed -i '/^SINGLE/c\SINGLE=/sbin/sulogin' /etc/sysconfig/init

# Remove permissions from /etc/ssh/sshd_config

sudo chmod og-rwx /etc/ssh/sshd_config

# Remove and replace java with newer version

sudo yum -y remove `sudo yum list installed | grep jdk | awk '{print \$1}'`
sudo aws s3 cp s3://elb-config/devops-install-config/jdk-8u111-linux-x64.rpm /tmp/java111.rpm && echo "JDK download successful" || echo "Failed to download JDK"
sudo aws s3 cp s3://elb-config/devops-install-config/jce_policy-8.zip /tmp/jce_policy.zip && echo "JCE Policy download successful" || echo "Failed to download JCE Policy"
sudo unzip /tmp/jce_policy.zip -d /home/ec2-user

sudo yum install -y /tmp/java111.rpm
sudo cp /home/ec2-user/UnlimitedJCEPolicyJDK8/local_policy.jar /usr/java/jdk1.8.0_111/jre/lib/security/ && echo "Local policy copy successful" || echo "Failed to copy Local policy"
sudo cp /home/ec2-user/UnlimitedJCEPolicyJDK8/US_export_policy.jar /usr/java/jdk1.8.0_111/jre/lib/security/ && echo "Export policy copy successful" || echo "Failed to copy Export policy"

sudo rm /tmp/java111.rpm
sudo rm -r /home/ec2-user/UnlimitedJCEPolicyJDK8

# Update OpenSSL
sudo yum -y install gcc
sudo wget -O /openssl-1.0.1u.tar.gz https://www.openssl.org/source/openssl-1.0.1u.tar.gz
cd /
sudo tar -zxvf /openssl-1.0.1u.tar.gz
sudo chmod 755 /openssl-1.0.1u
cd /openssl-1.0.1u
sudo ./config
sudo make depend
sudo make
sudo make test
sudo make install
sudo mv /usr/bin/openssl /usr/bin/openssl_orig
sudo ln -s /usr/local/ssl/bin/openssl /usr/bin/openssl
sudo yum -y remove gcc
sudo rm -rfv /openssl-1.0.1u*
cd; cd -

# Install agent for Tenable.io
echo "Installing Tenable.io agent"
aws s3 cp s3://elb-config/devops-install-config/NessusAgent-6.10.9-amzn.x86_64.rpm /tmp/nessus-agent.rpm
sudo rpm -ivh /tmp/nessus-agent.rpm && echo "Tenable.io agent installed" || echo "Tenable.io agent installation failed"
/bin/rm -fv /tmp/nessus-agent.rpm

# Install agent for Vistara
echo "Installing Vistara agent"
aws s3 cp s3://elb-config/devops-install-config/vistara-agent-4.5.3-4.x86_64.rpm /tmp/vistara-agent.rpm
sudo rpm -ivh /tmp/vistara-agent.rpm && echo "Vistara agent installed" || echo "Vistara agent installation failed"
/bin/rm -fv /tmp/vistara-agent.rpm

# Install agent for Alert Logic
echo "Installing Alert Logic"
/usr/bin/wget https://scc.alertlogic.net/software/al-agent-LATEST-1.x86_64.rpm -O /tmp/al-agent.rpm
sudo rpm -ivh /tmp/al-agent.rpm && echo "Alert Logic agent installed" || echo "Alert Logic agent installation failed"
sudo /bin/rm -fv/tmp/al-agent.rpm

echo "Exiting configure.sh script"
