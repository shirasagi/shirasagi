module Tasks
  module WebMail
    class ExportMailTransfer
      class << self
        def exec(path)
          if path.blank?
            puts "pathを指定してください"
            return
          end
          File.open(path, "w") do |f|
            SS::User.pluck(:imap_settings).each do |settings|
              settings.each do |setting|
                if setting[:imap_aliase].present?
                  f.puts("#{setting[:name]} : #{setting[:imap_aliase]}")
                end
              end
            end
          end
        end
      end
    end
  end
end
