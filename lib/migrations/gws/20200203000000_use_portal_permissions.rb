class SS::Migration20200203000000
  include SS::Migration::Base

  depends_on "20191029000001"

  def change
    permissions = %w(use_gws_portal_user_settings use_gws_portal_group_settings use_gws_portal_organization_settings).freeze
    each_role do |role|
      role.add_to_set(permissions: permissions)
    end
  end

  private

  def each_role(&block)
    criteria = Gws::Role.all.unscoped
    all_ids = criteria.pluck(:id)
    all_ids.each_slice(20) do |ids|
      criteria.in(id: ids).to_a.each(&block)
    end
  end
end
