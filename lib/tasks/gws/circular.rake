namespace :gws do
  namespace :circular do
    desc 'circular deletion task'
    task deletion: :environment do
      ::Tasks::Gws::Circular.deletion
    end
  end
end
