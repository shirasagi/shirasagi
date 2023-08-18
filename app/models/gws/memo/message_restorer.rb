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

    item = init_memo(data)

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
      if item.to_member_ids.blank?
        item.to_member_ids = [@cur_user.id]
      end
      if !member_ids(item).include?(@cur_user.id)
        item.to_member_ids += [@cur_user.id]
      end
    end

    unless item.draft?
      member_ids(item).each do |id|
        item.deleted[id.to_s] = @datetime if id != @cur_user.id
      end
      item.deleted["sent"] = @datetime unless @sent_by_cur_user
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

  def init_memo(data)
    item = Gws::Memo::Message.new
    item.site_id = cur_site.id
    item.set_blank_val
    data.each do |k, v|
      next if %w(user members to_members cc_members bcc_members files list_id).include?(k)

      item[k] = v
    end

    item
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
      JSON.parse(f.read)
    end
  end
end
