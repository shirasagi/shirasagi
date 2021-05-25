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
    return unless SS.config.ss.upload_policy == 'restricted'
    errors.add :base, :upload_restricted
  end

  def sanitizer_save_file
    return false unless SS.config.ss.upload_policy == 'sanitizer'
    return false unless in_file.kind_of?(ActionDispatch::Http::UploadedFile)
    return false if try(:original_id)

    Fs.write(path, '')
    Fs.rm_rf(sanitizer_input_path) if Fs.exists?(sanitizer_input_path)
    Fs.upload(sanitizer_input_path, in_file.path)
    self.sanitizer_state = 'wait'
    self.size = in_file.size

    return true
  end

  def remove_sanitizer_file
    Fs.rm_rf(sanitizer_input_path) if SS.config.ss.upload_policy == 'sanitizer'
  end

  module_function

  def upload_policy
    return nil if SS.config.ss.upload_policy.blank?
    return SS.current_site.upload_policy || SS.config.ss.upload_policy if SS.current_site
    return SS.current_organization.upload_policy || SS.config.ss.upload_policy if SS.current_organization
    SS.config.ss.upload_policy
  end

  def upload_policy_options
    values = ["default_#{self.upload_policy}", 'sanitizer', 'restricted']
    values.map { |v| [ I18n.t("ss.options.upload_policy.#{v}"), v ] }
  end
end
