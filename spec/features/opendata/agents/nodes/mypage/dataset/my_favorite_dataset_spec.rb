require 'spec_helper'

describe "opendata_agents_nodes_my_favorite_dataset", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let(:member) { opendata_member(site: site) }
  let!(:node_member) { create :opendata_node_member, cur_site: site, layout_id: layout.id }
  let!(:node_dataset) { create :opendata_node_dataset, cur_site: site, layout_id: layout.id }
  let!(:node_search_dataset) do
    create :opendata_node_search_dataset, cur_site: site, cur_node: node_dataset, layout_id: layout.id
  end

  let!(:upper_html) { "<a href=\"new/\">#{I18n.t("ss.links.new")}</a><table class=\"opendata-datasets datasets\"><tbody>" }
  let!(:node_mypage) { create :opendata_node_mypage, cur_site: site, layout_id: layout.id, filename: "mypage" }
  let!(:node_my_dataset) do
    create :opendata_node_my_dataset, cur_site: site, cur_node: node_mypage, layout_id: layout.id, upper_html: upper_html
  end
  let!(:node_my_favorite_dataset) do
    create :opendata_node_my_favorite_dataset, cur_site: site, cur_node: node_mypage, layout_id: layout.id, upper_html: upper_html
  end
  let!(:node_my_idea) do
    create :opendata_node_my_idea, cur_site: site, cur_node: node_mypage, layout_id: layout.id, upper_html: upper_html
  end

  let!(:node_login) { create :member_node_login, cur_site: site, layout_id: layout.id, redirect_url: node_my_favorite_dataset.url }

  let(:index_url) { URI.parse "http://#{site.domain}#{node_my_favorite_dataset.url}" }

  before do
    login_opendata_member(site, node_login, member)
  end

  after do
    logout_opendata_member(site, node_login, member)
  end

  describe "#index" do
    let!(:dataset1) { create :opendata_dataset, cur_node: node_dataset, member_id: member.id }
    let!(:dataset2) { create :opendata_dataset, cur_node: node_dataset, member_id: member.id }

    it "no favorite dataset" do
      visit index_url
      expect(current_path).to eq index_url.path
      within ".opendata-datasets" do
        expect(page).to have_css(".empty", text: I18n.t("opendata.labels.no_favorite_datasets"))
      end
    end

    it "have favorite dataset" do
      visit dataset1.url
      within ".mypage-content .dataset-favorite" do
        click_on I18n.t("opendata.links.add_favorite")
      end
      within ".mypage-content .dataset-favorite" do
        expect(page).to have_css("a", text: I18n.t("opendata.links.registered_favorite"))
      end

      visit index_url
      within "table.opendata-datasets" do
        expect(page).to have_link dataset1.name
        expect(page).to have_no_link dataset2.name
      end

      within "table.opendata-datasets" do
        click_on I18n.t("opendata.labels.delete_favorite_dataset")
      end
      expect(page).to have_css("#ss-notice", text: I18n.t("opendata.notice.remove_favorite"))

      within ".opendata-datasets" do
        expect(page).to have_css(".empty", text: I18n.t("opendata.labels.no_favorite_datasets"))
      end
    end
  end
end
