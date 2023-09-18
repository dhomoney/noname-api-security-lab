#! /bin/bash
export noname_version=$'${noname_version}'
export aws_tmt=$'${aws_tmt}'
export aws_region=$'${aws_region}'
export aws_account=$'${aws_account}'
export aws_vpc_id=$'${aws_vpc_id}'
export aws_subnet_id=$'${aws_subnet_id}'
export app_server_id=$'${app_server_id}'
export app_server_ip=$'${app_server_ip}'
export noname_su_password=$'${noname_su_password}'
export noname_admin_password=$'${noname_admin_password}'
export ipv4_arn=$'${ipv4_arn}'
export ipv6_arn=$'${ipv6_arn}'
export waf_rulegroup_arn=$'${waf_rulegroup_arn}'
export ipv4_id=$'${ipv4_id}'
export ipv6_id=$'${ipv6_id}'
export waf_rulegroup_id=$'${waf_rulegroup_id}'
export alb_arn=$'${alb_arn}'
export customer_name=$'${customer_name}'
export email_csv=$'${email_csv}'
export crapi_private_ip=$'${crapi_private_ip}'
export git_branch=$'${git_branch}'
export slack_userid=$'${slack_userid}'
export slack_channelid=$'${slack_channelid}'
export callback_host=$'${callback_host}'
export package_stage=$'${package_stage}'

curl -sL https://deb.nodesource.com/setup_14.x | sudo bash -

sudo apt-get update -y
sudo apt-get install jq unzip awscli zip -y
sudo apt-get install nodejs yarn -y

# Execute bootstrap script
sudo aws s3 cp s3://noname-workshop-share/${git_branch}/nnServer_setup.sh ./nnServer_setup.sh
sudo chmod +x nnServer_setup.sh
./nnServer_setup.sh
