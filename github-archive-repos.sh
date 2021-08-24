#! /bin/bash

###
# documentaton
###

# If you've never seen a bash script like this, look her for a basic startersguide on scripting
# https://medium.com/tech-tajawal/writing-shell-scripts-the-beginners-guide-4778e2c4f609

# The full usermanual on bash can be found here
# http://www.gnu.org/savannah-checkouts/gnu/bash/manual/bash.html

# I run this script in the cloud on https://gitpod.io/ using a free account,
# if you want to run it on Windows 10, look here
# https://www.howtogeek.com/261591/how-to-create-and-run-bash-shell-scripts-on-windows-10/

# this script depends on curl, a quick startersguide for curl can be found here
# https://dev.to/iggredible/how-to-make-api-request-with-curl-kg8

# this script depends on jq, a quick startersguide for qt can be found here
# https://www.baeldung.com/linux/jq-command-json

# this scripts uses the github rest api, documentation can be found here
# https://docs.github.com/en/rest


###
# definitions
###
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
# do the actual work
###

# list full_name of all repo's (max 30) in organisation
curl -H "Accept: application/vnd.github.v3+json" -u $username:$token https://api.github.com/orgs/$organisation/repos | jq -r ".[].full_name"

# move a repo to the archive
# example: organisation_old="emmaus-5v"
organisation_old="emmaus-5v"
organisation_new="emmaus-archief"
# example: repo_old="webshop-in1-boris-LarsH-steijn"
repo_old="webshop-voorbeeld"
repo_new="2021-5V-"$repo_old

# change organisation
echo "CHANGE ORGANISATION https://api.github.com/repos/$organisation_old/$repo_old/transfer {\"new_owner\":\"'$organisation_new'\"}"
nextstep
curl -X POST -H "Accept: application/vnd.github.v3+json" -u @username:$token \
  https://api.github.com/repos/$organisation_olds/$repo_old/transfer \
  -d '{"new_owner":"'$organisation_new'"}'

# change name of repo
echo "CHANGE REPO https://api.github.com/repos/$organisation_new/$repo_old {\"name\":\"'$repo_new'\"}"
nextstep
curl -X PATCH -H "Accept: application/vnd.github.v3+json" -u $username:$token \
  https://api.github.com/repos/$organisation_new/$repo_old \
  -d '{"name":"'$repo_new'"}'

# remove outside collaborators (=toegang leerlingen verwijderen)
for collaborator in \
  $(curl -H "Accept: application/vnd.github.v3+json" -u $username:$token \
    https://api.github.com/repos/$organisation_new/$repo_new/collaborators?affiliation=outside \
    | jq -r ".[].login")
  do
   # remove outside collaborator 
   echo "REMOVE COLLABORATOR https://api.github.com/repos/$organisation_new/$repo_new/collaborators/$collaborator"
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
