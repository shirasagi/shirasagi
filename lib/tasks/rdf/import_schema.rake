namespace :rdf do
  task :import_schema => :environment do
    break if ENV["site"].blank?
    break if ENV["prefix"].blank?
    break if ENV["file"].blank?
    Rdf::VocabImportJob.bind(site_id: ENV["site"]).
      perform_now(ENV["prefix"], ENV["file"], ENV["owner"] || Rdf::Vocab::OWNER_SYSTEM, ENV["order"])
  end

  task :delete_schema => :environment do
    break if ENV["site"].blank?
    break if ENV["prefix"].blank?
    Rdf::Vocab.site(SS::Site.find_by(host: ENV["site"])).find_by(prefix: ENV["prefix"]).delete
  end
end
