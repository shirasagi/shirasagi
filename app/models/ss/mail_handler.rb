class SS::MailHandler
  class << self
    def write_eml(data, model)
      now = Time.zone.now
      path = ::File.join(SS::File.root, "mail_handler", model, now.strftime('%Y%m%d'), "#{now.to_i}.eml")
      Fs.mkdir_p(::File.dirname(path))
      Fs.binwrite(path, data)
      path
    end
  end
end
