#!/bin/bash

WORKSHOPS=$(aws s3api list-objects-v2 --bucket nn-workshop-tf-states --prefix env:/ | jq .Contents -r -c)

EXPIREDWORKSHOPS=()
EXPIRETOMORROW=()

for WORKSHOP in $(echo $WORKSHOPS | jq -c '.[]')
do
  CUSTOMERNAME=$(echo $WORKSHOP | awk -F '/' '{print $2}')
  TAGS=$(aws s3api get-object-tagging --bucket nn-workshop-tf-states --key $(echo $WORKSHOP | jq '.Key' -r))

  CREATEDON=$(echo $TAGS | jq '.TagSet[] | select(.Key=="creationDate") | .Value' -r)
  EXPIRATIONDATE=$(echo $TAGS | jq '.TagSet[] | select(.Key=="labEndDate") | .Value' -r)
  SLACKCHANNELID=$(echo $TAGS | jq '.TagSet[] | select(.Key=="slackChannelID") | .Value' -r)
  SLACKUSERID=$(echo $TAGS | jq '.TagSet[] | select(.Key=="slackUserID") | .Value' -r)
  REGION=$(echo $TAGS | jq '.TagSet[] | select(.Key=="region") | .Value' -r)
  TODAY=$(date +'%Y%m%d')
  FUTURE=$(date -d "2 days" +'%Y%m%d')

  if [ "$EXPIRATIONDATE" = "$TODAY" ]; then
    EXPIRETOMORROW+=("$CUSTOMERNAME $SLACKUSERID $SLACKCHANNELID $REGION")
  elif [ "$EXPIRATIONDATE" -le $FUTURE ]; then
    EXPIRESOON+=("$CUSTOMERNAME $SLACKUSERID $SLACKCHANNELID $REGION $EXPIRATIONDATE")
  fi

  if [ $EXPIRATIONDATE -lt $TODAY ]; then
    EXPIREDWORKSHOPS+=("$CUSTOMERNAME $SLACKUSERID $SLACKCHANNELID $REGION")
  fi

done

echo "expiring-count=${#EXPIRETOMORROW[@]}" >> $GITHUB_OUTPUT
echo "expired-count=${#EXPIREDWORKSHOPS[@]}" >> $GITHUB_OUTPUT
echo "expiresoon-count=${#EXPIRESOON[@]}" >> $GITHUB_OUTPUT

EXPIREDWORKSHOPS=$(jq --compact-output --null-input '$ARGS.positional' --args -- "${EXPIREDWORKSHOPS[@]}")
EXPIRETOMORROW=$(jq --compact-output --null-input '$ARGS.positional' --args -- "${EXPIRETOMORROW[@]}")
EXPIRESOON=$(jq --compact-output --null-input '$ARGS.positional' --args -- "${EXPIRESOON[@]}")


echo "expired-workshops=$EXPIREDWORKSHOPS" >> $GITHUB_OUTPUT
echo "expiring-workshops=$EXPIRETOMORROW" >> $GITHUB_OUTPUT
echo "expiresoon-workshops=$EXPIRESOON" >> $GITHUB_OUTPUT
