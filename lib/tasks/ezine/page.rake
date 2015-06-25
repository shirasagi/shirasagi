namespace :ezine do
  task :deliver => :environment do
    page_id = ENV['page_id']
    if page_id
      Ezine::Task.deliver page_id
    else
      Ezine::Task.deliver_reserved
    end
  end
end
