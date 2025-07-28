require 'spec_helper'

describe Cms::PublicFilter::ConditionalTag, type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create :cms_node, filename: 'node', layout_id: layout.id }
  let!(:item) { create(:article_page, cur_site: site, cur_node: node, layout_id: layout.id) }

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
    html << '<div class="condition">'
    html << '#{if is_page(\'dummy\')}'
    html << '#{parent_name}'
    html << '#{end}'
    html << "\#{if in_node('node')}"
    html << '<p>in_node</p>'
    html << '#{end}'
    html << "\#{if has_pages()}"
    html << '<p>has_pages</p>'
    html << '#{end}'
    html << '</div>'
    let(:part) { create :cms_part_page, upper_html: html }
    let(:layout) { create_cms_layout [part] }

    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it do
      visit item.url
      expect(status_code).to eq 200
      expect(page).to have_css('div.condition', text: item.name)
      expect(page).to have_no_css('div.condition', text: node.name)
      expect(page).to have_no_css('div.condition time')
      expect(page).to have_css('p', text: 'in_node')
      expect(page).to have_no_css('p', text: 'has_pages')
    end

    it do
      visit node.url
      expect(status_code).to eq 200
      expect(page).to have_no_css('div.condition', text: item.name)
      expect(page).to have_css('div.condition', text: node.name)
      expect(page).to have_no_css('div.condition time')
      expect(page).to have_css('p', text: 'in_node')
      expect(page).to have_css('p', text: 'has_pages')
    end
  end

  context 'When content has apostrophes' do
    let(:layout) { create_cms_layout }

    before do
      html = []
      html << '<html><body><br><br><br>'
      html << '<div class="condition">'
      html << '#{if is_page()}'
      html << ' foo&#39;s manual'
      html << '#{elsif is_node()}'
      html << ' bar&#39;s manual'
      html << '#{else}'
      html << ' baz&#39;s manual'
      html << '#{end}'
      html << '</div>'
      html << '</body></html>'

      layout.html = html.join("\n")
      layout.save!
      FileUtils.rm_f(item.path)
    end

    it do
      visit item.full_url
      expect(status_code).to eq 200
      expect(page).to have_css('div.condition', text: "foo's manual")
      expect(page).to have_no_content("\#{if is_page()}")
      expect(page).to have_no_content("\#{elsif is_node()}")
      expect(page).to have_no_content("\#{end}")
      expect(page).to have_no_content("bar's manual")
      expect(page).to have_no_content("baz's manual")
    end

    it do
      visit node.full_url
      expect(status_code).to eq 200
      expect(page).to have_css('div.condition', text: "bar's manual")
      expect(page).to have_no_content("\#{if is_page()}")
      expect(page).to have_no_content("\#{elsif is_node()}")
      expect(page).to have_no_content("\#{end}")
      expect(page).to have_no_content("foo's manual")
      expect(page).to have_no_content("baz's manual")
    end
  end
end
