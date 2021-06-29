#############################################################################################
# Creating Temporary Preview Environments Based On Pull Requests With Argo CD And Codefresh #
#############################################################################################

########################################
# Creating The Project And App Of Apps #
########################################

open https://github.com/vfarcic/argocd-previews

export GH_ORG=[...]

git clone https://github.com/$GH_ORG/argocd-previews.git

cd argocd-previews

git remote add upstream \
    https://github.com/vfarcic/argocd-previews

git fetch upstream

git merge upstream/master

cat project.yaml

kubectl apply --filename project.yaml

cat apps.yaml

cat apps.yaml \
    | sed -e "s@vfarcic@$GH_ORG@g" \
    | tee apps.yaml

git add .

git commit -m "Initial commit"

git push

kubectl apply --filename apps.yaml

ls -1 helm/templates

cd ..

#########################
# Creating The Pipeline #
#########################

open https://github.com/vfarcic/devops-toolkit

git clone https://github.com/$GH_ORG/devops-toolkit.git

cd devops-toolkit

git remote add upstream \
    https://github.com/vfarcic/devops-toolkit

git fetch upstream

git merge upstream/master

cat preview.yaml

echo $INGRESS_HOST

export DH_USER=[...]

cat preview.yaml \
    | sed -e "s@github.com/vfarcic@github.com/$GH_ORG@g" \
    | sed -e "s@repository: vfarcic@repository: $DH_USER@g" \
    | sed -e "s@devopstoolkitseries.com@$INGRESS_HOST.xip.io@g" \
    | tee preview.yaml

cp codefresh/codefresh-pr-open.yml \
    codefresh-pr-open.yml

cat codefresh-pr-open.yml

codefresh get contexts

export CF_GIT_CONTEXT=[...]

codefresh get registry

export CF_REGISTRY=[...]

cat codefresh-pr-open.yml \
    | sed -e "s@repo: vfarcic@repo: $GH_ORG@g" \
    | sed -e "s@image_name: vfarcic@image_name: $DH_USER@g" \
    | sed -e "s@IMAGE: vfarcic@IMAGE: $DH_USER/devops-toolkit@g" \
    | sed -e "s@context: github@context: $CF_GIT_CONTEXT@g" \
    | sed -e "s@git: github@git: $CF_GIT_CONTEXT@g" \
    | sed -e "s@GIT_PROVIDER_NAME: github@GIT_PROVIDER_NAME: $CF_GIT_CONTEXT@g" \
    | sed -e "s@registry: docker-hub@registry: $CF_REGISTRY@g" \
    | tee codefresh-pr-open.yml

git add .

git commit -m "Corrections"

git push

codefresh create pipeline \
    -f codefresh-pr-open.yml

##################################################
# Creating, Syncing, And Reopening Pull Requests #
##################################################

git checkout -b pr-1

echo "A silly change" | tee README.md

git add .

git commit -m "A silly change"

git push --set-upstream origin pr-1

gh pr create \
    --repo $GH_ORG/devops-toolkit \
    --title "A silly change" \
    --body "A silly change indeed"

export PR_NUMBER=[...]

codefresh get builds \
    --pipeline-name devops-toolkit-pr-open

export BUILD_ID=[...]

open https://g.codefresh.io/build/$BUILD_ID

ARGOCD_ADDR=$(kubectl \
    --namespace argocd \
    get ingress argocd-server \
    --output jsonpath="{.spec.rules[0].host}")

echo $ARGOCD_ADDR

open http://$ARGOCD_ADDR

kubectl get namespaces

export APP_ADDR=$(kubectl \
    --namespace pr-devops-toolkit-$PR_NUMBER \
    get ingresses \
    --output jsonpath="{.items[0].spec.rules[0].host}")

echo $APP_ADDR

open http://$APP_ADDR

git checkout master

#########################
# Closing Pull Requests #
#########################

cp codefresh/codefresh-pr-close.yml \
    codefresh-pr-close.yml

cat codefresh-pr-close.yml

cat codefresh-pr-close.yml \
    | sed -e "s@repo: vfarcic@repo: $GH_ORG@g" \
    | sed -e "s@context: github@context: $CF_GIT_CONTEXT@g" \
    | sed -e "s@git: github@git: $CF_GIT_CONTEXT@g" \
    | tee codefresh-pr-close.yml

git add .

git commit -m "Corrections"

git push

codefresh create pipeline \
    -f codefresh-pr-close.yml

open https://github.com/$GH_ORG/devops-toolkit/pull/$PR_NUMBER

codefresh get builds \
    --pipeline-name devops-toolkit-pr-close

export BUILD_ID=[...] # Replace `[...]` with the ID of the last build

open https://g.codefresh.io/build/$BUILD_ID

kubectl get namespaces

kubectl --namespace pr-devops-toolkit-$PR_NUMBER \
    get pods

open https://github.com/$GH_ORG/devops-toolkit/pull/$PR_NUMBER

codefresh get builds \
    --pipeline-name devops-toolkit-pr-open

export BUILD_ID=[...] # Replace `[...]` with the ID of the last build

open https://g.codefresh.io/build/$BUILD_ID

kubectl --namespace pr-devops-toolkit-$PR_NUMBER \
    get pods

###########################
# Destroying The Evidence #
###########################

cd ..

codefresh delete pipeline \
    devops-toolkit-pr-open

codefresh delete pipeline \
    devops-toolkit-pr-close

open https://github.com/$GH_ORG/argocd-previews/settings

# Click the *Delete this repository* button and follow the instructions

open https://github.com/$GH_ORG/devops-toolkit/settings

# Click the *Delete this repository* button and follow the instructions

rm -rf \
    devops-toolkit \
    argocd-previews
