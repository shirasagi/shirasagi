class Gws::Memo::MessageImporter
  include ActiveModel::Model
  include Sys::SiteImport::File

  attr_accessor :cur_site, :cur_user, :in_file

  def import_messages
    @datetime = Time.zone.now
    @import_dir = "#{Rails.root}/private/import/gws-memo-messages-#{@datetime.strftime('%Y%m%d%H%M%S')}"
    @ss_files_map = {}
    @gws_users_map = {}

    FileUtils.rm_rf(@import_dir)
    FileUtils.mkdir_p(@import_dir)

    Zip::File.open(in_file.path) do |entries|
      entries.each do |entry|
        path = "#{@import_dir}/" + entry.name.encode("utf-8", "cp932").tr('\\', '/')

        if entry.directory?
          FileUtils.mkdir_p(path)
        else
          File.binwrite(path, entry.get_input_stream.read)
        end
      end
    end

    names = Dir.glob("#{@import_dir}/*.json").each.map { |path| File.basename(path).sub(".json", "") }
    names.each do |name|
      import_gws_memo_message(name)
    end

    FileUtils.rm_rf(@import_dir)
  end

  def import_gws_memo_message(name)
    data = read_json(name)
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
    if item.draft?
      #
    else
      if item.to_member_ids.blank?
        item.to_member_ids = [@cur_user.id]
      end
      member_ids = (item.to_member_ids + item.cc_member_ids + item.bcc_member_ids).uniq
      if !member_ids.include?(@cur_user.id)
        item.to_member_ids += [@cur_user.id]
      end
    end

    # deleted
    item.deleted = {}
    if item.draft?
      #
    else
      member_ids = (item.to_member_ids + item.cc_member_ids + item.bcc_member_ids).uniq
      member_ids.each do |id|
        item.deleted[id.to_s] = @datetime if id != @cur_user.id
      end
      item.deleted["sent"] = @datetime unless @sent_by_cur_user
    end

    # star
    item.star = {}

    # filterd
    item.filtered = {}
    item.filtered[@cur_user.id.to_s] = @datetime

    # seen
    item.seen = {}
    #item.seen[@cur_user.id.to_s] = @datetime

    # path
    item.path = {}

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
    if user && user.name == name
      user
    else
      nil
    end
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

  def read_json(name)
    path = "#{@import_dir}/#{name}.json"
    return [] unless File.file?(path)
    file = File.read(path)
    JSON.parse(file)
  end

  class << self
    def t(*args)
      human_attribute_name(*args)
    end
  end
end
