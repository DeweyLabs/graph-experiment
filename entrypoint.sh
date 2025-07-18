#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -f /rails/tmp/pids/server.pid

# Create and migrate databases if they don't exist
if ! PGPASSWORD=$DATABASE_PASSWORD psql -h $DATABASE_HOST -U $DATABASE_USERNAME -lqt | cut -d \| -f 1 | grep -qw dewey_${RAILS_ENV}; then
  echo "Database does not exist. Creating..."
  bundle exec rails db:create
fi

# Run migrations
bundle exec rails db:migrate

# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"