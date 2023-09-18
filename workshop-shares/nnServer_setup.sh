#! /bin/bash
set -e

# set up an error catch so that we can notify the user if Noname installation fails
handle_error() {
  curl https://$callback_host/notify -d '{ "notification": ":sob: Your workshop installation failed!", "message": " Please check `$ cat /var/log/syslog | grep cloud-init`", "channel": "'$slack_channelid'", "user": "'$slack_userid'", "type": "simple_notification"}' -H 'Content-Type: application/json'
}

trap "handle_error" ERR

# configs
ENABLE_FEATURES=(
  'Network Graph'
  'API Metrics UI'
  'active'
  'Call Flows'
)

DISABLE_FEATURES=(
)

ENGINE_CONFIG=(
  'POC.ISSUES.BOLA.MIN_RESOURCE_USERS,1'
  'POC.MIN_API_USERS,0'
  'POC.MIN_API_HISTORY,1'
  'POC.ISSUES.BOLA.RESOURCE_MIN_HISTORY,1'
  'SHOULD_CREATE_API_CALL_GRAPH,true'
  'POC.IS_POC,true'
  'POC.MAX_OUTLIER_USERS,1'
  'POC.ISSUES.JWT_ANOMALIES.MAX_OUTLIER_USERS,1'
  'POC.ISSUES.JWT_ANOMALIES.MIN_USERS,1'
  'POC.ISSUES.MAX_OUTLIER_USERS,1'
  'ISSUES.RANGE_VIOLATION.SHOULD_RAISE_ON_STRING,false'
  'ISSUES.RANGE_VIOLATION.SHOULD_RAISE_ON_OBJECT,false'
  'POC.ISSUES.EXCESSIVE_MA.API_USAGE_THRESHOLD,150'
  'ISSUES.GLOBAL_EXCESSIVE_MA.PATH_ERRORS.MIN_HISTORY,1'
)


ENABLE_ISSUES=(
  'Unexpected JWT Algorithm'
  'Broken Object Level Authorization'
  'Broken Authentication'
  'Abnormal Field Input'
  'Server-Side Request Forgery'
  'Unexpected Request Field Type'
  'Unexpected Request Field'
  'SQL Injection'
  'Min Range Violation'
  'Max Range Violation'
  'Command Injection'
  'Cross-Site Scripting'
  'Broken Verification of Expired JWT Token'
  'External API Serves Content Over HTTP'
  'JWT Expiration Time Violation'
  'Broken Verification of JWT Algorithm'
  'Path Traversal'
  'Unexpected JWT Algorithm'
  'Excessive Requests for Non-Existing Resources'
  'API With Broken Object Level Authorization'
  'API Access With Unexpected Request Field Type'
  'API Access With Unexpected Request Field'
)

DISABLE_ISSUES=(
  'Suspicious User-Agent'
  'Global Excessive DSPOT User Errors Producer'
  'Global Excessive DSPOT Server Errors Producer'
  'Global Excessive DSPOT Aggregated Response Length'
  'Excessive Data Retrieval'
  'Excessive Aggregated Response Length'
  'Excessive MA Aggregated Response Length'
  'Global Excessive MA User Errors Producer'
  'Global Excessive MA Server Errors Producer'
  'Global Excessive MA Aggregated Response Length'
  'Global Excessive Aggregated Response Length'
  'Excessive MA Server Errors Producer'
  'Excessive MA Data Retrieval'
  'Global Excessive Data Retrieval'
  'Global Excessive DSPOT Path Errors Producer'
  'GitHub Repository Exposes Forbidden API-Related Data'
)

