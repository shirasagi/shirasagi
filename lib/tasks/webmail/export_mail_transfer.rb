module Tasks
  module Webmail
    class ExportMailTransfer
      class << self
        def exec(output)
          if output.blank?
            puts "outputを指定してください"
            return
          end
          File.open(output, "w") do |f|
            SS::User.each do |user|
              user.imap_settings.each do |setting|
                if setting[:imap_alias].present?
                  f.puts("#{setting[:from].presence || user.imap_default_settings[:address]} #{setting[:imap_alias]}")
                end
              end
            end
          end
        end
      end
    end
  end
end
