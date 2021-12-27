module SS::Lgwan
  module_function

  def enabled?
    !SS.config.lgwan.disable
  end

  def pull_private_files(page)
    files = page.owned_files.map { |file| [file, file.thumb] }.flatten.compact
    return true if files.blank?

    command = SS.config.lgwan.pull_private_files_command
    stdin_data = files.map(&:path).join("\n") + "\n"
    output, error, status = Open3.capture3(command, stdin_data: stdin_data)
    Rails.logger.error("Lgwan Support pull_private_files : #{error}") if error.present?
    error.blank?
  end
end
