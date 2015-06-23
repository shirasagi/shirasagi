namespace :ezine do
  task :deliver => :environment do
    page_id = ENV['page_id'] || 0
    Ezine::Task.deliver page_id
  end

  namespace :deliver do
    task :all => :environment do
      Ezine::Task.deliver_all
    end

    task :reserved => :environment do
      Ezine::Task.deliver_reserved
    end
  end
end
