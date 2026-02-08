SRCS_DIR    = ./srcs
DATA_PATH   = $(HOME)/data
COMPOSE     = docker-compose -f $(SRCS_DIR)/docker-compose.yml

all: setup
	$(COMPOSE) up -d --build

up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

setup:
	@mkdir -p $(DATA_PATH)/mariadb $(DATA_PATH)/wordpress

clean:
	$(COMPOSE) down --rmi all --remove-orphans

fclean:
	$(COMPOSE) down -v --rmi all --remove-orphans
	rm -rf $(DATA_PATH)

re: fclean all

.PHONY: all up down setup clean fclean re
