
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
    @datetime = Time.zone.now
    @zip_filename = in_file.original_filename.sub(/.zip$/, "")
    @ss_files_map = {}
    @gws_users_map = {}
    @restored_folders = {}

    Zip.unicode_names = true
    Zip::File.open(in_file.path) do |entries|
      entries.each do |entry|
        next if !entry.name.end_with?(".eml")
        next if !entry.name.include?("/")

        import_gws_memo_message(entry)
      end
    end
  end

  private

  def import_gws_memo_message(entry)
    msg = read_eml(entry)
    return if msg.nil?

    item = Gws::Memo::Message.new

    item.site_id = cur_site.id
    item.subject = msg[:content].subject
    item.send_date = msg[:content].date
    if msg[:content].attachments.present?
      item.text = msg[:content].text_part.decoded
    else
      item.text = msg[:content].body.to_s.force_encoding("UTF-8")
    end

    if msg[:content].mime_type == "text/html"
      item.format = "html"
      item.html = msg[:content].decoded
    else
      item.format = "text"
    end

    sender = Gws::User.find_by(email: msg[:content].from.first) rescue nil
    # user_id (from)
    if sender
      item.cur_user = sender
      item.user_uid = sender.uid
      item.user_name = sender.name
      @sent_by_cur_user = (cur_user.id == sender.id)
    else
      item.cur_user = cur_user
    end

    # to_member_ids
    if msg[:content].to.present?
      item.to_member_ids = []
      msg[:content].to.each do |email|
        receiver = find_user(email)
        item.to_member_ids += [receiver.id] if receiver
        item.to_member_ids += [cur_user.id] unless receiver
      end
    end

    # cc_member_ids
    if msg[:content].cc.present?
      item.cc_member_ids = []
      msg[:content].cc.each do |email|
        receiver = find_user(email)
        item.cc_member_ids += [receiver.id] if receiver
      end
    end

    # bcc_member_ids
    if msg[:content].bcc.present?
      item.bcc_member_ids = []
      msg[:content].bcc.each do |email|
        receiver = find_user(email)
        item.bcc_member_ids += [receiver.id] if receiver
      end
    end

    item.member_ids = member_ids(item).sort

    # check member_ids
    unless item.draft?
      if item.to_member_ids.blank?
        item.to_member_ids = [cur_user.id]
      end
      if !member_ids(item).include?(cur_user.id)
        item.to_member_ids += [cur_user.id]
      end
    end

    # deleted
    item.deleted = {}
    unless item.draft?
      member_ids(item).each do |id|
        item.deleted[id.to_s] = @datetime if id != cur_user.id
      end
      item.deleted["sent"] = @datetime unless @sent_by_cur_user
    end

    # star
    item.star = {}

    # filterd
    item.filtered = {}
    item.filtered[cur_user.id.to_s] = @datetime

    # files
    item.file_ids = []
    if msg[:content].attachments.present?
      msg[:content].attachments.each do |data_file|
        item.file_ids += [save_ss_file(data_file).id]
      end
    end

    item.allow_other_user_files
    item.save

    # folder
    item.user_settings = []
    if msg[:folder_name].include?("受信トレイ")
      path = "INBOX"
    elsif msg[:folder_name].include?("送信済みトレイ")
      path = "INBOX.Sent"
    elsif msg[:folder_name].include?("下書き")
      path = "INBOX.Draft"
    elsif msg[:folder_name].include?("ゴミ箱")
      path = "INBOX.Trash"
    else
      restore_folder(msg[:folder_name])
      path = @restored_folders[msg[:folder_name]]
    end

    if path != "INBOX.Draft"
      item.move(cur_user, path).update
    else
      item.state = "closed"
      item.update
    end

    item
  end

  def restore_folder(folder_name)
    return if @restored_folders.has_key?(folder_name)

    folder = Gws::Memo::Folder.find_or_initialize_by(
      user_uid: cur_user.uid, user_name: cur_user.name,
      user_id: cur_user.id, site_id: @cur_site.id, name: folder_name
    )
    folder.save
    @restored_folders[folder_name] = folder.id.to_s
  end

  def find_user(email)
    user = Gws::User.find_by(email: email) rescue nil
    user
  end

  def member_ids(item)
    (item.to_member_ids + item.cc_member_ids + item.bcc_member_ids).uniq
  end

  def save_ss_file(data)
    file = Fs::UploadedFile.new('gws_message')
    file.binmode
    file.write(data.body)
    file.rewind
    file.original_filename = data.filename

    item = SS::File.new(model: "gws/memo/message")
    item.name = data.filename
    item.user_id = cur_user.id
    item.in_file = file
    item.save!

    item.in_file = nil
    item
  end

  def read_eml(entry)
    ext = File.extname(entry.name)
    file_path = URI.decode(entry.to_s).force_encoding('UTF-8')
    msg = {}
    Tempfile.open(file_path) do |file|
      structure = entry.name.force_encoding("UTF-8")
      msg[:tmp_path] = "tmp/#{File.basename(structure)}"
      if structure == "#{@zip_filename}/#{File.basename(structure)}"
        msg[:folder_name] = "no_name"
      elsif structure.start_with?(/.+#{@zip_filename}\//)
        # macで操作を行ったフォルダ構造の先頭に「__MACOS」が含まれるものと、含まれない２つのファイルが作成されて重複する
        return nil
      else
        msg[:folder_name] = structure.sub("#{@zip_filename}/", "").slice(/.*\//).tr("/", "")
      end
      entry.extract(msg[:tmp_path])
      msg[:content] = Mail.read(msg[:tmp_path])
      File.delete(msg[:tmp_path])
    end

    msg
  end
end
