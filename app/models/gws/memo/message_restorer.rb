class Gws::Memo::MessageRestorer
  include ActiveModel::Model
  include Sys::SiteImport::File

  attr_accessor :cur_site, :cur_user, :in_file

  class << self
    def t(*args)
      human_attribute_name(*args)
    end
  end

  def restore_messages
    @datetime = Time.zone.now
    @ss_files_map = {}
    @gws_users_map = {}

    Zip::File.open(in_file.path) do |entries|
      entries.each do |entry|
        next if entry.directory?

        restore_gws_memo_message(entry)
      end
    end
  end

  private

  def restore_gws_memo_message(entry)
    data = read_json(entry)
    data.delete('_id')

    item = init_message(data)

    if data['user']
      item.set_cur_user(data['user'])
    end

    if data['to_members'].present?
      item.set_to_members(data['to_members'])
    end

    if data['cc_members'].present?
      item.set_cc_member_ids(data['cc_members'])
    end

    if data['bcc_members'].present?
      item.set_bcc_member_ids(data['bcc_members'])
    end

    unless item.draft?
      item.set_to_member_ids_if_blank
    end

    unless item.draft?
      item.set_deleted
    end

    item.filtered[@cur_user.id.to_s] = @datetime

    if data['files'].present?
      data['files'].each do |data_file|
        item.file_ids += [save_ss_file(data_file).id]
      end
    end

    item.allow_other_user_files
    item.save
  end

  def init_message(data)
    item = Gws::Memo::Message.new
    data.each do |k, v|
      next if %w(user members to_members cc_members bcc_members files list_id).include?(k)

      item[k] = v
    end

    item.site_id = cur_site.id
    item.set_blank_val

    item
  end

  def find_user(data)
    id = data['_id']
    name = data['name']

    return nil if id.nil? || name.nil?

    user = Gws::User.unscoped.find(id) rescue nil

    return nil if user.try(:name) != name

    user
  end

  def member_ids(item)
    (item.to_member_ids + item.cc_member_ids + item.bcc_member_ids).uniq
  end

  def save_ss_file(data)
    file = Fs::UploadedFile.new('gws_message')
    file.binmode
    file.write(Base64.strict_decode64(data['base64']))
    file.rewind
    file.original_filename = data['filename']

    item = SS::File.new(model: data['model'])
    item.name = data['name']
    item.user_id = @cur_user.id
    item.in_file = file
    item.save!

    item.in_file = nil
    item
  end

  def read_json(entry)
    entry.get_input_stream do |f|
      # JSON文字列ではなく、オブジェクトを読み込むからJSON.loadを使う
      JSON.load(f)
    end
  end
end
