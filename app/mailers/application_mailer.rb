# coding: utf-8
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

        mail = yml[Rails.env.to_s]
        ActionMailer::Base.delivery_method = mail['delivery_method']
        ActionMailer::Base.default from: mail['default_from'], charset: mail['default_charset']
        if  mail['delivery_method'] == :smtp
          ActionMailer::Base.smtp_settings = {
            address: mail['address'],
            port: mail['port'],
            domain: mail['domain'],
            user_name: mail['user_name'],
            password: mail['password'],
            authentication: mail['authentication'],
            enable_starttls_auto: true
          }
        elsif mail['delivery_method'] == :sendmail
          ActionMailer::Base.sendmail_settings = {
            location: mail['location'],
            arguments:  mail['arguments']
          }
        end
      end
    end
  end
end
