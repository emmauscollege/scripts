#! /bin/bash

# If you've never seen a shell script like this, look her for a basic startersguide on scripting
# https://medium.com/tech-tajawal/writing-shell-scripts-the-beginners-guide-4778e2c4f609

# The full usermanual on bash can be found here
# http://www.gnu.org/savannah-checkouts/gnu/bash/manual/bash.html

# I use this script on MacOSX, look here how to run this script on Windows 10
# https://www.howtogeek.com/261591/how-to-create-and-run-bash-shell-scripts-on-windows-10/

# username and token to acces yout github account
# for security reasons it is not allowed to use your github password
# instead, a token can be generated which acts as a replacement for your password
# more info on https://docs.github.com/en/rest/guides/getting-started-with-the-rest-api#authentication"
organisation="emmaus-5v"
username="vangeest"
# if token is not defined
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

echo

curl -i -u @username:$token https://api.github.com/emmauscollege/scripts

# list full_name of all repo's (max 30) in organisation
curl -i -u $username:$token https://api.github.com/orgs/$organisation/repos | grep full_name

