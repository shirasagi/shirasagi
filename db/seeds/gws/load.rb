# --------------------------------------
# Require

%w(シラサギ市 クロサギ市 アオサギ市).each do |site_name|
  SS::Db::Seed.site_name = site_name
  load "#{Rails.root}/db/seeds/ss/users.rb"
  load "#{Rails.root}/db/seeds/gws/contents.rb"
end
