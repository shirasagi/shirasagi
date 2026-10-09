#frozen_string_literal: true

class SS::Migration20261009000000
  include SS::Migration::Base

  depends_on "20260427000000"

  def change
    each_gws_site do |site|
      Gws::Tabular::FormRefreshJob.bind(site_id: site).perform_now
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
