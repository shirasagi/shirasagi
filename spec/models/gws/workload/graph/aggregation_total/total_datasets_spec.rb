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
      create :gws_workload_work, due_start_on: d1, due_end_on: d2, due_date: d3, load: load1
    end
    let!(:item2) do
      d1 = Date.new(year, 5, 1)
      d2 = nil
      d3 = Date.new(year, 12, 7)
      create :gws_workload_work, due_start_on: d1, due_end_on: d2, due_date: d3, load: load1
    end
    let!(:item3) do
      d1 = Date.new(year, 4, 1)
      d2 = Date.new(year, 6, 7)
      d3 = Date.new(year, 6, 7)
      create :gws_workload_work, due_start_on: d1, due_end_on: d2, due_date: d3, load: load2
    end
    let!(:item4) do
      last_year = year - 1
      d1 = Date.new(last_year, 4, 1)
      d2 = Date.new(last_year, 4, 7)
      d3 = Date.new(last_year, 4, 7)
      create :gws_workload_work, year: last_year, due_start_on: d1, due_end_on: d2, due_date: d3, load: load3
    end

    it "total_datasets" do
      expect(item1.year_months).to eq [{ "year" => year, "month" => 4 }]
      expect(item2.year_months).to eq [{ "year" => year, "month" => 5 }]
      expect(item3.year_months).to eq [
        { "year" => year, "month" => 4 }, { "year" => year, "month" => 5 }, { "year" => year, "month" => 6 }]
      expect(item4.year_months).to eq [{ "year" => year - 1, "month" => 4 }]

      aggregation = described_class.new(site, year, group, users)
      aggregation.set_base_items
      aggregation.aggregate_total_datasets
      datasets = aggregation.total_datasets

      expect(datasets[0][:label]).to eq load1.name
      expect(datasets[0][:data]).to eq [50, 50, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

      expect(datasets[1][:label]).to eq load2.name
      expect(datasets[1][:data]).to eq [50, 50, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0]

      expect(datasets[2][:label]).to eq load3.name
      expect(datasets[2][:data]).to eq [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

      expect(datasets[3][:label]).to eq I18n.t("gws/workload.graph.total.label")
      expect(datasets[3][:data]).to eq [2, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    end
  end
end
