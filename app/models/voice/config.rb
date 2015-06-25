class Voice::Config
  class << self
    def root
      return test_root if Rails.env.test?
      ::File.join(Rails.root, "private", "files")
    end

    def test_root
      prefix = "voice"
      timestamp = Time.zone.now.strftime("%Y%m%d")
      tmp = ::File.join(Dir.tmpdir, "#{prefix}-#{timestamp}")
      ::Dir.mkdir(tmp) unless ::Dir.exists?(tmp)
      tmp
    end
  end
end
