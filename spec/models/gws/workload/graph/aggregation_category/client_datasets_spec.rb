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

  context "work exists" do
    let!(:item1) do
      d1 = Date.new(year, 4, 1)
      d2 = Date.new(year, 4, 7)
      d3 = Date.new(year, 4, 7)
      create :gws_workload_work, due_start_on: d1, due_end_on: d2, due_date: d3,
        category: category1, client: client1
    end
    let!(:item2) do
      d1 = Date.new(year, 4, 1)
      d2 = nil
      d3 = Date.new(year, 12, 7)
      create :gws_workload_work, due_start_on: d1, due_end_on: d2, due_date: d3,
        category: category1, client: client1
    end
    let!(:item3) do
      d1 = Date.new(year, 5, 1)
      d2 = Date.new(year, 5, 7)
      d3 = Date.new(year, 5, 7)
      create :gws_workload_work, due_start_on: d1, due_end_on: d2, due_date: d3,
        category: category1, client: client1
    end
    let!(:item4) do
      d1 = Date.new(year, 4, 1)
      d2 = Date.new(year, 6, 7)
      d3 = Date.new(year, 6, 7)
      create :gws_workload_work, due_start_on: d1, due_end_on: d2, due_date: d3,
        category: category1, client: client2
    end
    let!(:item5) do
      last_year = year - 1
      d1 = Date.new(last_year, 4, 1)
      d2 = Date.new(last_year, 4, 7)
      d3 = Date.new(last_year, 4, 7)
      create :gws_workload_work, year: last_year, due_start_on: d1, due_end_on: d2, due_date: d3,
        category: category1, client: client3
    end

    it "client_datasets" do
      aggregation = described_class.new(site, year, group, users)
      aggregation.set_category(category1)
      aggregation.set_base_items
      aggregation.aggregate_client_datasets
      datasets = aggregation.client_datasets

      expect(datasets[0][:label]).to eq client1.name
      expect(datasets[0][:data]).to eq [2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

      expect(datasets[1][:label]).to eq client2.name
      expect(datasets[1][:data]).to eq [1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0]

      expect(datasets[2][:label]).to eq client3.name
      expect(datasets[2][:data]).to eq [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    end
  end
end
