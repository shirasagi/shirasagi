# Load local Guardfile
# ref. https://github.com/openmensa/openmensa/blob/ac3b063edfd3639091d2b4025a292feea7814ec9/Guardfile#L34-L38
local_guardfile_path = File.expand_path('../Guardfile.local', __FILE__)
if File.exist? local_guardfile_path
  self.instance_eval(File.open(local_guardfile_path).read)
else
  if ENV["GUARD_RSPEC"]
    guard :rspec, cmd: 'bundle exec rspec', all_on_start: false do
      watch(%r{^spec/.+_spec\.rb$})
      watch(%r{^lib/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }
      watch('spec/spec_helper.rb')  { "spec" }

      # Rails example
      watch(%r{^app/(.+)\.rb$})                           { |m| "spec/#{m[1]}_spec.rb" }
      watch(%r{^app/(.*)(\.erb|\.haml|\.slim)$})          { |m| "spec/#{m[1]}#{m[2]}_spec.rb" }
      watch(%r{^app/controllers/(.+)_(controller)\.rb$})  { |m| ["spec/routing/#{m[1]}_routing_spec.rb", "spec/#{m[2]}s/#{m[1]}_#{m[2]}_spec.rb", "spec/acceptance/#{m[1]}_spec.rb"] }
      watch(%r{^spec/support/(.+)\.rb$})                  { "spec" }
      watch('config/routes.rb')                           { "spec/routing" }
      watch('app/controllers/application_controller.rb')  { "spec/controllers" }
      watch('spec/rails_helper.rb')                       { "spec" }

      # Capybara features specs
      watch(%r{^app/views/(.+)/.*\.(erb|haml|slim)$})     { |m| "spec/features/#{m[1]}_spec.rb" }

      # Turnip features and steps
      watch(%r{^spec/acceptance/(.+)\.feature$})
      watch(%r{^spec/acceptance/steps/(.+)_steps\.rb$})   { |m| Dir[File.join("**/#{m[1]}.feature")][0] || 'spec/acceptance' }
    end
  end

  if ENV["GUARD_RUBOCOP"]
    guard :rubocop, all_on_start: false do
      watch(%r{^app/(.+)\.rb$})
      watch(%r{^config/(.+)\.rb$})
      watch(%r{^db/(.+)\.rb$})
      watch(%r{^lib/(.+)\.rb$})
      watch(%r{^spec/(.+)\.rb$})
      watch('Gemfile')
    end
  end

  if ENV["GUARD_BRAKEMAN"]
    guard 'brakeman', all_on_start: false do
      watch(%r{^app/.+\.(erb|haml|rhtml|rb)$})
      watch(%r{^config/.+\.rb$})
      watch(%r{^db/(.+)\.rb$})
      watch(%r{^lib/.+\.rb$})
      watch('Gemfile')
    end
  end

  if ENV["GUARD_SCSS_LINT"]
    guard :scss_lint, all_on_start: false do
      watch(%r{^app/assets/stylesheets/(.+)\.s?css$})
      watch(%r{^spec/fixtures/(.+)\.s?css$})
      watch(%r{^db/seeds/(.+)\.s?css$})
    end
  end

  if ENV["GUARD_STYLELINT"]
    require_relative "./lib/guard/stylelint"
    guard :stylelint, all_on_start: false do
      watch(%r{^app/assets/stylesheets/(.+)\.s?css$})
      watch(%r{^app/javascript/(.+)\.s?css$})
      watch(%r{^spec/fixtures/(.+)\.s?css$})
      watch(%r{^db/seeds/(.+)\.s?css$})
    end
  end

  if ENV["GUARD_ESLINT"]
    require_relative "./lib/guard/eslint"
    guard :eslint, all_on_start: false do
      watch(%r{^app/assets/(.+)\.(js|js\.erb)$})
      watch(%r{^app/javascript/(.+)\.js$})
      watch(%r{^db/seeds/(.+)\.(js|js\.erb)$})
    end
  end
end
