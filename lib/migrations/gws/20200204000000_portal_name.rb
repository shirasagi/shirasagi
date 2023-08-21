class SS::Migration20200204000000
  include SS::Migration::Base

  depends_on "20200203000000"

  def change
    each_organization_portal do |portal|
      portal.set(name: I18n.t("gws/portal.tabs.root_portal"))
    end
  end

  private

  def each_organization_portal(&block)
    each_portal do |portal|
      next unless portal.portal_group.root?

      yield portal
    end
  end

  def each_portal(&block)
    criteria = Gws::Portal::GroupSetting.all.unscoped
    all_ids = criteria.pluck(:id)
    all_ids.each_slice(20) do |ids|
      criteria.in(id: ids).to_a.each(&block)
    end
  end
end
