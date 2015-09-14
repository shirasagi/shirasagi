class SS::FileScanner
  class << self
    public
      def scan(opts = {})
        ClamScan.configure do |config|
          config.default_scan_options = {stdout: true}
          config.client_location      = '/usr/bin/clamdscan'
          config.raise_unless_safe    = false
        end

        response = ClamScan::Client.scan(opts)
        response.safe?
      end
  end
end
