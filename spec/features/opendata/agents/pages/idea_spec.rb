require 'spec_helper'

describe "opendata_agents_pages_idea", dbscope: :example do

  let(:site) { cms_site }
  let(:node) { create_once :opendata_node_idea, name: "opendata_idea" }
  let(:category) { create_once :opendata_node_category, basename: "opendata_category1" }
  let(:area) { create_once :opendata_node_area, basename: "opendata_area_1" }
  let!(:node_search) { create :opendata_node_search_idea }

  context "ideaurl" do
    let(:node_ds) { create_once :opendata_node_dataset, basename: "opendata_dataset_1" }
    let(:ideaurl) do
      create_once :opendata_idea,
                  filename: "#{node.filename}/#{unique_id}.html",
                  category_ids: [ category.id ],
                  area_ids: [ area.id ]
    end
    let(:ideaurl_path) { "#{ideaurl.url}" }

    it "#index" do
      page.driver.browser.with_session("public") do |session|
        session.env("HTTP_X_FORWARDED_HOST", site.domain)
        session.env("REQUEST_PATH", ideaurl_path)
        visit ideaurl_path
        expect(current_path).to eq ideaurl_path
      end
    end

  end

end