# Create webhook URL UUID
WEBHOOK_UUID=$(curl -X POST https://webhook.site/token | jq .uuid -r)

CUSTOM_LINKS=(
  'https://'$customer_name'-crapi.nnsworkshop.com,crAPI Web Interface'
  'https://'$customer_name'-mailhog.nnsworkshop.com,MailHog Web Interface'
  'https://'$customer_name'.nnsworkshop.com/guide,Hands on Guide'
  'https://'$customer_name'.nnsworkshop.com/pre-work,Pre-Work Guide'
  'https://webhook.site/#!/'$WEBHOOK_UUID',Workflow Webhook'
)


# Download the specified tar file from the correct S3 bucket location
sudo mkdir /opt/noname

sudo aws s3 cp s3://noname-packages/${package_stage}/${noname_version}.tar nonamesecurity.tar.gz
sudo aws s3 cp s3://noname-packages/${package_stage}/${noname_version}.activation /home/ubuntu/noname.activation
sudo tar zxvf nonamesecurity.tar.gz -C /opt/noname

# enable antigen lab mode
sudo chmod 777 /opt/noname/.env
echo 'ANTIGEN_LAB_MODE=true' >>/opt/noname/.env

# set up the guides and collections
cd /opt/noname/nginx/templates
echo -n "include /etc/nginx/conf.d/guides.conf;" | sudo tee -a active.conf.template
sudo aws s3 cp s3://noname-workshop-share/${git_branch}/guides.conf.template guides.conf.template
sudo aws s3 cp s3://noname-workshop-share/${git_branch}/postman-collection.zip postman-collection.zip
sudo aws s3 cp s3://noname-workshop-share/${git_branch}/janeDoe.postman_collection.json janeDoe.postman_collection.json
sudo aws s3 cp s3://noname-workshop-share/${git_branch}/johnSmith.postman_collection.json johnSmith.postman_collection.json
sudo aws s3 cp s3://noname-workshop-share/${git_branch}/crapi-at-spec.json crapi-at-spec.json
sudo unzip postman-collection.zip
sudo rm postman-collection.zip
sudo sed -i "s/<customer>/$customer_name/g" ./postman-collection/workspace.postman_globals.json
sudo sed -i "s/<customer>/$customer_name/g" janeDoe.postman_collection.json
sudo sed -i "s/<customer>/$customer_name/g" johnSmith.postman_collection.json
sudo sed -i "s/<customer>/$customer_name/g" crapi-at-spec.json
sudo zip -r postman-collection.zip ./postman-collection
sudo aws s3 cp s3://noname-workshop-share/${git_branch}/prework.zip ~/prework.zip
sudo aws s3 cp s3://noname-workshop-share/${git_branch}/guide.zip ~/guide.zip
sudo unzip ~/prework.zip -d ./
sudo unzip ~/guide.zip -d ./
sudo sed -i "s/admin_password/$noname_admin_password/g" ./prework/index.html
sudo sed -i "s/https:\/\/customer/https:\/\/$customer_name/g" ./prework/index.html
sudo sed -i "s/https:\/\/customer/https:\/\/$customer_name/g" ./guide/index.html

# install Noname
cd /opt/noname
sudo ./noname_installer.sh --activation /home/ubuntu/noname.activation --active --force
sleep 10s

# Toggle feature flags
for feature in "${ENABLE_FEATURES[@]}"; do
  sudo docker exec $(sudo docker ps | grep postgres | awk '{print $1}') psql -U postgres -d noname -c "UPDATE feature_flags SET is_enabled = true WHERE name = '$feature'"
done

# Disable features currently disabled
# for feature in "${DISABLE_FEATURES[@]}"; do
#  sudo docker exec $(sudo docker ps | grep postgres | awk '{print $1}') psql -U postgres -d noname -c "UPDATE feature_flags SET is_enabled = false WHERE name = '$feature'"
# done

# create participant role
PARTICIPANT_ROLES='[{"role": "api_spec_files_r", "entity": "api_spec_files"}, {"role": "spec_examples_n", "entity": "spec_examples"}, {"role": "oas_rule_file_r", "entity": "oas_rule_file"}, {"role": "groups_rw", "entity": "groups"}, {"role": "issue_status_rw", "entity": "issue_status"}, {"role": "ignore_ip_rw", "entity": "ignore_ip"}, {"role": "comments_rw", "entity": "comments"}, {"role": "evidence_r", "entity": "evidence"}, {"role": "take_action_rw", "entity": "take_action"}, {"role": "prevention_rw", "entity": "prevention"}, {"role": "datatypes_rw", "entity": "datatypes"}, {"role": "teams_n", "entity": "teams"}, {"role": "roles_n", "entity": "roles"}, {"role": "users_n", "entity": "users"}, {"role": "data_policies_rw", "entity": "data_policies"}, {"role": "custom_policies_rw", "entity": "custom_policies"}, {"role": "detection_policies_rw", "entity": "detection_policies"}, {"role": "workflows_rw", "entity": "workflows"}, {"role": "posture_security_r", "entity": "posture_security"}, {"role": "workflow_integrations_r", "entity": "workflow_integrations"}, {"role": "prevention_integrations_r", "entity": "prevention_integrations"}, {"role": "saml_settings_r", "entity": "saml_settings"}, {"role": "sources_r", "entity": "sources"}, {"role": "audit_n", "entity": "audit"}, {"role": "manage_api_n", "entity": "manage_api"}, {"role": "active_testing_rw", "entity": "active_testing"}, {"role": "active_testing_owner_n", "entity": "active_testing_owner"}, {"role": "engines_r", "entity": "engines"}, {"role": "security_r", "entity": "security"}, {"role": "infrastructure_n", "entity": "infrastructure"}, {"role": "custom_links_r", "entity": "custom_links"}, {"role": "api_consumers_rw", "entity": "api_consumers"}, {"role": "recon_n", "entity": "recon"}, {"role": "authentication_management_rw", "entity": "authentication_management"}, {"role": "api_tags_rw", "entity": "api_tags"}, {"role": "api_owner_rw", "entity": "api_owner"}, {"role": "discovery_configuration_rw", "entity": "discovery_configuration"}]'
sudo docker exec $(sudo docker ps | grep postgres | awk '{print $1}') psql -U postgres -d noname -c "INSERT INTO system_roles (id, title, description, roles) VALUES ('7fc304a0-f03e-4503-92ac-a76558ba6006', 'participant', 'Workshop participant role', '$PARTICIPANT_ROLES')"

# create participant team
sudo docker exec $(sudo docker ps | grep postgres | awk '{print $1}') psql -U postgres -d noname -c "INSERT INTO system_teams (id, name, is_show_unassociated_issues) VALUES ('dbae8d11-f481-4378-ad48-b11f9d417a7d', 'participants', true)"
sudo docker exec $(sudo docker ps | grep postgres | awk '{print $1}') psql -U postgres -d noname -c "INSERT INTO system_team_groups (team_id, group_id) VALUES ('dbae8d11-f481-4378-ad48-b11f9d417a7d', (SELECT id FROM groups WHERE name = 'root'))"

# create admin role insert columns/values
ROLE_COLUMNS=()
ROLE_VALUES=()
ROLE_ROWS=$(sudo docker exec $(sudo docker ps | grep postgres | awk '{print $1}') psql -U postgres -d noname -t -c "SELECT jae.rolePair->>'role' FROM (SELECT jsonb_array_elements(roles) as rolePair FROM public.system_roles where title = 'admin') jae")
ROLE_CHANGES=()
for role in $ROLE_ROWS; do
  VALID_COLUMN=$(sudo docker exec $(sudo docker ps | grep postgres | awk '{print $1}') psql -U postgres -d noname -AXqtc "SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='user_permissions' AND column_name='$role');")
  if [ "$VALID_COLUMN" = "t" ]; then
    if [[ ! " ${ROLE_COLUMNS[*]} " =~ " ${role} " ]]; then
      ROLE_COLUMNS+=("$role")
      ROLE_VALUES+=("true")
    fi
  fi
done

# set up the columns list for the admin role... we still have each user with specific permissions rather than just using a role ID
printf -v role_column_csv '%s,' "${ROLE_COLUMNS[@]}"
role_column_csv=${role_column_csv::-1}
printf -v role_value_csv '%s,' "${ROLE_VALUES[@]}"
role_value_csv=${role_value_csv::-1}

# create system user
sudo docker exec $(sudo docker ps | grep postgres | awk '{print $1}') psql -U postgres -d noname -c "INSERT INTO system_users (username, password, role, email, team, is_registered, force_login, is_deleted, type) VALUES ('noname-su@nonamesecurity.com', '"$(echo -n "$noname_su_password" | sha256sum | awk '{print $1}')"', (SELECT id FROM system_roles WHERE title = 'admin'), 'noname-su@nonamesecurity.com', (SELECT id FROM system_teams WHERE name = 'admins'), true, false, false, 'regular')"
sudo docker exec $(sudo docker ps | grep postgres | awk '{print $1}') psql -U postgres -d noname -c "INSERT INTO user_permissions (user_id, role_id, system, $role_column_csv) VALUES ((SELECT id FROM system_users WHERE username = 'noname-su@nonamesecurity.com'), (SELECT id FROM system_roles WHERE title = 'admin'), true, $role_value_csv)"

# create participant role insert columns/values
ROLE_COLUMNS=()
ROLE_VALUES=()
ROLE_ROWS=$(sudo docker exec $(sudo docker ps | grep postgres | awk '{print $1}') psql -U postgres -d noname -t -c "SELECT jae.rolePair->>'role' FROM (SELECT jsonb_array_elements(roles) as rolePair FROM public.system_roles where title = 'participant') jae")
ROLE_CHANGES=()
for role in $ROLE_ROWS; do
  VALID_COLUMN=$(sudo docker exec $(sudo docker ps | grep postgres | awk '{print $1}') psql -U postgres -d noname -AXqtc "SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='user_permissions' AND column_name='$role');")
  if [ "$VALID_COLUMN" = "t" ]; then
    ROLE_COLUMNS+=("$role")
    ROLE_VALUES+=("true")
  fi
done

# create the customer links
for custom_link in "${CUSTOM_LINKS[@]}"; do
  key=$(echo $custom_link | awk -F',' '{print $1}')
  value=$(echo $custom_link | awk -F',' '{print $2}')
  sudo docker exec $(sudo docker ps | grep postgres | awk '{print $1}') psql -U postgres -d noname -c "INSERT INTO custom_links (link, alias, added_by, updated_by) VALUES ('$key', '$value', (SELECT id FROM system_users WHERE username ='noname-su@nonamesecurity.com'), (SELECT id FROM system_users WHERE username ='noname-su@nonamesecurity.com'))"
done

# set up the columns list for the participant role... we still have each user with specific permissions rather than just using a role ID
printf -v role_column_csv '%s,' "${ROLE_COLUMNS[@]}"
role_column_csv=${role_column_csv::-1}
printf -v role_value_csv '%s,' "${ROLE_VALUES[@]}"
role_value_csv=${role_value_csv::-1}


# create list of users from CSV input
EMAILS="$email_csv"
for email in $(echo $EMAILS | sed "s/,/ /g"); do
  sudo docker exec $(sudo docker ps | grep postgres | awk '{print $1}') psql -U postgres -d noname -c "INSERT INTO system_users (username, password, role, email, team, is_registered, force_login, is_deleted, type) VALUES ('$email', '"$(echo -n "$noname_admin_password" | sha256sum | awk '{print $1}')"', (SELECT id FROM system_roles WHERE title = 'participant'), '$email', (SELECT id FROM system_teams WHERE name = 'participants'), true, false, false, 'regular')"
  sudo docker exec $(sudo docker ps | grep postgres | awk '{print $1}') psql -U postgres -d noname -c "INSERT INTO user_permissions (user_id, role_id, system, $role_column_csv) VALUES ((SELECT id FROM system_users WHERE username = '$email'), (SELECT id FROM system_roles WHERE title = 'participant'), false, $role_value_csv)"
done

# create aws integration
sudo docker exec $(sudo docker ps | grep postgres | awk '{print $1}') psql -U postgres -d noname -c "INSERT INTO sources (alias, type, index, status, settings) VALUES ('aws-crapi-mirroring', 2, 1, 'Configured', '{\"assumer\":\"\",\"assumer_session_name\":\"\",\"accessKeyId\":\"\",\"secretAccessKey\":\"\",\"region\":\"$aws_region\",\"vpcId\": \"$aws_vpc_id\",\"subnetId\": \"$aws_subnet_id\",\"accountId\":\"$aws_account\",\"targetId\":\"$aws_tmt\",\"albs\":[],\"ec2s\":[\"$app_server_id\"]}')"

# create prevention integration
sudo docker exec $(sudo docker ps | grep postgres | awk '{print $1}') psql -U postgres -d noname -c "INSERT INTO prevention_sources (alias, type, index, status, settings) VALUES ('aws-crapi-waf', 2, 1, 'Configured', '{\"assumer\":\"arn:aws:iam::$aws_account:role/nnw-$customer_name-pr\",\"assumer_session_name\":\"AWSCLI-Session\",\"externalId\": \"e1ae2adb-4179-4fe4-8383-6c9f9f194aa2\", \"accessKeyId\":\"\",\"secretAccessKey\":\"\",\"regions\":[\"$aws_region\"],\"accountId\":\"$aws_account\", \"rule_group\": {\"arn\": \"$waf_rulegroup_arn\", \"id\": \"$waf_rulegroup_id\", \"name\": \"$customer_name-PreventionRuleGroup\", \"scope\": \"regional\", \"capacity\": 1000}, \"ipv4_set\": {\"arn\": \"$ipv4_arn\", \"id\": \"$ipv4_id\", \"name\": \"$customer_name-IPv4Set\", \"scope\": \"regional\"}, \"ipv6_set\": {\"arn\": \"$ipv6_arn\", \"id\": \"$ipv6_id\", \"name\": \"$customer_name-IPv6Set\", \"scope\": \"regional\"}, \"version\": 2, \"role\": {\"account\": \"$aws_account\", \"name\": \"nnw-$customer_name-pr\"}}')"

# create workflow integration
sudo docker exec $(sudo docker ps | grep postgres | awk '{print $1}') psql -U postgres -d noname -c "INSERT INTO workflow_settings (const_settings, settings, type, alias, is_enabled) VALUES ('{\"linkURL\":\"https://webhook.site/$WEBHOOK_UUID\", \"url\":\"https://webhook.site/$WEBHOOK_UUID\"}', '{\"url\":\"https://webhook.site/$WEBHOOK_UUID\"}', 'webhook', 'Webhook Integration', true)"

# end learning mode
sudo docker exec $(sudo docker ps | grep postgres | awk '{print $1}') psql -U postgres -d noname -c "UPDATE system_configs SET value = '{\"method\":\"END_NOW\"}' WHERE name = 'endOfLearningPeriod'"

# disable all sources
sudo docker exec $(sudo docker ps | grep postgres | awk '{print $1}') psql -U postgres -d noname -c "UPDATE source_types SET is_enabled = 'false'"
sudo docker exec $(sudo docker ps | grep postgres | awk '{print $1}') psql -U postgres -d noname -c "UPDATE workflow_source_types SET is_enabled = 'false'"
#enable webhook, aws prevention, and aws source
sudo docker exec $(sudo docker ps | grep postgres | awk '{print $1}') psql -U postgres -d noname -c "UPDATE workflow_source_types SET is_enabled = 'true' WHERE name = 'webhook'"
sudo docker exec $(sudo docker ps | grep postgres | awk '{print $1}') psql -U postgres -d noname -c "UPDATE prevention_source_types SET is_enabled = 'true' WHERE name = 'aws'"
sudo docker exec $(sudo docker ps | grep postgres | awk '{print $1}') psql -U postgres -d noname -c "UPDATE source_types SET is_enabled = 'true' WHERE name = 'aws-mirroring'"
# configure engine configs
for config in "${ENGINE_CONFIG[@]}"; do
  key=$(echo $config | awk -F',' '{print $1}')
  value=$(echo $config | awk -F',' '{print $2}')
  sudo docker exec $(sudo docker ps | grep postgres | awk '{print $1}') psql -U postgres -d noname -c "UPDATE engine_configs SET value = '${value}' WHERE key = '${key}'"
done

# enable issues
for issue in "${ENABLE_ISSUES[@]}"; do
  sudo docker exec $(sudo docker ps | grep postgres | awk '{print $1}') psql -U postgres -d noname -c "UPDATE issue_types SET default_display = true WHERE title = '$issue'"
done

# disable issues
for issue in "${DISABLE_ISSUES[@]}"; do
  sudo docker exec $(sudo docker ps | grep postgres | awk '{print $1}') psql -U postgres -d noname -c "UPDATE issue_types SET is_enabled = false, default_display = false WHERE title = '$issue'"
done

# Create data types for longitude, latitude, and vehicle ID
sudo docker exec $(sudo docker ps | grep postgres | awk '{print $1}') psql -U postgres -d noname -c "INSERT INTO datatypes (id, title, icon, deleted, disable, sensitive, operator, field_name, field_value, force_obfuscation) values ('<Latitude>', 'Latitude', 'location_on', 'f', 'f', 'f', 'OR', '{(((l|L)atitude)|((L|l)at))}', '{}', 'f')"
sudo docker exec $(sudo docker ps | grep postgres | awk '{print $1}') psql -U postgres -d noname -c "INSERT INTO datatypes (id, title, icon, deleted, disable, sensitive, operator, field_name, field_value, force_obfuscation) values ('<Longitude>', 'Longitude', 'location_on', 'f', 'f', 'f', 'OR', '{(((l|L)ongitude)|((L|l)ong))}', '{}', 'f')"
sudo docker exec $(sudo docker ps | grep postgres | awk '{print $1}') psql -U postgres -d noname -c "INSERT INTO datatypes (id, title, icon, deleted, disable, sensitive, operator, field_name, field_value, force_obfuscation) values ('<VehicleID>', 'Vehicle ID', 'directions_car', 'f', 'f', 'f', 'OR', '{vehicleid}', '{}', 'f')"
# add the sensitive tag to the data types we created
sudo docker exec $(sudo docker ps | grep postgres | awk '{print $1}') psql -U postgres -d noname -c "INSERT INTO tag_datatypes (datatype_id, tag_id) values ('<Latitude>', (SELECT id FROM tags WHERE name = 'Sensitive'))"
sudo docker exec $(sudo docker ps | grep postgres | awk '{print $1}') psql -U postgres -d noname -c "INSERT INTO tag_datatypes (datatype_id, tag_id) values ('<Longitude>', (SELECT id FROM tags WHERE name = 'Sensitive'))"
sudo docker exec $(sudo docker ps | grep postgres | awk '{print $1}') psql -U postgres -d noname -c "INSERT INTO tag_datatypes (datatype_id, tag_id) values ('<VehicleID>', (SELECT id FROM tags WHERE name = 'Sensitive'))"

# Create mailhog cluster type
sudo docker exec $(sudo docker ps | grep postgres | awk '{print $1}') psql -U postgres -d noname -c "INSERT INTO clustering_configs (type, regex, min_count, tag, enabled) values ('MailHogID', '.*=@mailhog.example', 1, '<string>', true)"

# Upload OAS specification
cd ~
TOKEN=$(curl --insecure https://localhost/api/v3/users/generate-api-token -H "Content-Type: application/json" -d '{"email":"noname-su@nonamesecurity.com","password":"'$noname_su_password'"}' | jq .token -r)
sudo aws s3 cp s3://noname-workshop-share/${git_branch}/crapi-spec.yaml ./crapi-spec.yaml
sudo sed -i "s/DNS_KEY/${customer_name}-crapi.nnsworkshop.com/g" crapi-spec.yaml
RULE_ID=$(echo $(sudo docker exec $(sudo docker ps | grep postgres | awk '{print $1}') psql -U postgres -d noname -c "SELECT id FROM oas_rule_file") | awk '{print $3}')
sudo curl --insecure https://localhost/api/v3/openapi/specs\?ruleFiles=$RULE_ID \
  -H "Authorization: Bearer $TOKEN" \
  -F 'files=@crapi-spec.yaml'

# Notify user that Noname is installed
curl https://$callback_host/notify -d '{ "notification": ":tada: Your workshop is ready for login!", "message": "Your workshop for *'$customer_name'* has successfully been installed and is now baselining.\n------\n```Noname instance: https://'$customer_name'.nnsworkshop.com\ncrAPI instance: https://'$customer_name'-crapi.nnsworkshop.com\nMailHog instance: https://'$customer_name'-mailhog.nnsworkshop.com\nPre-work: https://'$customer_name'.nnsworkshop.com/pre-work\nFollow-along guide: https://'$customer_name'.nnsworkshop.com/guide```\n------\n```System user: noname-su@nonamesecurity.com\nPassword: '$noname_su_password'```\n------\n```Password for participants: '$noname_admin_password'```", "channel": "'$slack_channelid'", "user": "'$slack_userid'", "type": "simple_notification"}' -H 'Content-Type: application/json'

#echo new cron into cron file; this sets up a daily reboot and low but persistent (every 30 minutes) traffic
echo "0 0 * * * /sbin/shutdown -r +5" >> dailyreboot.cron
echo '*/30 * * * * USERS_TO_SIMULATE=10 node /opt/noname/baseline-script/' >> dailyreboot.cron
crontab -l -u root >> dailyreboot.cron
crontab -u root dailyreboot.cron
rm dailyreboot.cron

# set up error catch before starting baseline - this tells the user that baseline failed, but install didn't
baseline_failed() {
  curl https://$callback_host/notify -d '{ "notification": ":sob: Your workshop failed to finish baseline!", "message": "Your workshop for *'$customer_name'* has failed to successfully complete baselining.", "channel": "'$slack_channelid'", "user": "'$slack_userid'", "type": "simple_notification"}' -H 'Content-Type: application/json'
}

trap "baseline_failed" ERR

# download baseline script from S3 bucket and update config
sudo aws s3 cp s3://noname-workshop-share/${git_branch}/baseline-script.zip ./baseline-script.zip
sudo unzip baseline-script.zip -d /opt/noname
sudo sed -i "s/CRAPI_HOST/${customer_name}-crapi.nnsworkshop.com/g" /opt/noname/baseline-script/config.js
sudo sed -i "s/MAILHOG_HOST/${customer_name}-mailhog.nnsworkshop.com/g" /opt/noname/baseline-script/config.js

# run baseline script
cd /opt/noname/baseline-script/
sudo npm install
USERS_TO_SIMULATE=3000 node . || true

# Notify user that Noname is baselined
curl https://$callback_host/notify -d '{ "notification": ":tada: Your workshop is ready to go!", "message": "Your workshop for *'$customer_name'* has successfully completed baselining and is ready to go. Have fun with your workshop!", "channel": "'$slack_channelid'", "user": "'$slack_userid'", "type": "simple_notification"}' -H 'Content-Type: application/json'
