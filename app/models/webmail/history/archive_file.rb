class Webmail::History::ArchiveFile
  include SS::Model::File
  include Webmail::Permission
  include Cms::Lgwan::File

  set_permission_name 'webmail_histories'

  default_scope ->{ where(model: 'webmail/history/archive_file') }

  def previewable?(site: nil, user: nil, member: nil)
    if user
      Webmail::History::ArchiveFile.allowed?(:read, user)
    end
  end
end
