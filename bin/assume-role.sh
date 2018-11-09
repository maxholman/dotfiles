#!/bin/bash

# START USAGE DOCUMENTATION
# assume-role is a command line tool to help assume roles through a bastion account with MFA.
# Store your bastion account credentials here ~/.aws/credentials
#
# Usage: assume-role [account_name] [role] [mfa_token] [aws-region]
#
# account_name          account id or alias
#                       aliases stored in ~/.aws/accounts as JSON {"alias": account_id}
#                       [default 'default']
# role                  the role to assume into the account
#                       [default 'read']
# mfa_token             The MFA token for the user
#                       only valid if not using SAML for auth
#
# aws_region            region to assume into default set in ~/.aws/config
#
# END USAGE DOCUMENTATION

echo_out() {
  # If this is outputting to an eval statement we need to output a "echo" as well
  if [ -z "$OUTPUT_TO_EVAL" ]; then
    echo "$@"
  else
    echo "echo \"$*\";"
  fi
}

assume-role(){
  setup "$@" || return 1

  if [[ $AWS_ASSUME_ROLE_AUTH_SCHEME == "saml" ]]; then
    assume-role-with-saml || return 1
  elif [[ $AWS_ASSUME_ROLE_AUTH_SCHEME == "bastion" ]]; then
    assume-role-with-bastion || return 1
  else
    return 1
  fi

  export-envars
  debug-info
  cleanup
}

setup() {
  #######
  # PRE-CONDITIONS
  #######

  # requires jq
  if ! hash jq 2>/dev/null; then
    echo_out "assume-role requires 'jq' to be installed"
    return 1
  fi

  # requires aws
  if ! hash aws 2>/dev/null; then
    echo_out "assume-role requires 'aws' to be installed"
    return 1
  fi

  #######
  # SCRIPT VARIABLES
  #######

  # exports
  export AWS_SESSION_START
  export AWS_SESSION_ACCESS_KEY_ID
  export AWS_SESSION_SECRET_ACCESS_KEY
  export AWS_SESSION_SESSION_TOKEN
  export AWS_SESSION_SECURITY_TOKEN
  export AWS_ACCESS_KEY_ID
  export AWS_SECRET_ACCESS_KEY
  export AWS_SESSION_TOKEN
  export AWS_SECURITY_TOKEN
  export AWS_REGION
  export AWS_DEFAULT_REGION
  export AWS_ACCOUNT_ID
  export AWS_ACCOUNT_NAME
  export AWS_ACCOUNT_ROLE
  export GEO_ENV
  export AWS_PROFILE_ASSUME_ROLE

  # INPUTS
  if [[ $AWS_ASSUME_ROLE_AUTH_SCHEME == "saml" ]]; then
    account_name_input=$1
    role_input=$2
    aws_region_input=$3
  else
    account_name_input=$1
    role_input=$2
    mfa_token_input=$3
    aws_region_input=$4
  fi

  # DEFAULT VARIABLES
  ACCOUNTS_FILE=${ACCOUNTS_FILE:-~/.aws/accounts}
  SAML_FILE=${SAML_FILE:-~/.saml/credentials}
  SESSION_TIMEOUT=43200
  ROLE_SESSION_TIMEOUT=3600
  AWS_ASSUME_ROLE_AUTH_SCHEME=${AWS_ASSUME_ROLE_AUTH_SCHEME:-bastion}

  if [[ $AWS_ASSUME_ROLE_AUTH_SCHEME == "saml" ]] && ! echo "$SAML_IDP_ASSERTION_URL" | grep -q "^https"; then
    echo_out "[WARNING] - Using non-https url ($SAML_IDP_ASSERTION_URL) for SAML authentication. Your credentials may be sent via plaintext."
  fi

  # Force use of ~/.aws/credentials file which contains aws login account
  unset AWS_ACCESS_KEY_ID
  unset AWS_SECRET_ACCESS_KEY
  unset AWS_SESSION_TOKEN
  unset AWS_SECURITY_TOKEN

  #######
  # SETUP
  #######

  # load default assume-role profile if available, use "default" otherwise
  if [ "$AWS_PROFILE_ASSUME_ROLE" ]; then
    echo_out "Using assume-role default profile: $AWS_PROFILE_ASSUME_ROLE"
    default_profile=${AWS_PROFILE_ASSUME_ROLE}
  else
    default_profile="default"
  fi

  # load user-set ROLE_SESSION_TIMEOUT (up to 12h, 43200 seconds), use default 1h defined above otherwise
  if [ "$AWS_ROLE_SESSION_TIMEOUT" ]; then
    ROLE_SESSION_TIMEOUT=${AWS_ROLE_SESSION_TIMEOUT}
  fi

  # set account_name
  if [ -z "$account_name_input" ] && [ -z "$OUTPUT_TO_EVAL" ]; then
    echo -n "Assume Into Account [default]:"
    read -r account_name
    # default
    account_name=${account_name:-"default"}
  else
    account_name="$account_name_input"
  fi

  # set account_id
  if [ -f "$ACCOUNTS_FILE" ]; then
    account_id=$(jq ".[\"$account_name\"]" < "$ACCOUNTS_FILE" | jq --raw-output "select(. != null)")
  fi

  # If cant find the alias then set the input as the account id
  if [ -z "$account_id" ]; then
    account_id=$account_name
  fi

  # Validate Account ID
  if [[ ! $account_id =~ ^[0-9]{12}$ ]]; then
    echo_out "account_id \"$account_id\" is incorrectly formatted AWS account id"
    return 1
  fi

  # set role
  if [ -z "$role_input" ] && [ -z "$OUTPUT_TO_EVAL" ]; then
    echo -n "Assume Into Role [read]: "
    read -r role
    role=${role:-"read"}
  else
    role="$role_input"
  fi

  if [ -z "$role" ]; then
    echo_out "role not defined"
    return 1
  fi

  # set region
  AWS_CONFIG_REGION="$(aws configure get region --profile ${default_profile})"
  if [ -z "$aws_region_input" ] && [ -z "$AWS_REGION" ] && [ -z "$AWS_DEFAULT_REGION" ] && [ -z "$AWS_CONFIG_REGION" ] && [ -z "$OUTPUT_TO_EVAL" ]; then
    echo -n "Assume Into Region [us-east-1]: "
    read -r region
    region=${region:-"us-east-1"}
  elif [ ! -z "$aws_region_input" ]; then
    # if there is a $aws_region_input then set to $aws_region_input
    region="$aws_region_input"
  elif [ ! -z "$AWS_REGION" ]; then
    # if there is a $AWS_REGION then set to $AWS_REGION
    region="$AWS_REGION"
  elif [ ! -z "$AWS_DEFAULT_REGION" ]; then
    # if there is a $AWS_DEFAULT_REGION then set to $AWS_DEFAULT_REGION
    region="$AWS_DEFAULT_REGION"
  elif [ ! -z "$AWS_CONFIG_REGION" ]; then
    region=$AWS_CONFIG_REGION
  fi

  if [ -z "$region" ]; then
    echo_out "region not defined"
    return 1
  fi

  AWS_REGION="$region"
  AWS_DEFAULT_REGION="$region"
}

