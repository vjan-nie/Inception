# Variables
USER	=	$(shell whoami)
DATA_PATH	=	/home/$(USER)/data

#Commands
COMPOSE     = docker compose -f srcs/docker-compose.yml --env-file srcs/.env
BUILDKIT = DOCKER_BUILDKIT=1 COMPOSE_DOCKER_CLI_BUILD=1
.RECIPEPREFIX := >

#Targets
all: build 

build:
>@mkdir -p $(DATA_PATH)/mariadb $(DATA_PATH)/wordpress
>$(BUILDKIT) $(COMPOSE) build --parallel

up: build
>$(COMPOSE) up -d

down:
>$(COMPOSE) down

logs:
>$(COMPOSE) logs -f

ps:
>$(COMPOSE) ps

images:
>$(COMPOSE) images

clean:
>$(COMPOSE) down --rmi all --remove-orphans

fclean: clean
>$(COMPOSE) down -v
>sudo rm -rf $(DATA_PATH)
>docker system prune -a -f

re: fclean all

.PHONY:all  build up down logs ps images clean fclean re
