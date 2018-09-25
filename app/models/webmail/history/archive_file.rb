class Webmail::History::ArchiveFile
  include SS::Model::File
  include Webmail::Permission

  set_permission_name 'webmail_histories'

  default_scope ->{ where(model: 'webmail/history/archive_file') }
end
