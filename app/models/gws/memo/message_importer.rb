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
    @zip_filename = File.basename(in_file.original_filename, ".zip")
    @ss_files_map = {}
    @gws_users_map = {}
    @restored_folders = {}

    Zip.unicode_names = true
    Zip::File.open(in_file.path) do |entries|
      entries.each do |entry|
        next if entry.directory?
        next if !entry.name.end_with?(".eml")
        next if File.basename(entry.name).start_with?(".", "_")

        import_gws_memo_message(entry)
      end
    end
  end

  private

  def import_gws_memo_message(entry)
    msg = Mail.new(entry.get_input_stream.read)
    item = Gws::Memo::Message.new

    item.site_id = cur_site.id
    item.subject = msg.subject
    item.send_date = msg.date
    if msg.attachments.present?
      item.text = NKF.nkf("-Ww", msg.text_part.decoded)
    else
      item.text = NKF.nkf("-Ww", msg.body.to_s)
    end

    if msg.mime_type == "text/html"
      item.format = "html"
      item.html = msg.decoded
    else
      item.format = "text"
    end

    sender = Gws::User.find_by(email: msg.from.first) rescue nil
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
    item = import_to_members(msg, item) if msg.to.present?

    # cc_member_ids
    item = import_cc_members(msg, item) if msg.cc.present?

    # bcc_member_ids
    item = import_bcc_members(msg, item) if msg.bcc.present?

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
    if msg.attachments.present?
      msg.attachments.each do |data_file|
        item.file_ids += [save_ss_file(data_file).id]
      end
    end

    item.allow_other_user_files
    item.save

    # folder
    item.user_settings = []
    folder_name = get_folder_name(entry.name)
    case folder_name
    when I18n.t('gws/memo/folder.inbox')
      path = "INBOX"
    when I18n.t('gws/memo/folder.inbox_sent')
      path = "INBOX.Sent"
    when I18n.t('gws/memo/folder.inbox_draft')
      path = "INBOX.Draft"
    when I18n.t('gws/memo/folder.inbox_trash')
      path = "INBOX.Trash"
    else
      restore_folder(folder_name)
      path = @restored_folders[folder_name]
    end

    if path != "INBOX.Draft"
      item.move(cur_user, path).update
    else
      item.state = "closed"
      item.update
    end

    item
  end

  def import_to_members(msg, item)
    to_member_ids = []
    item.to_member_ids = []
    to_webmail_address_group_ids = []
    to_shared_address_group_ids = []
    msg.header["X-Shirasagi-Member-IDs"].value.split(",").each do |id|
      receiver = find_user(id.to_i)
      to_member_ids << receiver.id if receiver
    end
    item.to_member_ids = to_member_ids if to_member_ids.present?

    to_webmail_address_group_ids = []
    to_shared_address_group_ids = []
    msg.to.each do |address|
      webmail_address_group = find_webmail_address_group(address)
      to_webmail_address_group_ids << webmail_address_group.id if webmail_address_group

      shared_address_group = find_shared_address_group(address)
      to_shared_address_group_ids << shared_address_group.id if shared_address_group
    end
    item.to_webmail_address_group_ids = to_webmail_address_group_ids
    item.to_shared_address_group_ids = to_shared_address_group_ids

    item.to_member_ids += [cur_user.id] if item.to_member_ids.blank?

    item
  end

  def import_cc_members(msg, item)
    item.cc_member_ids = []
    msg.header["Cc-IDs"].value.split(",").each do |id|
      receiver = find_user(id.to_i)
      item.cc_member_ids += [receiver.id] if receiver
    end

    cc_webmail_address_group_ids = []
    cc_shared_address_group_ids = []
    msg.cc.each do |address|
      webmail_address_group = find_webmail_address_group(address)
      cc_webmail_address_group_ids << webmail_address_group.id if webmail_address_group

      shared_address_group = find_shared_address_group(address)
      cc_shared_address_group_ids << shared_address_group.id if shared_address_group
    end
    item.cc_webmail_address_group_ids = cc_webmail_address_group_ids
    item.cc_shared_address_group_ids = cc_shared_address_group_ids

    item
  end

  def import_bcc_members(msg, item)
    item.bcc_member_ids = []
    msg.header["Bcc-IDs"].value.split(",").each do |id|
      receiver = find_user(id.to_i)
      item.bcc_member_ids += [receiver.id] if receiver
    end

    bcc_webmail_address_group_ids = []
    bcc_shared_address_group_ids = []
    msg.bbc.each do |address|
      webmail_address_group = find_webmail_address_group(address)
      bcc_webmail_address_group_ids << webmail_address_group.id if webmail_address_group

      shared_address_group = find_shared_address_group(address)
      bcc_shared_address_group_ids << shared_address_group.id if shared_address_group
    end
    item.bcc_webmail_address_group_ids = bcc_webmail_address_group_ids
    item.bcc_shared_address_group_ids = bcc_shared_address_group_ids

    item
  end

  def get_folder_name(entry_name)
    structure = NKF.nkf("-Ww", entry_name)
    if structure.count("/") == 1
      folder_name = ::File.dirname(structure).sub(@zip_filename, "")
    else
      folder_name = ::File.dirname(structure).sub("#{@zip_filename}/", "")
    end
    folder_name = "no_name" if folder_name.blank?

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

  def find_user(id)
    Gws::User.site(@cur_site).find(id) rescue nil
  end

  def find_webmail_address_group(name)
    Webmail::AddressGroup.find_by(name: name) rescue nil
  end

  def find_shared_address_group(name)
    Gws::SharedAddress::Group.find_by(name: name) rescue nil
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
end
