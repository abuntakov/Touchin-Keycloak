#!/bin/sh

set -e
set -x

cat <<-EOF > kube.config
%KUBE_TOKEN%
EOF

SECRET_NAME=`echo "$ENV_DOMAIN.tls" | tr "." "-"`

cat <<-EOF > ./build-values.yml
profile: $DEPLOY_ENV
image:
  repository: %APP_IMAGE_NAME%
  tag: $APP_VERSION

ingress:
  hosts:
    - "$DEPLOY_DOMAIN"
  tls:
    - secretName: $SECRET_NAME
      hosts:
        - "*.$ENV_DOMAIN"
        - "$DEPLOY_DOMAIN"
EOF

FULL_APP_NAME=`echo "$DEPLOY_DOMAIN" | tr "." "-"`

if [ -f "deploy/%APP_NAME%/values-$DEPLOY_ENV.yaml" ]; then
  cat "deploy/%APP_NAME%/values-$DEPLOY_ENV.yaml" >> ./build-values.yml
fi

DB_NAME_POSTFIX=""

if [ ! "$MILESTONE_NAME" == "" ]; then
  DB_NAME_POSTFIX="__${MILESTONE_NAME}"
fi

RELEASE_NAME=$DEPLOY_DOMAIN

if [ ${#RELEASE_NAME} -gt 52 ]; then
  RELEASE_NAME=`echo $RELEASE_NAME | cut -d'.' -f1`
fi


if [[ $DEPLOY == "yes" ]]; then
  helm upgrade --install $RELEASE_NAME \
    ./%APP_NAME%-$APP_VERSION.tgz \
    --values=./build-values.yml \
    --namespace $DEPLOY_ENV \
    --set db.namePostfix=$DB_NAME_POSTFIX \
    --set server.url=$SERVER_URL \
    --set fullnameOverride=$FULL_APP_NAME \
    --debug \
    --kubeconfig kube.config \
    --wait
fi

echo "app_image: $APP_IMAGE_NAME:$APP_VERSION" > %BASE_DIR%deploy/app_vars.yaml

echo "##teamcity[buildStatus status='<status value>' text='{build.status.text} url: https://$DEPLOY_DOMAIN  image: $APP_IMAGE_NAME:$APP_VERSION']"
