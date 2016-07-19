class Rss::TempFile
  include SS::Model::File
  include SS::UserPermission

  default_scope ->{ where(model: 'rss/temp_file') }

  class << self
    public
      def create_from_post(site, payload, content_type)
        file = ::Fs::UploadedFile.new('rss')
        file.binmode
        file.write(payload)
        file.rewind
        file.original_filename = ::File.basename(file)
        file.content_type = content_type

        item = new
        item.site_id = site.id
        item.in_file = file
        item.filename = File.basename(file.path)
        item.state = 'closed'
        item.save

        file.delete

        item
      end
  end
end
