namespace :rdf do
  task :import_schema => :environment do
    break if ENV["site"].blank?
    break if ENV["prefix"].blank?
    break if ENV["file"].blank?
    Rdf::VocabImportJob.new.call(ENV["site"], ENV["prefix"], ENV["file"], ENV["owner"] || Rdf::Vocab::OWNER_SYSTEM, ENV["order"])
  end

  task :delete_schema => :environment do
    break if ENV["site"].blank?
    break if ENV["uri"].blank?
    Rdf::Vocab.site(SS::Site.find_by(host: ENV["site"])).find_by(uri: ENV["uri"]).delete
  end
end