assume-role-with-saml() {
  if [ -f "$SAML_FILE" ]; then
    saml_user=$(sed -nE 's/username = (.+)/\1/gp' "$SAML_FILE")
    saml_password=$(sed -nE 's/password = (.+)/\1/gp' "$SAML_FILE")
  fi

  echo_out "Gathering SAML credentials..."
  if [ -n "$OUTPUT_TO_EVAL" ] && { [ -z "$saml_user" ] || [ -z "$saml_password" ] ;}; then
    echo_out "assume-role-with-saml only supports eval if used with $SAML_FILE for credentials"
    unset saml_password
    return 1
  fi

  if [ -z "$saml_user" ]; then
    echo_out -n "Username: "
    read -r saml_user
  fi

  if [ -z "$saml_password" ]; then
    echo_out -n "Password: "
    read -r -s saml_password
    echo_out
  fi

  echo_out "Authenticating with SAML provider..."
  api_body=$(python -c "print '$SAML_IDP_REQUEST_BODY_TEMPLATE'.replace('\$saml_password', '$saml_password').replace('\$saml_user', '$saml_user')")

  # Should be ok to post password as long as service is over SSL
  saml_assertion_b64=$(curl -s -X POST "$SAML_IDP_ASSERTION_URL" -H "Content-Type: application/json" -d "$api_body" | jq .saml_response -r)

  unset saml_password
  unset api_body

  if [ "$saml_assertion_b64" = "null" ]; then
    echo_out "Incorrect endpoint ($SAML_IDP_ASSERTION_URL), username or password."
    return 1
  fi

  NOW=$(date +"%s")
  ROLE_SESSION_START=$NOW

  ROLE_SESSION_ARGS=(--role-arn arn:aws:iam::"${account_id}":role/"${role}")
  ROLE_SESSION_ARGS+=(--principal-arn arn:aws:iam::"${account_id}":saml-provider/"${SAML_IDP_NAME}")
  ROLE_SESSION_ARGS+=(--saml-assertion "$saml_assertion_b64")
  ROLE_SESSION_ARGS+=(--duration-seconds "${ROLE_SESSION_TIMEOUT}")

  ROLE_SESSION=$(aws sts assume-role-with-saml "${ROLE_SESSION_ARGS[@]}" || return 1)
}

