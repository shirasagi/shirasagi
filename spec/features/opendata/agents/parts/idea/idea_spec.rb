require 'spec_helper'

describe "opendata_agents_parts_idea", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let!(:parts) { create(:opendata_part_idea) }
  let(:index_path) { parts.url }
  before do
    create_once :opendata_node_search_idea, filename: "idea/search"
  end

  it "#index" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      visit index_path
      expect(current_path).to eq index_path
    end
  end
end
