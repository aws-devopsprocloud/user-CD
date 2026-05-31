#!/bin/bash 

component=$1
environment=$2 
app_version=$3

cd /home/ec2-user
sudo dnf install ansible -y 
# yum install python3.11-devel python3.11-pip -y 
# pip3.11 install ansible botocore boto3
# export PATH=$PATH:/usr/local/bin
git clone https://github.com/aws-devopsprocloud/roboshop-ansible-roles-tf.git
cd roboshop-ansible-roles-tf 
git pull
ansible-playbook -e component=$component -e env=$environment -e app_version=$app_version main.yaml