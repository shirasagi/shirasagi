class SS::FileScanner
  class << self
    public
      def scan(file)
        response = ClamScan::Client.scan(stream: file.read)
        file.rewind
        response.safe?
      end
  end
end
