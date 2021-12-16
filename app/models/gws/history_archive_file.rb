class Gws::HistoryArchiveFile
  include Gws::Model::File
  include Gws::Referenceable
  include Gws::Reference::Site
  include Gws::SitePermission

  set_permission_name 'gws_histories'

  default_scope ->{ where(model: 'gws/history_archive_file') }

  def previewable?(site: nil, user: nil, member: nil)
    if user
      Gws::History.allowed?(:read, user, site: self.site)
    end
  end
end
