# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative "config/application"

Rails.application.load_tasks

# Load ActiveGraph migration tasks
begin
  require "active_graph/tasks/migration"
rescue LoadError
  # ActiveGraph tasks not available
end
