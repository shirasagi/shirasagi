class SS::Migration20240729000000
  include SS::Migration::Base

  depends_on "20240424000000"

  def change
    use_permission = "read_cms_check_links_reports"
    run_permission = "use_cms_tools"

    Cms::Role.where(:permissions.in => [use_permission, run_permission]).each do |item|
      if item.permissions.include?(use_permission)
        item.add_to_set(permissions: "use_cms_check_links")
      end
      if item.permissions.include?(run_permission)
        item.add_to_set(permissions: "run_cms_check_links")
      end
    end
  end
end