assume-role-with-bastion() {
  # Activate our session
  NOW=$(date +"%s")
  if [ -z "$AWS_SESSION_START" ]; then
    AWS_SESSION_START=0
  fi

  ABOUT_SESSION_TIMEOUT=$((SESSION_TIMEOUT - 200))
  SESSION_TIMEOUT_DELTA=$((NOW - AWS_SESSION_START))

  # if session doesn't exist, or is expired
  if [ "$ABOUT_SESSION_TIMEOUT" -lt "$SESSION_TIMEOUT_DELTA" ]; then
    # We'll need a token to renew session
    if [ -z "$mfa_token_input" ] && [ -z "$OUTPUT_TO_EVAL" ]; then
      echo -n "MFA Token: "
      read -r -s mfa_token
      echo
    else
      mfa_token="$mfa_token_input"
    fi

    if [ -z "$mfa_token" ]; then
      echo_out "mfa_token is not defined"
      return 1
    fi

    # get the username attached to your default creds
    AWS_USERNAME=$(aws iam get-user --query User.UserName --output text --profile $default_profile)


    # get MFA device attached to default creds
    MFA_DEVICE_ARGS=(--user-name "$AWS_USERNAME")
    MFA_DEVICE_ARGS+=(--query 'MFADevices[0].SerialNumber')
    MFA_DEVICE_ARGS+=(--output text)
    MFA_DEVICE_ARGS+=(--profile "${default_profile}")
    MFA_DEVICE=$(aws iam list-mfa-devices "${MFA_DEVICE_ARGS[@]}")
    MFA_DEVICE_STATUS=$?

    if [ $MFA_DEVICE_STATUS -ne 0 ]; then
      echo_out "aws iam list-mfa-devices error"
      return 1
    fi

    # 12 hour MFA w/ Session Token, which can then be reused
    SESSION_ARGS=(--duration-seconds "$ROLE_SESSION_TIMEOUT")
    SESSION_ARGS+=(--serial-number "${MFA_DEVICE}")
    SESSION_ARGS+=(--token-code "${mfa_token}")
    SESSION_ARGS+=(--profile "${default_profile}")

    SESSION=$(aws sts get-session-token "${SESSION_ARGS[@]}")

    SESSION_STATUS=$?

    if [ $SESSION_STATUS -ne 0 ]; then
      echo_out "aws sts get-session-token error"
      return 1
    fi

    # Save Primary Credentials
    AWS_SESSION_START=$NOW
    AWS_SESSION_ACCESS_KEY_ID=$(echo "$SESSION" | jq -r .Credentials.AccessKeyId)
    AWS_SESSION_SECRET_ACCESS_KEY=$(echo "$SESSION" | jq -r .Credentials.SecretAccessKey)
    AWS_SESSION_SESSION_TOKEN=$(echo "$SESSION" | jq -r .Credentials.SessionToken)
    AWS_SESSION_SECURITY_TOKEN=$AWS_SESSION_SESSION_TOKEN
  fi

  # Use the Session in the login account
  export AWS_ACCESS_KEY_ID=$AWS_SESSION_ACCESS_KEY_ID
  export AWS_SECRET_ACCESS_KEY=$AWS_SESSION_SECRET_ACCESS_KEY
  export AWS_SESSION_TOKEN=$AWS_SESSION_SESSION_TOKEN
  export AWS_SECURITY_TOKEN=$AWS_SESSION_SECURITY_TOKEN

  ROLE_SESSION_START=$NOW

  # Now drop into a role using session token's long-lived MFA
  ROLE_SESSION_ARGS=(--role-arn arn:aws:iam::"${account_id}":role/"${role}")
  ROLE_SESSION_ARGS+=(--external-id "${account_id}")
  ROLE_SESSION_ARGS+=(--duration-seconds "${ROLE_SESSION_TIMEOUT}")
  ROLE_SESSION_ARGS+=(--role-session-name "$(date +%s)")

  ROLE_SESSION=$(aws sts assume-role "${ROLE_SESSION_ARGS[@]}" || echo "fail")
}

