# Load ActiveGraph migration tasks
begin
  require 'active_graph'
  load File.join(Gem::Specification.find_by_name('activegraph').gem_dir, 'lib', 'active_graph', 'tasks', 'migration.rake')
rescue LoadError => e
  puts "ActiveGraph migration tasks not available: #{e.message}"
end