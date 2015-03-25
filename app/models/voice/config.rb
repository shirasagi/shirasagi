class Voice::Config
  def self.test_root
    prefix = "voice"
    timestamp = Time.now.strftime("%Y%m%d")
    tmp = ::File.join(Dir.tmpdir, "#{prefix}-#{timestamp}")
    ::Dir.mkdir(tmp) unless ::Dir.exists?(tmp)
    tmp
  end

  DEFAULT_ROOT = Rails.env.test? ? test_root : Rails.root.join("private", "files").to_s

  cattr_reader(:default_values) do
    {
      disable: false,
      root: DEFAULT_ROOT,
      download: {
        "max_attempts" => 3,
        "initial_wait" => 3,
        "timeout_sec" => 10,
      },
      controller: {
        "location" => "/.voice",
        "retry_after" => 5
      },
      resource: {
        "loading" => "/assets/voice/voice-loading.mp3",
        "disabled" => "/assets/voice/voice-disabled.mp3",
        "overload" => "/assets/voice/voice-overload.mp3"
      },
      scraper: {
        "voice-marks" => [ "read-voice", "end-read-voice" ],
        "skip-marks" => [ "skip-voice", "end-skip-voice" ],
        "delete-tags" => %w(style script noscript iframe rb rp),
        "kuten-tags" => %w(h1 h2 h3 h4 h5 p br div pre blockquote ul ol table)
      },
      type: "openjtalk",
      openjtalk: {
        "bin" => "/usr/local/bin/open_jtalk",
        "dic" => "/usr/local/dic",
        "voice" => "config/voices/mei_normal/mei_normal.htsvoice",
        "opts" => "-s 48000 -p 200 -u 0.5 -jm 0.5 -jf 0.5",
        "max_length" => 1024,
        "sox" => "/usr/local/bin/sox"
      },
      lame: {
        "bin" => "/usr/local/bin/lame",
        "opts" => "--scale 5 --silent"
      },
    }
  end
end
