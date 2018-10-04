.PHONY: help

# self-documented makefile, thanks to the Marmelab team
# see http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

DOCKER_PREFIX ?= hello
DOCKER_HTTP_PORT ?= 1234

docker-network-create: ## create the custom docker network
	docker network create -d bridge $(DOCKER_PREFIX)_net

docker-network-delete: ## delete the custom docker network
	docker network rm $(DOCKER_PREFIX)_net

docker-build-app: ## build the app container using docker
	docker build --rm --tag $(DOCKER_PREFIX)_app .

docker-run-blue: ## start running the app container as blue
	docker run --rm --detach --network=$(DOCKER_PREFIX)_net --network-alias=blue --name $(DOCKER_PREFIX)_app_blue $(DOCKER_PREFIX)_app

docker-stop-blue: ## stop the blue app container
	docker stop $(DOCKER_PREFIX)_app_blue

docker-logs-blue: ## display the logs from the blue app container
	docker logs $(DOCKER_PREFIX)_app_blue

docker-run-green: ## start running the app container as green
	docker run --rm --detach --network=$(DOCKER_PREFIX)_net --network-alias=green --name $(DOCKER_PREFIX)_app_green $(DOCKER_PREFIX)_app

docker-stop-green: ## stop the green app container
	docker stop $(DOCKER_PREFIX)_app_green

docker-logs-green: ## display the logs from the green app container
	docker logs $(DOCKER_PREFIX)_app_green

docker-build-nginx: ## build the nginx container using docker
	docker build --rm --tag $(DOCKER_PREFIX)_nginx ./docker/nginx

docker-run-nginx: ## start running the nginx container
	docker run --rm  --network=$(DOCKER_PREFIX)_net --network-alias=nginx --publish $(DOCKER_HTTP_PORT):80 --detach --name $(DOCKER_PREFIX)_nginx_1 $(DOCKER_PREFIX)_nginx

docker-stop-nginx: ## stop the nginx container
	docker stop $(DOCKER_PREFIX)_nginx_1

docker-logs-nginx: ## display the logs from the nginx container
	docker logs $(DOCKER_PREFIX)_nginx_1

docker-build: docker-build-app docker-build-nginx ## build all the containers

docker-blue2green:
	docker exec $(DOCKER_PREFIX)_nginx_1 sed -i -e 's/blue/green/' /etc/nginx/nginx.conf
	docker kill -s HUP $(DOCKER_PREFIX)_nginx_1

docker-green2blue:
	docker exec $(DOCKER_PREFIX)_nginx_1 sed -i -e 's/green/blue/' /etc/nginx/nginx.conf
	docker kill -s HUP $(DOCKER_PREFIX)_nginx_1
