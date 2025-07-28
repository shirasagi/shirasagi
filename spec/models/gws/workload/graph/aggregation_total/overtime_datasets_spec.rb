require 'spec_helper'

describe Gws::Workload::Graph::Aggregation, type: :model, dbscope: :example do
  let!(:site) { gws_site }
  let!(:user) { gws_user }

  let!(:year) { site.fiscal_year }
  let!(:group) { user.gws_default_group }

  let!(:category1) { create :gws_workload_category, order: 10 }
  let!(:category2) { create :gws_workload_category, order: 20 }
  let!(:category3) { create :gws_workload_category, order: 30 }

  let!(:client1) { create :gws_workload_client, order: 10 }
  let!(:client2) { create :gws_workload_client, order: 20 }
  let!(:client3) { create :gws_workload_client, order: 30 }

  let!(:load1) { create :gws_workload_load, order: 10 }
  let!(:load2) { create :gws_workload_load, order: 20 }
  let!(:load3) { create :gws_workload_load, order: 30 }

  let!(:aggregation_groups) do
    Gws::Aggregation::GroupJob.bind(site_id: site.id).perform_now
    Gws::Aggregation::Group.site(site).active_at
  end
  let!(:users) { aggregation_groups.find_group(group.id).ordered_users }

  let!(:graph_users) { Gws::Workload::Graph::UserSetting.create_settings(users, site_id: site.id, group_id: group.id) }
  let!(:overtimes) { Gws::Workload::Overtime.create_settings(year, users, site_id: site.id, group_id: group.id) }

  context "overtime exists" do
    before do
      overtime = overtimes.find_by(user_id: user.id)
      overtime.month4_minutes = 10 * 60
      overtime.month5_minutes = 20 * 60
      overtime.month6_minutes = 30 * 60
      overtime.update!
    end

    it "overtime_datasets" do
      aggregation = described_class.new(site, year, group, users)
      aggregation.set_base_items
      aggregation.aggregate_overtime_datasets
      datasets = aggregation.overtime_datasets

      expect(datasets[1][:label]).to eq user.name
      expect(datasets[1][:data]).to eq [10, 20, 30, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    end
  end
end
