module Cms::GroupCsv
  extend ActiveSupport::Concern

  module ClassMethods
    def enum_csv(options = {})
      drawer = SS::Csv.draw(:export, context: self) do |drawer|
        drawer.column :id
        drawer.column :code
        drawer.column :name
        drawer.column :order
        drawer.column :activation_date
        drawer.column :expiration_date
        drawer.column :memo
        drawer.column :ldap_dn
        drawer.column :contact_group_name
        drawer.column :contact_tel
        drawer.column :contact_fax
        drawer.column :contact_email
        drawer.column :contact_postal_code
        drawer.column :contact_address
        drawer.column :contact_link_url
        drawer.column :contact_link_name
        drawer.column :cms_role_ids do
          drawer.body { |item| item.cms_roles.pluck(:name).join("\n") }
        end
      end
      drawer.enum(self.all, options)
    end
  end
end
