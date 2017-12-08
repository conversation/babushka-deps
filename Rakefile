require 'islington'
require 'rubocop/rake_task'

task default: 'spec:rubocop'

namespace :spec do
  desc "Run rubocop quality checks"
  RuboCop::RakeTask.new(:rubocop) do |task|
    task.patterns = ['**/*.rb']
    task.formatters = ['progress']
    task.fail_on_error = true
    task.options = ["--config", Islington::Config.rubocop_config]
  end
end
