#! /bin/bash

# THIS SCRIPT IS NOT TESTED

###
# documentaton
# purpose: create repos from template with (groups of) students added as collaborators
# before use: adjust settings below
# usage: github-create-repos < repos.txt
# input: repos.txt contains name of repo and name of user on each line
#        the same repo may be used on multiple lines
###

###
# settings
###

# username to access github, a corresponding token needs to be set as environment variabel
username="vangeest"
# location/name of template
template_organisation="emmauscollege"
template_repo="4H-website-template"
# location where repo is created
target_organisation="emmaus-4h"
# "true" creates private repo, "false" creates public repo
private="true"

###
# definitions
###

# function that asks for user confirmation to allow step by step execution of script
steps=0
function nextstep {
  if [ $steps -le 0 ]
  then
    read -p "How many steps (CHANGES, ADDITIONS, REMOVALS etc) do you want to do untill next pause : " steps
  fi
  steps=$(($steps - 1))
  echo $steps" steps left"
}

###
# authentication
###

# username and token to access your github account
# for security reasons github doesn't allow to use your password to access the rest-api
# instead, a token can be generated which acts as a replacement for your password
# more info on https://docs.github.com/en/rest/guides/getting-started-with-the-rest-api#authentication"
organisation="emmauscollege"
username="vangeest"
# check if token is defined
if [ -z $token ] 
then
echo "ERROR: environment variable \"token\" not defined"
echo "create a token on github and set the environment variable token before executing this script"
echo "more info on how to create a personal token:"
echo "https://docs.github.com/en/github/authenticating-to-github/keeping-your-account-and-data-secure/creating-a-personal-access-token"
echo "set environment variable with following commands:"
echo "token=\"whatever token you created\""
echo "export token"
exit 1
fi

# check for a valid response from github
status_code=$(curl -u @username:$token --write-out %{http_code} --silent --output /dev/null https://api.github.com/user)
if [ $status_code -eq 200 ]
  then
  curl -H "Accept: application/vnd.github.v3+json" -u @username:$token https://api.github.com/user | grep login
  echo "Login to github succeeded"
else
  curl -i -H "Accept: application/vnd.github.v3+json" -u @username:$token https://api.github.com/user
  echo "ERROR: login to github failed, maybe your username is invalid or your token expired"
  exit 1
fi

echo
echo
echo

###
# do the actual work:
# create repo's from a template (unless it already exists)
# add user as collaborator with push (write) permission
###

# loop for all lines with repo and user read from stdin 
while read repo user
do
  # create repo from template (assuming is will fail if it already exists)
  echo "CREATE REPO https://api.github.com/repos/$template_organisation/$template_repo/generate"'{"name":"'$repo'","private":"'$private'"}'
  nextstep
  curl -X POST -H "Accept: application/vnd.github.v3+json" -u $username:$token \
    https://api.github.com/repos/$template_organisation/$template_repo/generate \
    -d '{"name":"'$repo'","private":"'$private'"}'
  # wait some time (work around to prevent "Not Found" errors in next curl statement)
  sleep 2

  # add user as collaborator (if user already is collaborator, then permissions will be updated)
  # more info at https://github.community/t/update-collaborator-permission/14579
  # user will be invited via email by github and needs to accept the invitation
  curl -X PUT -H "Accept: application/vnd.github.v3+json" \
       https://api.github.com/repos/$target_organisation/$repo/collaborators/$user \
       -d '{"permission":"push"}'
done
