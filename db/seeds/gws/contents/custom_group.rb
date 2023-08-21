## -------------------------------------
puts "# custom_group"

def create_custom_group(data)
  create_item(Gws::CustomGroup, data)
end

@cgroups = [
  create_custom_group(
    name: "#{@site_name}プロジェクト", member_ids: %w[sys admin user1 user3].map { |uid| u(uid).id },
    readable_setting_range: 'select',
    readable_group_ids: %w[政策課 広報課].map { |n| g(n).id }
  )
]