export-envars() {
  if [ "$ROLE_SESSION" = "fail" ]; then
     echo_out "Failed to export session envars."
     # This will force a new session next time assume-role is run
     unset AWS_SESSION_START
  else
    AWS_ACCESS_KEY_ID=$(echo "$ROLE_SESSION" | jq -r .Credentials.AccessKeyId)
    AWS_SECRET_ACCESS_KEY=$(echo "$ROLE_SESSION" | jq -r .Credentials.SecretAccessKey)
    AWS_SESSION_TOKEN=$(echo "$ROLE_SESSION" | jq -r .Credentials.SessionToken)
    export AWS_ACCESS_KEY_ID
    export AWS_SECRET_ACCESS_KEY
    export AWS_SESSION_TOKEN
    export AWS_SECURITY_TOKEN=$AWS_SESSION_TOKEN
    export AWS_ACCOUNT_ID="$account_id"
    export AWS_ACCOUNT_NAME="$account_name"
    export AWS_ACCOUNT_ROLE="$role"
    export ROLE_SESSION_START="$ROLE_SESSION_START"
    export GEO_ENV="$account_name" # For GeoEngineer https://github.com/coinbase/geoengineer
    echo_out "Success! IAM session envars are exported."
  fi

  # OUTPUTS ALL THE EXPORTS for eval $(assume-role [args])
  if [ "$OUTPUT_TO_EVAL" = "true" ]; then
    echo "export AWS_REGION=\"$AWS_REGION\";"
    echo "export AWS_DEFAULT_REGION=\"$AWS_DEFAULT_REGION\";"
    echo "export AWS_ACCESS_KEY_ID=\"$AWS_ACCESS_KEY_ID\";"
    echo "export AWS_SECRET_ACCESS_KEY=\"$AWS_SECRET_ACCESS_KEY\";"
    echo "export AWS_SESSION_TOKEN=\"$AWS_SESSION_TOKEN\";"
    echo "export AWS_ACCOUNT_ID=\"$AWS_ACCOUNT_ID\";"
    echo "export AWS_ACCOUNT_NAME=\"$AWS_ACCOUNT_NAME\";"
    echo "export AWS_ACCOUNT_ROLE=\"$AWS_ACCOUNT_ROLE\";"
    echo "export AWS_SESSION_ACCESS_KEY_ID=\"$AWS_SESSION_ACCESS_KEY_ID\";"
    echo "export AWS_SESSION_SECRET_ACCESS_KEY=\"$AWS_SESSION_SECRET_ACCESS_KEY\";"
    echo "export AWS_SESSION_SESSION_TOKEN=\"$AWS_SESSION_SESSION_TOKEN\";"
    echo "export AWS_SESSION_SECURITY_TOKEN=\"$AWS_SESSION_SESSION_TOKEN\";"
    echo "export AWS_SESSION_START=\"$AWS_SESSION_START\";"
    echo "export GEO_ENV=\"$GEO_ENV\";"
    echo "export AWS_PROFILE_ASSUME_ROLE=\"$AWS_PROFILE_ASSUME_ROLE\";"
    echo "export AWS_SECURITY_TOKEN=\"$AWS_SESSION_TOKEN\";"
  fi
}

debug-info() {
  # USED FOR TESTING AND DEBUGGING
  if [ "$DEBUG_ASSUME_ROLE" = "true" ]; then
    echo "AWS_CONFIG_REGION=\"$AWS_CONFIG_REGION\";"
    echo "AWS_USERNAME=\"$AWS_USERNAME\";"
    echo "MFA_DEVICE_ARGS=\"${MFA_DEVICE_ARGS[*]}\";"
    echo "MFA_DEVICE=\"$MFA_DEVICE\";"
    echo "SESSION_ARGS=\"${SESSION_ARGS[*]}\";"
    echo "SESSION=\"$SESSION\";"
    echo "ROLE_SESSION_ARGS=\"${ROLE_SESSION_ARGS[*]}\";"
    echo "ROLE_SESSION=\"$ROLE_SESSION\";"
    echo "SESSION_TIMEOUT=\"$SESSION_TIMEOUT\";"
    echo "ROLE_SESSION_TIMEOUT=\"$ROLE_SESSION_TIMEOUT\";"
    echo "AWS_PROFILE_ASSUME_ROLE=\"$AWS_PROFILE_ASSUME_ROLE\";"
  fi
}

cleanup() {
  unset ROLE_SESSION
  unset ROLE_SESSION_ARGS
  unset SESSION
  unset SESSION_ARGS
  unset SESSION_TIMEOUT
  unset api_body
  unset saml_password
  unset account_name_input
  unset role_input
  unset aws_region_input
  unset mfa_token
}

# from https://stackoverflow.com/questions/2683279/how-to-detect-if-a-script-is-being-sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
  # If the script is being sourced, do nothing
  # Supports `source $(which assume_role)` in rc file for bash and zsh
  : # noop
elif [[ "init" == "${1}" ]]; then
  # TODO: This will be multi-shell support like rbenv, e.g. fish
  # Supports `eval "$(assume-role init -)"` in rc file
  echo "Currently not supported"
else
  # The script is being called directly
  # Supports calling being called like eval $(assume-role account role [token])
  set -eo pipefail
  OUTPUT_TO_EVAL="true"
  assume-role "$@";
fi