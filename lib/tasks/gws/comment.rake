namespace :gws do
  namespace :comment do
    desc 'set viewing authority on circular comments task'
    task set_authority: :environment do
      ::Tasks::Gws::Comment.set_authority
    end
  end
end
