NAME        = inception
SRCS_DIR    = ./srcs
DATA_PATH   = $(HOME)/data
COMPOSE     = docker-compose -f $(SRCS_DIR)/docker-compose.yml

all: setup
	$(COMPOSE) up -d --build

# Up/Down (persistence)
up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

setup:
	@sudo mkdir -p $(DATA_PATH)/mariadb
	@sudo mkdir -p $(DATA_PATH)/wordpress

clean:
	$(COMPOSE) down --rmi all --remove-orphans

fclean: clean
	@$(COMPOSE) down -v
	@sudo rm -rf $(DATA_PATH)
	@docker system prune -a -f

re: fclean all

.PHONY: all up down setup clean fclean re
