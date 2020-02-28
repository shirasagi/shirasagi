class SS::Migration20191205000003
  include SS::Migration::Base

  depends_on "20181214000000"

  def change
    each_target_role do |role|
      add_permission_to_role(role, "read_opendata_reports")
      role.save
    end

    each_admin_role do |role|
      add_permission_to_role(role, "read_opendata_histories")
      role.save
    end
  end

  private

  def each_role(&block)
    criteria = Cms::Role.all.unscoped
    all_ids = criteria.pluck(:id)
    all_ids.each_slice(20) do |ids|
      roles = criteria.in(id: ids).to_a
      roles.each(&block)
    end
  end

  def each_target_role(&_block)
    each_role do |role|
      # フォルダーの閲覧権限がない
      next unless %w(read_other_cms_nodes read_private_cms_nodes).any? { |permission| role.permissions.include?(permission) }

      # オープンデータデータセット関連の権限がない
      next unless %w(read_other_opendata_datasets read_private_opendata_datasets).any? do |permission|
        role.permissions.include?(permission)
      end

      yield role
    end
  end

  def each_admin_role(&block)
    each_role do |role|
      # 権限「フォルダーの閲覧（全て）」がない
      next unless %w(read_other_cms_nodes).any? { |permission| role.permissions.include?(permission) }

      # 権限「データセットの閲覧（全て）」がない
      next unless %w(read_other_opendata_datasets).any? { |permission| role.permissions.include?(permission) }

      yield role
    end
  end

  def add_permission_to_role(role, permission)
    permissions = role.permissions.try { |array| array.dup } || []
    permissions << permission
    permissions.flatten!
    permissions.uniq!
    permissions.sort!

    role.permissions = permissions
  end
end
