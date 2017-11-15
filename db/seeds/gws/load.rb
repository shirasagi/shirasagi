# --------------------------------------
# Require

if ENV['group'].present?
  load "#{Rails.root}/db/seeds/ss/users.rb"
  load "#{Rails.root}/db/seeds/gws/contents.rb"
else
  %w(シラサギ市 クロサギ市 アオサギ市).each do |site_name|
    ENV['group'] = site_name
    load "#{Rails.root}/db/seeds/ss/users.rb"
    load "#{Rails.root}/db/seeds/gws/contents.rb"
  end
end
