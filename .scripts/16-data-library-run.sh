#!/bin/bash
set -ex

# Install dependencies before changing commits
find .scripts -name requirements.txt | xargs --no-run-if-empty -n 1 pip install -r
echo '[galaxyservers]' > ~/.hosts
echo "$(hostname -f) ansible_connection=local ansible_user=$(whoami)"  >> ~/.hosts
echo '[pulsarservers]' >> ~/.hosts
echo "$(hostname -f) ansible_connection=local ansible_user=$(whoami)"  >> ~/.hosts
echo '[dbservers:children]' >> ~/.hosts
echo 'galaxyservers' >> ~/.hosts
echo '[monitoring]' >> ~/.hosts
echo "$(hostname -f) ansible_connection=local ansible_user=$(whoami)"  >> ~/.hosts
export GALAXY_HOSTNAME="$(hostname -f)"
export GALAXY_API_KEY=adminkey
## The students should use a random password, we override with 'password' for reproducibility
echo 'password' > ~/.vault-password.txt;
## And one in this directory, it can contain garbage
echo 'garbage' > ./.vault-password.txt;
## Ensure the galaxy user is setup
sudo -u galaxy /srv/galaxy/venv/bin/python /usr/bin/galaxy-create-user -c /srv/galaxy/config/galaxy.yml --user admin@example.org --password password --key adminkey --username admin

# CMD
## Checkout
git checkout $(git log main --pretty=oneline | grep "admin/data-library/0001" | cut -c1-40)
## Run command
if [[ -z ${GALAXY_VERSION} ]]; then
ansible-playbook galaxy.yml -i ~/.hosts --vault-password-file ~/.vault-password.txt
else
ansible-playbook galaxy.yml -i ~/.hosts --vault-password-file ~/.vault-password.txt -e galaxy_commit_id=${GALAXY_VERSION}
fi

# TEST
## Checkout
git checkout $(git log main --pretty=oneline | grep "admin/data-library/0001" | cut -c1-40)
## Run test case
./.scripts/16-data-library-test/1.sh

# CMD
## Checkout
git checkout $(git log main --pretty=oneline | grep "admin/data-library/0001" | cut -c1-40)
## Run command
setup-data-libraries -g https://galaxy.example.org -a adminkey --training -i /libraries/example-library.yaml --legacy

# TEST
## Checkout
git checkout $(git log main --pretty=oneline | grep "admin/data-library/0001" | cut -c1-40)
## Run test case
./.scripts/16-data-library-test/2.sh
# Done!
git checkout main
