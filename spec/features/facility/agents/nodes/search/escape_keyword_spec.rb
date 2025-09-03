require 'spec_helper'

describe "facility_agents_nodes_search", type: :feature, dbscope: :example, js: true do
  let!(:layout) { create_cms_layout }
  let!(:node) { create :facility_node_search, layout: layout }
  let!(:item) { create :facility_node_page, cur_node: node }

  let!(:category_ids_query) { "category_ids%5B%5D=%22%3E%3Cscript%3Ealert%281%29%3C%2Fscript%3E" }
  let!(:keyword_query) { "keyword=%3C%2Fscript%3E%27%22%3E%3Cimg+src%3Dx+onError%3Dprompt%281%29%3E" }
  let!(:illegal_index_path) do
    "#{node.url}index.html?#{category_ids_query}&#{keyword_query}"
  end
  let!(:illegal_result_path) do
    "#{node.url}result.html?#{category_ids_query}&#{keyword_query}"
  end
  let!(:illegal_map_path) do
    "#{node.url}map.html?#{category_ids_query}&#{keyword_query}"
  end
  let!(:illegal_map_all_path) do
    "#{node.url}map-all.html?#{category_ids_query}&#{keyword_query}"
  end
  let!(:escaped_keyword) { '</script>\'"><img src=x onError=prompt(1)>' }

  context "default case" do
    it "#index" do
      visit illegal_index_path
      expect(first("input[name=\"keyword\"]")["value"]).to eq escaped_keyword
    end

    it "#result" do
      visit illegal_result_path
      within ".condition" do
        expect(page).to have_css("dd", text: escaped_keyword)
      end
    end

    it "#map" do
      visit illegal_map_path
      within ".condition" do
        expect(page).to have_css("dd", text: escaped_keyword)
      end
    end

    it "#map_all" do
      visit illegal_map_all_path
      expect(page).to have_no_css("dd", text: escaped_keyword)
    end
  end

  context "with custom html" do
    let(:search_html) do
      h = []
      h << '<fieldset>'
      h << '<legend>キーワード</legend>'
      h << '#{keyword}'
      h << '</fieldset>'
      h << '<legend>施設の種類を選択</legend>'
      h << '#{category}'
      h << '<legend>施設の地域を選択</legend>'
      h << '#{location}'
      h.join("\n")
    end
    let(:upper_html) do
      h = []
      h << '<dl class="condition">'
      h << '<dt class="keyword">キーワード</dt>'
      h << '<dd>#{keyword}</dd>'
      h << '<dt class="category">種類</dt>'
      h << '<dd>#{category}</dd>'
      h << '<dt class="location">地域</dt>'
      h << '<dd>#{location}</dd>'
      h << '</dl>'
      h << '#{settings}'
      h << '<section class="result">'
      h << '<h2>検索結果<span class="number">#{number}</span>件</h2>'
      h << '</section>'
      h << '#{tabs}'
      h.join("\n")
    end
    let(:map_html) do
      h = []
      h << '<div>#{sidebar}</div>'
      h << '<div>#{canvas}</div>'
      h << '<div>#{filters}</div>'
      h.join("\n")
    end

    before do
      node.search_html = search_html
      node.upper_html = upper_html
      node.map_html = map_html
      node.update!
    end

    it "#index" do
      visit illegal_index_path
      expect(first("input[name=\"keyword\"]")["value"]).to eq escaped_keyword
    end

    it "#result" do
      visit illegal_result_path
      within ".condition" do
        expect(page).to have_css("dd", text: escaped_keyword)
      end
    end

    it "#map" do
      visit illegal_map_path
      within ".condition" do
        expect(page).to have_css("dd", text: escaped_keyword)
      end
    end

    it "#map_all" do
      visit illegal_map_all_path
      expect(page).to have_no_css("dd", text: escaped_keyword)
    end
  end
end
