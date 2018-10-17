module Gws::SharedAddress
  class Initializer
    Gws::Role.permission :use_gws_shared_address, module_name: 'gws/shared_address'

    Gws::Role.permission :read_other_gws_shared_address_addresses, module_name: 'gws/shared_address'
    Gws::Role.permission :read_private_gws_shared_address_addresses, module_name: 'gws/shared_address'
    Gws::Role.permission :edit_other_gws_shared_address_addresses, module_name: 'gws/shared_address'
    Gws::Role.permission :edit_private_gws_shared_address_addresses, module_name: 'gws/shared_address'
    Gws::Role.permission :delete_other_gws_shared_address_addresses, module_name: 'gws/shared_address'
    Gws::Role.permission :delete_private_gws_shared_address_addresses, module_name: 'gws/shared_address'
    Gws::Role.permission :trash_other_gws_shared_address_addresses, module_name: 'gws/shared_address'
    Gws::Role.permission :trash_private_gws_shared_address_addresses, module_name: 'gws/shared_address'

    Gws::Role.permission :read_other_gws_shared_address_groups, module_name: 'gws/shared_address'
    Gws::Role.permission :read_private_gws_shared_address_groups, module_name: 'gws/shared_address'
    Gws::Role.permission :edit_other_gws_shared_address_groups, module_name: 'gws/shared_address'
    Gws::Role.permission :edit_private_gws_shared_address_groups, module_name: 'gws/shared_address'
    Gws::Role.permission :delete_other_gws_shared_address_groups, module_name: 'gws/shared_address'
    Gws::Role.permission :delete_private_gws_shared_address_groups, module_name: 'gws/shared_address'

    Gws.module_usable :shared_address do |site, user|
      Gws::SharedAddress.allowed?(:use, user, site: site)
    end
  end
end
