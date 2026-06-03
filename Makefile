# Variables
USER    =   $(shell whoami)
export LOGIN := $(USER)
DATA_PATH   =   /home/$(USER)/data

#Commands
COMPOSE     = docker compose -f srcs/docker-compose.yml --env-file srcs/.env
BUILDKIT = DOCKER_BUILDKIT=1 COMPOSE_DOCKER_CLI_BUILD=1
.RECIPEPREFIX := >

#Targets
all: up 

build:
>@if [ ! -f srcs/.env ]; then cp .env.example srcs/.env; echo "Created srcs/.env from example"; fi
>@mkdir -p secrets
>@for s in db_root_password db_password wp_admin_password wp_user_password; do \
>    if [ ! -f secrets/$$s.txt ]; then \
>        cp secrets/$$s.txt.example secrets/$$s.txt; \
>        echo "WARNING: secrets/$$s.txt created from example – replace with a real password!"; \
>    fi \
>done
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
>@[ -f srcs/.env ] || cp .env.example srcs/.env
>$(COMPOSE) down --rmi all --remove-orphans

fclean: clean
>$(COMPOSE) down -v
>sudo rm -rf $(DATA_PATH)
>@rm -f srcs/.env
>docker system prune -a -f

re: fclean all

.PHONY:all build up down logs ps images clean fclean re