#! /bin/bash

# THIS SCRIPT IS NOT TESTED AND NOT FINISHED

###
# documentaton
# adjust settings below
# usage: github-create-repos < repos.txt
# input: names of repo's in repos.txt, one repo per line
###

###
# settings
###

# username to access github
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
# create repo's from a template
###

# loop for all repo's read from stdin
while read repo
do
  # create repo from template
  echo "CREATE REPO https://api.github.com/repos/$template_organisation/$template_repo/generate"'{"name":"'$repo'","private":"'$private'"}'
  nextstep
  curl -X POST -H "Accept: application/vnd.github.v3+json" -u $username:$token \
    https://api.github.com/repos/$template_organisation/$template_repo/generate \
    -d '{"name":"'$repo'","private":"'$private'"}'
  # wait some time (work around to prevent "Not Found" errors in next curl statement)
  sleep 2

done

exit
##################################

for repo_old in \
  $(curl -H "Accept: application/vnd.github.v3+json" -u $username:$token \
    https://api.github.com/orgs/$organisation_old/repos?per_page=100 \
    | jq -r ".[].name" )
do
  
  # change organisation
  echo "CHANGE ORGANISATION https://api.github.com/repos/$organisation_old/$repo_old/transfer"'{"new_owner":"'$organisation_new'"}'
  nextstep
  curl -X POST -H "Accept: application/vnd.github.v3+json" -u $username:$token \
    https://api.github.com/repos/$organisation_old/$repo_old/transfer \
    -d '{"new_owner":"'$organisation_new'"}'
  # wait some time (work around to prevent "Not Found" errors in next curl statement)
  sleep 2

  # change name of repo
  repo_new=$repo_prefix$repo_old
  echo "CHANGE REPO https://api.github.com/repos/$organisation_new/$repo_old"'{"name":"'$repo_new'"}'
  nextstep
  curl -X PATCH -H "Accept: application/vnd.github.v3+json" -u $username:$token \
    https://api.github.com/repos/$organisation_new/$repo_old \
    -d '{"name":"'$repo_new'"}'
  # wait some time (work around to prevent "Not Found" errors in next curl statement)
  sleep 2

  # remove outside collaborators (=toegang leerlingen verwijderen)
  for collaborator in \
    $(curl -H "Accept: application/vnd.github.v3+json" -u $username:$token \
      https://api.github.com/repos/$organisation_new/$repo_new/collaborators?affiliation=outside \
      | jq -r ".[].login")
  do
    # remove outside collaborator 
    echo "REMOVE COLLABORATOR https://api.github.com/repos/'$organisation_new'/'$repo_new/collaborators/$collaborator"
    nextstep
    curl -X DELETE -H "Accept: application/vnd.github.v3+json" -u $username:$token \
         https://api.github.com/repos/$organisation_new/$repo_new/collaborators/$collaborator
  done

  ## change permission of outside collaborators to read-only (= alternatief voor leerlingen verwijderenre)
  #for collaborator in \
  #  $(curl -H "Accept: application/vnd.github.v3+json" -u $username:$token \
  #    https://api.github.com/repos/$organisation_new/$repo_new/collaborators?affiliation=outside \
  #    | jq -r ".[].login")
  #  do
  #   # change permission of collaborator to read(aka pull)
  #   # more info at https://github.community/t/update-collaborator-permission/14579
  #   echo "CHANGE COLLABORATOR https://api.github.com/repos/$organisation_new/$repo_new/collaborators/$collaborator {\"permission\":\"pull\"}"
  #   curl -X PUT -H "Accept: application/vnd.github.v3+json" -u $username:$token \
  #        https://api.github.com/repos/$organisation_new/$repo_new/collaborators/$collaborator \
  #        -d '{"permission":"pull"}'
  #done

done

###
# other examples of code in comments
###

# list outside collaborators (max 30) of a repo
# organisation="emmaus-5v"
# repo="webshop-in1-boris-LarsH-steijn"
# curl -u $username:$token https://api.github.com/repos/$organisation/$repo/collaborators?affiliation=outside | jq -r ".[].login"

# delete collaborator (alternative is to change permission)
# curl \
#  -X DELETE \
#  -H "Accept: application/vnd.github.v3+json" \
#  https://api.github.com/repos/octocat/hello-world/collaborators/USERNAME


# change permission of collaborator to read(aka pull)
# more info at https://github.community/t/update-collaborator-permission/14579
# curl -X PUT -H "Accept: application/vnd.github.v3+json" \
#  https://api.github.com/repos/$organisation/$repo/collaborators/$collaborator \
#  -d '{"permission":"pull"}'
