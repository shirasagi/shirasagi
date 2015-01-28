class Voice::Config
  def self.test_root
    prefix = "voice"
    timestamp = Time.now.strftime("%Y%m%d")
    tmp = "/tmp/#{prefix}-#{timestamp}"
    ::Dir.mkdir(tmp) unless ::Dir.exists?(tmp)
    tmp
  end

  DEFAULT_ROOT = Rails.env.to_s == "test" ? test_root : Rails.root.join("private", "files")

  cattr_reader(:default_values) do
    {
      disable: false,
      root: DEFAULT_ROOT,
    }
  end
end
