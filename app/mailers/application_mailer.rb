class ApplicationMailer
  class << self
    def set(option)
      if option == :load_settings
        conf = SS.config.mail
        ActionMailer::Base.delivery_method = conf['delivery_method'].to_sym
        ActionMailer::Base.default from: conf['default_from'], charset: conf['default_charset']
        if conf['delivery_method'] == 'smtp'
          set_smtp conf
        elsif conf['delivery_method'] == 'sendmail'
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
        authentication: conf['authentication'].try(:to_sym),
        enable_starttls_auto: true
      }
    end

    def set_sendmail(conf)
      if conf['location'].present?
        ActionMailer::Base.sendmail_settings["location"] = conf['location']
      end
      if conf['location'].present?
        ActionMailer::Base.sendmail_settings["arguments"] = conf['arguments']
      end
    end
  end
end
