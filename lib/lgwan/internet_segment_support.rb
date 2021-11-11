module Lgwan
  class InternetSegmentSupport
    PULL_PRIVATE_FILES_COMMAND = "/root/shell/pull_publish.sh"

    class << self
      def pull_private_files(page)
        files = page.owned_files.map { |file| [file, file.thumb] }.flatten.compact
        stdin_data = files.map(&:path).join("\n") + "\n"
        output, error, status = Open3.capture3(PULL_PRIVATE_FILES_COMMAND, stdin_data: stdin_data)
        Rails.logger.error("Lgwan InternetSegmentSupport pull_private_files : #{error}") if error.present?
        error.blank?
      end
    end
  end
end
