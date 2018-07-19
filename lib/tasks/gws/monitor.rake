namespace :gws do
  namespace :monitor do
    desc "deletion task"

    task deletion: :environment do
      ::Tasks::Gws::Monitor.deletion
    end
  end
end
