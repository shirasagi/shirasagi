class Voice::Config
  def self.test_root
    prefix = "voice"
    timestamp = Time.zone.now.strftime("%Y%m%d")
    tmp = ::File.join(Dir.tmpdir, "#{prefix}-#{timestamp}")
    ::Dir.mkdir(tmp) unless ::Dir.exists?(tmp)
    tmp
  end
end
