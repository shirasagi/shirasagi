# 既存ユーザーのうち、ワークフローを利用している人は、ワークフロー2のメニューを非表示にする。
class SS::Migration20240807000000
  include SS::Migration::Base

  depends_on "20240424000000"

  def change
    # put your migration code here
    each_gws_site do |site|
      site.without_record_timestamps do
        site.update(menu_workflow2_state: "hide")
      end
    end
  end

  private

  def each_gws_site
    criteria = Gws::Group.unscoped
    all_ids = criteria.pluck(:id)
    all_ids.each_slice(100) do |ids|
      criteria.in(id: ids).to_a.each do |group|
        if group.gws_use?
          yield group
        end
      end
    end
  end

  def workflow_available?(site)
    return true if Gws::Workflow::File.unscoped.site(site).present?
    false
  end
end
