namespace :service do
  # @usage
  #   rake service:create_account data='{ name: "Test", account: "account", password: "pass" }'
  task :create_account => :environment do
    data = eval(ENV["data"])
    data[:in_password] = data.delete(:password)

    item = Service::Account.create(data)
    puts item.errors.empty? ? "  created  #{item.name}" : item.errors.full_messages.join("\n")
  end

  # @usage
  #   rake service:update_account data='{ account: "account", add_role: "administrator" }'
  task :update_account => :environment do
    data = eval(ENV["data"])
    data[:in_password] = data.delete(:password)

    item = Service::Account.where(account: data[:account]).first

    if !item
      puts "account: #{data[:account]} " + I18n.t("errors.messages.not_exist")
      exit
    end

    item.update(data)
    puts item.errors.empty? ? "  updated  #{item.name}" : item.errors.full_messages.join("\n")
  end

  # @usage
  #   rake service:reload_quota
  task :reload_quota => :environment do
    Service::Account.each do |item|
      puts item.name
      item.reload_quota_used.save
      puts "=> { base: #{item.base_quota_used}, cms: #{item.cms_quota_used} " +
        "gws: #{item.gws_quota_used}, webmail: #{item.webmail_quota_used} }"
    end
  end
end
