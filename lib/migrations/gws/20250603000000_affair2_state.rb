# 旧庶務事務メニューを強制的に非表示にする
# まだ利用する際は、手動で表示に変更してもらう

class SS::Migration20250603000000
  include SS::Migration::Base

  def change
    each_gws_site do |site|
      site.without_record_timestamps do
        site.menu_affair2_state ||= "show"
        site.menu_affair_state = "hide"
        unless site.save
          puts site.errors.full_messages
        end
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
end
