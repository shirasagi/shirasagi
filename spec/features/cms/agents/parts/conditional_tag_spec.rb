require 'spec_helper'

describe Cms::PublicFilter::ConditionalTag, type: :feature, dbscope: :example do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout [part] }
  let(:node)   { create :cms_node, layout_id: layout.id }
  let(:item) { create(:article_page, cur_site: site, cur_node: node, layout_id: layout.id) }

  context 'When upper_html have condition tags' do
    html = ''
    html << '<div class="condition">'
    html << '#{if is_page()}'
    html << '#{page_name}'
    html << '#{elsif is_node()}'
    html << '#{parent_name}'
    html << '#{else}'
    html << '<time>#{page_released.long}</time>'
    html << '#{end}'
    html << '</div>'
    let(:part) { create :cms_part_page, upper_html: html }

    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it do
      visit item.url
      expect(status_code).to eq 200
      expect(page).to have_css('div.condition', text: item.name)
      expect(page).to have_no_css('div.condition', text: node.name)
      expect(page).to have_no_css('div.condition time')
    end

    it do
      visit node.url
      expect(status_code).to eq 200
      expect(page).to have_no_css('div.condition', text: item.name)
      expect(page).to have_css('div.condition', text: node.name)
      expect(page).to have_no_css('div.condition time')
    end
  end
end
