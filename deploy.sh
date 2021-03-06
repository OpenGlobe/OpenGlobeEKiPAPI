#!/bin/sh

set -e

app_name="ekip-staging"

timestamp="$(date +"%s")"
current_apps="$(cf apps)"

deploy()
{
	current_deployment=$1
	next_deployment=$2

	current_vars="$(cf env $current_deployment)"

	database_url="$(echo ${current_vars#*DATABASE_URL: } | awk '{print $1}')"

	echo "$current_deployment is currently deployed, pushing $next_deployment"
	cf push $next_deployment --no-start -n $app_name-$timestamp
	cf set-env $next_deployment DATABASE_URL $database_url
	cf push $next_deployment -n $app_name-$timestamp
	echo "Mapping $next_deployment to the Main Domain"
	cf map-route $next_deployment 18f.gov -n $app_name
	cf map-route $next_deployment cf.18f.us -n $app_name
	echo "Removing $current_deployment From the Main Domain"
	cf unmap-route $current_deployment 18f.gov -n $app_name
	cf unmap-route $current_deployment cf.18f.us -n $app_name
    cf delete $current_deployment -f
}

if [[ $current_apps == *"green"* ]]; then
	echo "Green Exists, Deploying Blue"
	deploy green blue
elif [[ $current_apps == *"blue"* ]]; then
	echo "Blue Exists, Deploying Green"
	deploy blue green
else
	echo "No existing blue or green app, please create one first!"
fi