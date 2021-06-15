module SS::UploadPolicy
  extend ActiveSupport::Concern

  included do
    field :sanitizer_state, type: String
    before_destroy :remove_sanitizer_file
  end

  def sanitizer_input_path
    "#{Rails.root}/#{SS.config.ss.sanitizer_input}/#{id}_#{created.to_i}#{::File.extname(basename)}"
  end

  def sanitizer_state_options
    %w(wait complete).map { |v| [ I18n.t("ss.options.sanitizer_state.#{v}"), v ] }
  end

  def sanitizer_restore_file(output_path)
    self.sanitizer_state = 'complete'
    self.in_file = Fs::UploadedFile.create_from_file(output_path)
    return false unless save

    Fs.rm_rf(output_path)
    true
  end

  private

  def validate_upload_policy
    return unless SS::UploadPolicy.upload_policy == 'restricted'
    errors.add :base, :upload_restricted
  end

  def sanitizer_save_file
    return false unless SS::UploadPolicy.upload_policy == 'sanitizer'
    return false unless in_file.kind_of?(ActionDispatch::Http::UploadedFile)
    return false if try(:original_id)

    Fs.rm_rf(sanitizer_input_path) if Fs.exists?(sanitizer_input_path)
    Fs.upload(sanitizer_input_path, in_file.path)
    self.sanitizer_state = 'wait'
    self.size = in_file.size

    wait_file = Fs::UploadedFile.create_from_file(SS.config.ss.sanitizer_wait_image)
    SS::ImageConverter.attach(wait_file, ext: ::File.extname(in_file.original_filename)) do |converter|
      converter.apply_defaults!(resizing: resizing)
      Fs.upload(path, converter.to_io)
      self.geo_location = converter.geo_location
    end

    return true
  end

  def remove_sanitizer_file
    Fs.rm_rf(sanitizer_input_path) if SS::UploadPolicy.upload_policy == 'sanitizer'
  end

  module_function

  def upload_policy
    return nil if SS.config.ss.upload_policy.blank?

    default = SS.config.ss.upload_policy
    return SS.current_site.upload_policy || default if SS.current_site
    return SS.current_organization.upload_policy || default if SS.current_organization
    return SS.current_user.organization.try(:upload_policy) || default if SS.current_user
    return default
  end

  def upload_policy_options
    default = SS.config.ss.upload_policy
    values = [[I18n.t("ss.options.upload_policy.default_#{default}"), nil]]
    values += ['sanitizer', 'restricted'].map { |v| [ I18n.t("ss.options.upload_policy.#{v}"), v ] }
    values
  end
end
