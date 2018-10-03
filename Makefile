.PHONY: help

# self-documented makefile, thanks to the Marmelab team
# see http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

DOCKER_PREFIX ?= hello
DOCKER_HTTP_PORT ?= 1234

docker-build-app: ## build the app container using docker
	docker build --rm --tag $(DOCKER_PREFIX)_app .

docker-run-app: ## start running the app container
	docker run --rm --detach --name $(DOCKER_PREFIX)_app_1 $(DOCKER_PREFIX)_app

docker-stop-app: ## stop the app container
	docker stop $(DOCKER_PREFIX)_app_1

docker-logs-app: ## display the logs from the app container
	docker logs $(DOCKER_PREFIX)_app_1

docker-build-nginx: ## build the nginx container using docker
	docker build --rm --tag $(DOCKER_PREFIX)_nginx ./docker/nginx

docker-run-nginx: ## start running the nginx container
	docker run --rm --link $(DOCKER_PREFIX)_app_1:app --publish $(DOCKER_HTTP_PORT):80 --detach --name $(DOCKER_PREFIX)_nginx_1 $(DOCKER_PREFIX)_nginx

docker-stop-nginx: ## stop the nginx container
	docker stop $(DOCKER_PREFIX)_nginx_1

docker-logs-nginx: ## display the logs from the nginx container
	docker logs $(DOCKER_PREFIX)_nginx_1

docker-build: docker-build-app docker-build-nginx ## build all the containers
docker-run: docker-run-app docker-run-nginx ## run all the containers
docker-stop: docker-stop-app docker-stop-nginx ## stop all the containers
