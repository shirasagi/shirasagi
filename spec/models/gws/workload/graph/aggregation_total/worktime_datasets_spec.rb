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

  context "work and comments exists" do
    let!(:item) do
      d1 = Date.new(year, 4, 1)
      d2 = Date.new(year, 4, 7)
      d3 = Date.new(year, 8, 7)
      create :gws_workload_work, due_start_on: d1, due_end_on: d2, due_date: d3, load: load1
    end

    let(:commented_at1) { Date.new(year, 4, 5) }
    let(:commented_at2) { Date.new(year, 5, 5) }
    let(:commented_at3) { Date.new(year, 6, 5) }

    let!(:comment1) do
      create(:gws_workload_work_comment, work: item, commented_at: commented_at1,
        in_worktime_hours: 2, in_worktime_minutes: 0)
    end
    let!(:comment2) do
      create(:gws_workload_work_comment, work: item, commented_at: commented_at1,
        in_worktime_hours: 1, in_worktime_minutes: 30)
    end
    let!(:comment3) do
      create(:gws_workload_work_comment, work: item, commented_at: commented_at2,
        in_worktime_hours: 3, in_worktime_minutes: 0)
    end
    let!(:comment4) do
      create(:gws_workload_work_comment, work: item, commented_at: commented_at3,
        in_worktime_hours: 0, in_worktime_minutes: 15)
    end
    let!(:comment5) do
      create(:gws_workload_work_comment, work: item, commented_at: commented_at3)
    end

    it "worktime_datasets" do
      aggregation = described_class.new(site, year, group, users)
      aggregation.set_base_items
      aggregation.aggregate_worktime_datasets
      datasets = aggregation.worktime_datasets

      expect(datasets[1][:label]).to eq user.name
      expect(datasets[1][:data]).to eq [3.5, 3, 0.25, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    end
  end
end
