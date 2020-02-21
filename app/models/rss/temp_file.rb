class Rss::TempFile
  include SS::Model::File
  include SS::UserPermission

  store_in_repl_master
  default_scope ->{ where(model: 'rss/temp_file') }

  class << self
    def create_from_post(site, payload, content_type)
      create_empty!(site_id: site.id, name: 'rss', filename: 'rss', content_type: content_type, state: 'closed') do |file|
        ::File.binwrite(file.path, payload)
      end
    end
  end
end
