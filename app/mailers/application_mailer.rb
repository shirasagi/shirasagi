class ApplicationMailer
  class << self
    def set(option)
      if option == :load_settings
        begin
          yml = YAML.load_file(File.join(Rails.root, 'config', 'mail.yml'))
          raise "empty" if yml.blank?
        rescue => e
          return nil
        end

        conf = yml[Rails.env.to_s]
        ActionMailer::Base.delivery_method = conf['delivery_method']
        ActionMailer::Base.default from: conf['default_from'], charset: conf['default_charset']
        if conf['delivery_method'] == :smtp
          set_smtp conf
        elsif conf['delivery_method'] == :sendmail
          set_sendmail conf
        end
      end
    end

    def set_smtp(conf)
      ActionMailer::Base.smtp_settings = {
        address: conf['address'],
        port: conf['port'],
        domain: conf['domain'],
        user_name: conf['user_name'],
        password: conf['password'],
        authentication: conf['authentication'],
        enable_starttls_auto: true
      }
    end

    def set_sendmail(conf)
      ActionMailer::Base.sendmail_settings = {
        location: conf['location'],
        arguments: conf['arguments']
      }
    end
  end
end
