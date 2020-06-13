set -e
rm -rf deploy
mkdir -p deploy

cp -r site ./deploy/

mkdir -p ./deploy/web
cp -r web/css ./deploy/web/
cp -r web/js ./deploy/web/
cp -r web/static ./deploy/web/
cp -r web/templates ./deploy/web/

cp -r gerbil_release ./deploy/

tar -czvf deploy.tgz ./deploy
scp -r ./deploy.tgz <USER>@<HOST>:<SERVER_TEMP_LOCATION_FOR_DEPLOY_FILES>
