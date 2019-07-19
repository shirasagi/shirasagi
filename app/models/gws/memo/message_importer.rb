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

    Zip::File.open(in_file.path) do |entries|
      entries.each do |entry|
        next if entry.directory?

        import_gws_memo_message(entry)
      end
    end
  end

  private

  def import_gws_memo_message(entry)
    data = read_json(entry)
    data.delete('_id')

    item = Gws::Memo::Message.new
    data.each do |k, v|
      next if %w(user members to_members cc_members bcc_members files list_id).include?(k)

      item[k] = v
    end

    # site_id
    item.site_id = cur_site.id

    # user_id (from)
    if data['user']
      user = find_user(data['user'])
      if user
        item.cur_user = user
        @sent_by_cur_user = (@cur_user.id == user.id)
      else
        item.cur_user = @cur_user
      end
    end

    # to_member_ids
    if data['to_members'].present?
      item.to_member_ids = []
      data['to_members'].each do |data_user|
        user = find_user(data_user)
        item.to_member_ids += [user.id] if user
      end
    end

    # cc_member_ids
    if data['cc_members'].present?
      item.cc_member_ids = []
      data['cc_members'].each do |data_user|
        user = find_user(data_user)
        item.cc_member_ids += [user.id] if user
      end
    end

    # bcc_member_ids
    if data['bcc_members'].present?
      item.bcc_member_ids = []
      data['bcc_members'].each do |data_user|
        user = find_user(data_user)
        item.bcc_member_ids += [user.id] if user
      end
    end

    # check member_ids
    unless item.draft?
      if item.to_member_ids.blank?
        item.to_member_ids = [@cur_user.id]
      end
      if !member_ids(item).include?(@cur_user.id)
        item.to_member_ids += [@cur_user.id]
      end
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

    # user_settings
    item.user_settings = []

    # files
    item.file_ids = []
    if data['files'].present?
      data['files'].each do |data_file|
        item.file_ids += [save_ss_file(data_file).id]
      end
    end

    item.allow_other_user_files
    item.save
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
      JSON.load(f)
    end
  end
end
