namespace :recommend do
  task :create_matrix => :environment do
    Recommend::CreateMatrixJob.perform_now(ENV["days"])
  end
end
