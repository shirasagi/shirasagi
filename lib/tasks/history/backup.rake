namespace :history do
  namespace :backup do
    task sweep: :environment do
      ::Tasks::History.sweep_backup
    end
  end
end
