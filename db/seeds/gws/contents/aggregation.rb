require 'rake'
Rails.application.load_tasks
ENV["site"]=@site.name
Rake::Task['gws:aggregation:group:update'].invoke
