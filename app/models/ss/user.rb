class SS::User
  include SS::Model::User
  include SS::Reference::UserTitles
  include SS::Reference::UserOccupations
  include Sys::Addon::Role
  include Sys::Reference::Role
  include Sys::Permission

  set_permission_name "sys_users", :edit

  require 'csv'
  require 'ss/user_csv_exporter'

  def self.csv_headers
    SS::UserCsvExporter.csv_headers
  end

  def self.to_csv(opts = {})
    SS::UserCsvExporter.to_csv(opts)
  end
end
