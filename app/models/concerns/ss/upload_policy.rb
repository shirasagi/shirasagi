module SS::UploadPolicy
  extend ActiveSupport::Concern

  included do
    field :sanitizer_state, type: String
    before_destroy :sanitizer_remove_file
  end

  def sanitizer_input_path
    "#{Rails.root}/#{SS.config.ss.sanitizer_input}/#{id}_#{created.to_i}#{::File.extname(basename)}"
  end

  def sanitizer_state_options
    %w(wait complete).map { |v| [ I18n.t("ss.options.sanitizer_state.#{v}"), v ] }
  end

  def sanitizer_skip
    @sanitizer_skip = true
  end

  def sanitizer_copy_file
    return false unless SS::UploadPolicy.upload_policy == 'sanitizer'
    return false if @sanitizer_skip
    return false if try(:original_id)
    return false if errors.present?

    ::FileUtils.rm_f(sanitizer_input_path) if FileTest.exist?(sanitizer_input_path)
    ::FileUtils.copy(path, sanitizer_input_path) if FileTest.exist?(path)

    set(sanitizer_state: 'wait') unless sanitizer_state == 'wait'
  end

  def sanitizer_restore_file(output_path)
    self.in_file = Fs::UploadedFile.create_from_file(output_path)
    self.sanitizer_state = 'complete'
    sanitizer_skip
    return false unless save(validate: false)

    try(:generate_public_file) if try(:public?)
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
    return false unless in_file
    return false if @sanitizer_skip
    return false if try(:original_id)

    ::FileUtils.rm_f(sanitizer_input_path) if FileTest.exist?(sanitizer_input_path)
    ::FileUtils.copy(path, sanitizer_input_path) if FileTest.exist?(path)

    self.sanitizer_state = 'wait'
  end

  def sanitizer_remove_file
    ::FileUtils.rm_f(sanitizer_input_path) if SS::UploadPolicy.upload_policy == 'sanitizer'
  end

  module_function

  def upload_policy
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
