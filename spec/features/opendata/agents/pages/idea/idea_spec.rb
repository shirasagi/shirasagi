require 'spec_helper'

describe "opendata_agents_pages_idea", dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let(:node_idea) { create :opendata_node_idea, cur_site: site, layout_id: layout.id }
  let(:node_category) { create :opendata_node_category, cur_site: site, layout_id: layout.id }
  let(:node_area) { create :opendata_node_area, cur_site: site, layout_id: layout.id }
  let!(:node_search) { create :opendata_node_search_idea, cur_site: site, cur_node: node_idea, layout_id: layout.id }
  let(:page_idea) do
    create :opendata_idea, cur_site: site, cur_node: node_idea, layout_id: layout.id, category_ids: [ node_category.id ], area_ids: [ node_area.id ]
  end
  let(:index_path) { "#{page_idea.url}" }

  context "without login" do
    it do
      visit index_path
      expect(current_path).to eq index_path

      expect(page).to have_css("header .id", text: page_idea.id.to_s)
      expect(page).to have_css("header .name", text: page_idea.name)

      expect(page).to have_css("#idea-point .count, .label", text: "いいね！")
      expect(page).to have_css("#idea-point .count, .number", text: "1")

      expect(page).to have_css(".categories .category", text: node_category.name)
      expect(page).to have_css(".categories .area", text: node_area.name)
      expect(page).to have_css(".categories .tag", text: page_idea.tags[0])
      expect(page).to have_css(".categories .tag", text: page_idea.tags[1])

      expect(page).to have_css(".issue h2", text: '課題')
      expect(page).to have_css(".issue p", text: page_idea.issue.split("\n")[0])

      expect(page).to have_css(".idea h2", text: 'アイデア')
      expect(page).to have_css(".idea p", text: page_idea.text.split("\n")[0])

      expect(page).to have_css(".data h2", text: 'データ')
      expect(page).to have_css(".data p", text: page_idea.data.split("\n")[0])

      expect(page).to have_css(".note h2", text: '備考')
      expect(page).to have_css(".note p", text: page_idea.note.split("\n")[0])

      expect(page).to have_css(".idea-tabs .comment header h1", text: 'コメント')
      expect(page).to have_css(".idea-tabs .related-dataset header h1", text: '関連データセット')
      expect(page).to have_css(".idea-tabs .related-app header h1", text: '関連アプリ')

      expect(page).to have_css(".detail .info-wrap .author")
    end
  end

  context "when point is hide" do
    before do
      node_idea.show_point = 'hide'
      node_idea.save!

      page_idea.touch
      page_idea.save!
    end

    it do
      visit index_path

      expect(page).to have_css("header .id", text: page_idea.id.to_s)
      expect(page).to have_css("header .name", text: page_idea.name)

      expect(page).not_to have_css("#idea-point")

      expect(page).to have_css(".categories .category", text: node_category.name)
      expect(page).to have_css(".categories .area", text: node_area.name)
      expect(page).to have_css(".categories .tag", text: page_idea.tags[0])
      expect(page).to have_css(".categories .tag", text: page_idea.tags[1])

      expect(page).to have_css(".issue h2", text: '課題')
      expect(page).to have_css(".issue p", text: page_idea.issue.split("\n")[0])

      expect(page).to have_css(".idea h2", text: 'アイデア')
      expect(page).to have_css(".idea p", text: page_idea.text.split("\n")[0])

      expect(page).to have_css(".data h2", text: 'データ')
      expect(page).to have_css(".data p", text: page_idea.data.split("\n")[0])

      expect(page).to have_css(".note h2", text: '備考')
      expect(page).to have_css(".note p", text: page_idea.note.split("\n")[0])

      expect(page).to have_css(".idea-tabs .comment header h1", text: 'コメント')
      expect(page).to have_css(".idea-tabs .related-dataset header h1", text: '関連データセット')
      expect(page).to have_css(".idea-tabs .related-app header h1", text: '関連アプリ')

      expect(page).to have_css(".detail .info-wrap .author")
    end
  end

  context "when dataset and app is disabled" do
    before do
      site.dataset_state = 'disabled'
      site.app_state = 'disabled'
      site.save!

      page_idea.touch
      page_idea.save!
    end

    it do
      visit index_path

      expect(page).to have_css("header .id", text: page_idea.id.to_s)
      expect(page).to have_css("header .name", text: page_idea.name)

      expect(page).to have_css("#idea-point .count, .label", text: "いいね！")
      expect(page).to have_css("#idea-point .count, .number", text: "1")

      expect(page).to have_css(".categories .category", text: node_category.name)
      expect(page).to have_css(".categories .area", text: node_area.name)
      expect(page).to have_css(".categories .tag", text: page_idea.tags[0])
      expect(page).to have_css(".categories .tag", text: page_idea.tags[1])

      expect(page).to have_css(".issue h2", text: '課題')
      expect(page).to have_css(".issue p", text: page_idea.issue.split("\n")[0])

      expect(page).to have_css(".idea h2", text: 'アイデア')
      expect(page).to have_css(".idea p", text: page_idea.text.split("\n")[0])

      expect(page).to have_css(".data h2", text: 'データ')
      expect(page).to have_css(".data p", text: page_idea.data.split("\n")[0])

      expect(page).to have_css(".note h2", text: '備考')
      expect(page).to have_css(".note p", text: page_idea.note.split("\n")[0])

      expect(page).to have_css(".idea-tabs .comment header h1", text: 'コメント')
      expect(page).not_to have_css(".idea-tabs .related-dataset")
      expect(page).not_to have_css(".idea-tabs .related-app")

      expect(page).to have_css(".detail .info-wrap .author")
    end
  end
end
