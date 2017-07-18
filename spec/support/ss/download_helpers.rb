module SS
  module DownloadHelpers

    TIMEOUT = 1

    module_function

    def path
      @path ||= begin
        path = Rails.root.join('tmp/spec/downloads')
        ::FileUtils.mkdir_p(path) if !::Dir.exist?(path)
        path.to_s
      end
    end

    def downloads
      ::Dir["#{path}/*"]
    end

    def download
      downloads.first
    end

    def wait_for_download
      ::Timeout.timeout(TIMEOUT) do
        sleep 0.1 while downloading?
      end
    end

    def download_content
      wait_for_download
      ::File.binread(download)
    end

    def download_csv
      csv_content = download_content
      csv_content.force_encoding('CP932')
      csv_content.encode!('UTF-8')
      CSV.parse(csv_content)
    end

    def downloaded?
      !downloading?
    end

    def downloading?
      downloads.grep(/\.crdownload$/).any? || downloads.blank?
    end

    def clear_downloads
      ::FileUtils.rm_f(downloads)
    end
  end
end
