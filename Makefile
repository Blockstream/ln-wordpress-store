clean:
	docker-compose down -v

setup:
	docker-compose up -d

  # Allow the DB to be ready
	sleep 3

	# Install wordpress
	docker-compose exec wp-cli sh -c 'wp config create --dbname=wordpress --dbuser=root --dbpass=my-secret-pw --dbhost=mysql --force'

	# Stop wordpress-cli
	docker-compose stop wp-cli

.PHONY: setup cleanup
