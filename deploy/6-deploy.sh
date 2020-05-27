#!/bin/sh

set -e
set -x

cat <<-EOF > kube.config
%KUBE_TOKEN%
EOF

SECRET_NAME=`echo "$ENV_DOMAIN.tls" | tr "." "-"`

cat <<-EOF > ./build-values.yml
keycloak:
  image:
    repository: %APP_IMAGE_NAME%
    tag: $APP_VERSION
EOF

FULL_APP_NAME=`echo "$DEPLOY_DOMAIN" | tr "." "-"`

RELEASE_NAME=$DEPLOY_DOMAIN

if [ ${#RELEASE_NAME} -gt 52 ]; then
  RELEASE_NAME=`echo $RELEASE_NAME | cut -d'.' -f1`
fi


if [[ $DEPLOY == "yes" ]]; then
  helm upgrade --install $RELEASE_NAME \
    codecentric/keycloak \
    --values=./build-values.yml \
    --namespace $DEPLOY_ENV \
    --set keycloak.username=admin \
    --set keycloak.password=qwerty \
    --debug \
    --kubeconfig kube.config \
    --wait
fi

echo "app_image: $APP_IMAGE_NAME:$APP_VERSION" > %BASE_DIR%deploy/app_vars.yaml

echo "##teamcity[buildStatus status='<status value>' text='{build.status.text} url: https://$DEPLOY_DOMAIN  image: $APP_IMAGE_NAME:$APP_VERSION']"
