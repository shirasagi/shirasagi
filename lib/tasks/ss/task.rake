namespace :ss do
  namespace :task do
    task sweep: :environment do
      puts "delete tasks"
      SS::TaskSweepJob.perform_now
    end
  end
end
