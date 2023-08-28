class Gws::Memo::MessageImporter
  include ActiveModel::Model
  include Sys::SiteImport::File

  attr_accessor :cur_site, :cur_user, :in_file

  class << self
    def t(*args)
      human_attribute_name(*args)
    end
  end

  def import_messages
    I18n.with_locale(I18n.default_locale) do
      _import_messages
    end
  end

  private

  def _import_messages
    @datetime = Time.zone.now
    @zip_filename = File.basename(in_file.original_filename, ".zip")
    @ss_files_map = {}
    @gws_users_map = {}
    @restored_folders = {}

    Zip::File.open(in_file.path) do |entries|
      entries.each do |entry|
        next if entry.directory? || entry.name.blank?

        normalized = NKF.nkf("-Ww", entry.name)
        next if normalized.blank? || !normalized.end_with?(".eml")

        basename = File.basename(normalized)
        next if basename.present? && basename.start_with?(".", "_")

        Rails.logger.tagged(normalized) do
          path = ensure_to_have_folder(entry)
          Gws::Memo::Message.create_from_eml(cur_user, path, entry.get_input_stream, site: cur_site)
        rescue => e
          Rails.logger.warn { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
        end
      end
    end
  end

  # rubocop:disable Lint/DuplicateBranch
  def ensure_to_have_folder(entry)
    folder_name = get_folder_name(entry.name)
    case folder_name
    when I18n.t('gws/memo/folder.inbox')
      "INBOX"
    when I18n.t('gws/memo/folder.inbox_sent'), I18n.t('gws/memo/folder.inbox_draft'), I18n.t('gws/memo/folder.inbox_trash')
      # システムフォルダー下へはインポートできないので、受信トレイにリダイレクト
      "INBOX"
    else
      restore_folder(folder_name)
      @restored_folders[folder_name]
    end
  end
  # rubocop:enable Lint/DuplicateBranch

  def get_folder_name(entry_name)
    normalized = NKF.nkf("-Ww", entry_name)
    separator_count = normalized.count("/")
    case separator_count
    when 0
      folder_name = nil
    else
      folder_name = ::File.dirname(normalized)
    end
    folder_name = "no_name" if folder_name.blank? || folder_name == "."

    folder_name
  end

  def restore_folder(folder_name)
    return if @restored_folders.key?(folder_name)

    folder = Gws::Memo::Folder.find_or_initialize_by(
      user_uid: cur_user.uid, user_name: cur_user.name,
      user_id: cur_user.id, site_id: @cur_site.id, name: folder_name
    )
    if !folder.save
      structure = []
      folder_name.split("/").each do |parent_name|
        next if parent_name == File.basename(folder_name)

        structure << parent_name
        parent_folder = Gws::Memo::Folder.find_or_initialize_by(
          user_uid: cur_user.uid, user_name: cur_user.name,
          user_id: cur_user.id, site_id: @cur_site.id, name: structure.join("/")
        )
        parent_folder.save
      end
    end
    folder.save
    @restored_folders[folder_name] = folder.id.to_s
  end
end
