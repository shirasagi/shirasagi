require 'spec_helper'

describe "gws_workload_graphs", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:index_path) { gws_workload_graphs_path site }

  let!(:category1) { create :gws_workload_category, order: 10 }
  let!(:category2) { create :gws_workload_category, order: 20 }
  let!(:category3) { create :gws_workload_category, order: 30 }

  let!(:client1) { create :gws_workload_client, order: 10 }
  let!(:client2) { create :gws_workload_client, order: 20 }
  let!(:client3) { create :gws_workload_client, order: 30 }

  let!(:load1) { create :gws_workload_load, order: 10 }
  let!(:load2) { create :gws_workload_load, order: 20 }
  let!(:load3) { create :gws_workload_load, order: 30 }

  before do
    Gws::Aggregation::GroupJob.bind(site_id: site.id).perform_now
  end

  context "with auth" do
    before { login_gws_user }

    it "#index" do
      visit index_path
      expect(page).to have_css(".total-graph")
      expect(page).to have_css(".worktime-graph")
      expect(page).to have_css(".overtime-graph")

      within ".gws-side-navi" do
        click_on category1.name
      end
      expect(page).to have_css(".client-graph")
      expect(page).to have_css(".load-graph")

      within ".gws-side-navi" do
        click_on category2.name
      end
      expect(page).to have_css(".client-graph")
      expect(page).to have_css(".load-graph")

      within ".gws-side-navi" do
        click_on category3.name
      end
      expect(page).to have_css(".client-graph")
      expect(page).to have_css(".load-graph")
    end
  end
end
