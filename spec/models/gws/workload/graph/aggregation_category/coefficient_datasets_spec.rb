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

  let!(:load1) { create :gws_workload_load, order: 10, coefficient: 166_320 }
  let!(:load2) { create :gws_workload_load, order: 20, coefficient: 55_440 }
  let!(:load3) { create :gws_workload_load, order: 30, coefficient: 27_720 }

  let!(:aggregation_groups) do
    Gws::Aggregation::GroupJob.bind(site_id: site.id).perform_now
    Gws::Aggregation::Group.site(site).active_at
  end
  let!(:users) { aggregation_groups.find_group(group.id).ordered_users }

  let!(:graph_users) { Gws::Workload::Graph::UserSetting.create_settings(users, site_id: site.id, group_id: group.id) }
  let!(:overtimes) { Gws::Workload::Overtime.create_settings(year, users, site_id: site.id, group_id: group.id) }

  context "work and comments exists" do
    let!(:item1) do
      d1 = Date.new(year, 4, 1)
      d2 = Date.new(year, 4, 7)
      d3 = Date.new(year, 8, 7)
      create :gws_workload_work, due_start_on: d1, due_end_on: d2, due_date: d3,
        load: load1, category: category1
    end
    let!(:item2) do
      d1 = Date.new(year, 4, 1)
      d2 = Date.new(year, 4, 7)
      d3 = Date.new(year, 8, 7)
      create :gws_workload_work, due_start_on: d1, due_end_on: d2, due_date: d3,
        load: load2, category: category1
    end
    let!(:item3) do
      d1 = Date.new(year, 4, 1)
      d2 = Date.new(year, 4, 7)
      d3 = Date.new(year, 8, 7)
      create :gws_workload_work, due_start_on: d1, due_end_on: d2, due_date: d3,
        load: load3, category: category1
    end

    # 4月
    let(:commented_at1) { Date.new(year, 4, 5) }
    let(:commented_at2) { Date.new(year, 4, 20) }
    # 5月
    let(:commented_at3) { Date.new(year, 5, 5) }
    let(:commented_at4) { Date.new(year, 5, 20) }

    # 業務負荷: load1
    # 4月5日: 3回コメント
    # 4月20日: 1回コメント
    # 4月の業務負荷: 2日分, 166_320 * 2
    let!(:comment1) do
      create(:gws_workload_work_comment, work: item1, commented_at: commented_at1,
        in_worktime_hours: 1, in_worktime_minutes: 0)
    end
    let!(:comment2) do
      create(:gws_workload_work_comment, work: item1, commented_at: commented_at1,
        in_worktime_hours: 1, in_worktime_minutes: 0)
    end
    let!(:comment3) do
      create(:gws_workload_work_comment, work: item1, commented_at: commented_at1,
        in_worktime_hours: 1, in_worktime_minutes: 0)
    end
    let!(:comment4) do
      create(:gws_workload_work_comment, work: item1, commented_at: commented_at2,
        in_worktime_hours: 1, in_worktime_minutes: 0)
    end

    # 業務負荷: load2
    # 4月5日: 1回コメント
    # 5月5日: 1回コメント
    # 5月20日: 1回コメント
    # 4月の業務負荷: 1日分, 55_440 * 1
    # 5月の業務負荷: 2日分, 55_440 * 2
    let!(:comment5) do
      create(:gws_workload_work_comment, work: item2, commented_at: commented_at1,
        in_worktime_hours: 1, in_worktime_minutes: 0)
    end
    let!(:comment6) do
      create(:gws_workload_work_comment, work: item2, commented_at: commented_at3,
        in_worktime_hours: 1, in_worktime_minutes: 0)
    end
    let!(:comment7) do
      create(:gws_workload_work_comment, work: item2, commented_at: commented_at4,
        in_worktime_hours: 1, in_worktime_minutes: 0)
    end

    it "coefficient_datasets" do
      aggregation = described_class.new(site, year, group, users)
      aggregation.set_category(category1)
      aggregation.set_base_items
      aggregation.aggregate_coefficient_datasets
      datasets = aggregation.load_datasets

      expect(datasets[0][:label]).to eq load1.name
      expect(datasets[0][:data]).to eq [(166_320 * 2), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

      expect(datasets[1][:label]).to eq load2.name
      expect(datasets[1][:data]).to eq [(55_440 * 1), (55_440 * 2), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

      expect(datasets[2][:label]).to eq load3.name
      expect(datasets[2][:data]).to eq [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    end
  end
end
