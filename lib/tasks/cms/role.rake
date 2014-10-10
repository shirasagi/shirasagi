namespace :cms do
  namespace :role do
    namespace :admin do
      task :create => :environment do
        site = SS::Site.find_by host: ENV["site"]
        permissions = %w(
          edit_cms_sites
          edit_cms_users
          read_other_cms_nodes
          read_other_cms_pages
          read_other_cms_parts
          read_other_cms_layouts
          edit_other_cms_nodes
          edit_other_cms_pages
          edit_other_cms_parts
          edit_other_cms_layouts
          delete_other_cms_nodes
          delete_other_cms_pages
          delete_other_cms_parts
          delete_other_cms_layouts
          read_other_article_pages
          edit_other_article_pages
          delete_other_article_pages
        )
        data = { site_id: site.id, name: "admin",  permissions: permissions, permission_level: 3 }

        puts "Create role ..."
        item = Cms::Role.find_or_create_by data
        puts item.errors.empty? ? "  created  #{item.name}" : item.errors.full_messages.join("\n  ")

        puts "Update user ..."
        user = SS::User.find_by name: ENV["user"]
        user.add_to_set cms_role_ids: item.id
        user.update
        puts user.errors.empty? ? "  updated  #{user.name}" : user.errors.full_messages.join("\n  ")
      end
    end
  end
end
