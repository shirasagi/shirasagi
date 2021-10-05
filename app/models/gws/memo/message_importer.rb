
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
    @ss_files_map = {}
    @gws_users_map = {}

    Zip.unicode_names = true
    Zip::File.open(in_file.path) do |entries|
      entries.each do |entry|
        next if !entry.name.end_with?(".eml")

        import_gws_memo_message(entry)
      end
    end
  end

  private

  def import_gws_memo_message(entry)
    msg = read_eml(entry)

    item = Gws::Memo::Message.new
    item.site_id = cur_site.id
    item.subject = msg[:content].subject
    item.send_date = msg[:content].date
    if msg[:content].attachments.present?
      item.text = msg[:content].text_part.decoded
    else
      item.text = msg[:content].decoded
    end

    sender = Gws::User.find_by(email: msg[:content].from.first) rescue nil
    item.user_uid = sender.uid
    item.user_name = sender.name
    # user_id (from)
    if sender
      item.cur_user = sender
      @sent_by_cur_user = (@cur_user.id == sender.id)
    else
      item.cur_user = @cur_user
    end

    # to_member_ids
    if msg[:content].to.present?
      item.to_member_ids = []
      msg[:content].to.each do |email|
        receiver = find_user(email)
        item.to_member_ids += [receiver.id] if receiver
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
        item.to_member_ids = [@cur_user.id]
      end
      if !member_ids(item).include?(@cur_user.id)
        item.to_member_ids += [@cur_user.id]
      end
    end

    #trash
    item.user_settings = []
    if msg[:tmp_path].include?("受信トレイ")
      item.user_settings << { "user_id" => @cur_user.id, "path" => "INBOX" }
    elsif msg[:tmp_path].include?("ゴミ箱")
      item.user_settings << { "user_id" => @cur_user.id, "path" => "INBOX.Trash" }
    end

    # deleted
    item.deleted = {}
    unless item.draft?
      member_ids(item).each do |id|
        item.deleted[id.to_s] = @datetime if id != @cur_user.id
      end
      item.deleted["sent"] = @datetime unless @sent_by_cur_user
    end

    # star
    item.star = {}

    # filterd
    item.filtered = {}
    item.filtered[@cur_user.id.to_s] = @datetime

    # files
    item.file_ids = []
    if msg[:content].attachments.present?
      msg[:content].attachments.each do |data_file|
        item.file_ids += [save_ss_file(data_file).id]
      end
    end

    item.allow_other_user_files
    item.save
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
    item.user_id = @cur_user.id
    item.in_file = file
    item.save!

    item.in_file = nil
    item
  end

  def read_eml(entry)
    ext = File.extname(entry.name)
    msg = {}
    Tempfile.open(URI.decode(entry.to_s).force_encoding('UTF-8')) do |file|
      msg[:tmp_path] = "tmp/" + File.basename(file)
      entry.extract(msg[:tmp_path])
      msg[:content] = Mail.read("tmp/" + File.basename(file.path))
      File.delete(msg[:tmp_path])
    end

    msg
  end
end
