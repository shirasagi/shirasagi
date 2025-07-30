class ApplicationMailer < ActionMailer::Base
  class << self
    def set(option)
      if option == :load_settings
        conf = SS.config.mail
        delivery_method = conf['delivery_method'].to_sym
        ActionMailer::Base.delivery_method = delivery_method
        ActionMailer::Base.default from: conf['default_from'], charset: conf['default_charset']

        case delivery_method
        when :smtp
          set_smtp conf
        when :sendmail
          set_sendmail conf
        end
      end
    end

    def set_smtp(conf)
      conf = conf.to_h.stringify_keys

      smtp_settings = {
        address: conf['address'],
        port: conf['port'],
        domain: conf['domain'],
        user_name: conf['user_name'],
        password: conf['password'],
        authentication: conf['authentication'].try(:to_sym)
      }
      # optional smtp configurations
      %i[enable_starttls enable_starttls_auto openssl_verify_mode ssl tls open_timeout read_timeout].each do |key|
        str_key = key.to_s
        smtp_settings[key] = conf[str_key] if conf.key?(str_key)
      end

      ActionMailer::Base.smtp_settings = smtp_settings
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
