class SS::FileScanner
  class << self
    public
      def scan(opts = {})
        ClamScan.configure.default_scan_options = {stdout: true}
        ClamScan.configure.client_location = '/usr/bin/clamdscan'
        ClamScan.configure.raise_unless_safe = false

        response = ClamScan::Client.scan(opts)
        response.safe?
      end
  end
end
