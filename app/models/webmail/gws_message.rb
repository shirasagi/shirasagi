class Webmail::GwsMessage
  include ActiveSupport::NumberHelper
  include SS::Document
  include Gws::Model::Memo::Message
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::SitePermission
  include Gws::Addon::Member
  include Webmail::Addon::MailBody
  include Webmail::Addon::MailFile
  include Gws::Addon::Memo::Comments

  attr_accessor :imap

  before_save :save_files
  before_save :save_ref_files

  def model_name
    ActiveModel::Name.new(Gws::Memo::Message)
  end

  def save_files
    files.each do |file|
      file.update_attributes(model: model_name.i18n_key)
    end
  end

  def save_ref_files
    return if imap.blank?
    return if ref_file_ids.blank?
    return if ref_file_uid.blank?

    ref_ids = ref_file_ids.map { |c| c.sub(/^ref-/, '') }
    ss_file_ids = ref_ids.map do |section|
      part = imap.mails.find_part ref_file_uid, section

      file = Fs::UploadedFile.new(part.filename)
      file.binmode
      file.write(part.decoded)
      file.rewind
      file.original_filename = part.filename
      file.content_type = part.content_type

      ss_file = SS::File.new
      ss_file.in_file = file
      ss_file.name = file.original_filename
      ss_file.model = model_name.i18n_key
      ss_file.save!
      ss_file.id
    end
    self.file_ids += ss_file_ids
  end
end
