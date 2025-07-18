# Docker Development Setup

This project includes a complete Docker setup for development and testing.

## Quick Start

1. Copy the Docker environment file:
   ```bash
   cp .env.docker .env
   ```

2. Start all services:
   ```bash
   bin/docker-dev up
   ```

3. The application will be available at:
   - Rails app: http://localhost:3000
   - Neo4j browser: http://localhost:7474 (username: neo4j, password: password)

## Services

The docker-compose setup includes:
- **web**: Rails application server
- **postgres**: PostgreSQL database
- **redis**: Redis for caching and Sidekiq
- **neo4j**: Neo4j graph database
- **sidekiq**: Background job processor
- **test**: Dedicated container for running tests

## Common Commands

```bash
# Start services
bin/docker-dev up

# Stop services
bin/docker-dev down

# View logs
bin/docker-dev logs
bin/docker-dev logs web      # specific service

# Rails console
bin/docker-dev console

# Run tests
bin/docker-dev test
bin/docker-dev test spec/models/organization_spec.rb

# Run migrations
bin/docker-dev migrate

# Reset database
bin/docker-dev reset

# Open bash shell
bin/docker-dev bash
bin/docker-dev bash postgres  # specific service

# Rails commands
bin/docker-dev rails generate model Foo
bin/docker-dev rails db:seed

# Bundle commands
bin/docker-dev bundle add some-gem
bin/docker-dev bundle update
```

## Direct Docker Compose Commands

You can also use docker-compose directly:

```bash
# Run any command in a service
docker-compose exec web bundle exec rspec
docker-compose exec web rails generate controller Home

# One-off commands
docker-compose run --rm web rails db:create
docker-compose run --rm web bundle install
```

## Troubleshooting

### Database Connection Issues
If you get database connection errors, ensure the postgres service is healthy:
```bash
docker-compose ps
docker-compose logs postgres
```

### Rebuilding
If you change the Gemfile or package.json:
```bash
bin/docker-dev build
bin/docker-dev up
```

### Clean Start
For a completely fresh start:
```bash
docker-compose down -v  # Remove volumes
bin/docker-dev build
bin/docker-dev up
bin/docker-dev reset   # Reset databases
```

## Production Build

The main `Dockerfile` is optimized for production. To build and test it:
```bash
docker build -t dewey .
docker run -p 3000:80 -e RAILS_MASTER_KEY=<your-key> dewey
```