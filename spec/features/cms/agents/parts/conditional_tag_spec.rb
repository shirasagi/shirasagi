# frozen_string_literal: true

require 'spec_helper'

describe Cms::PublicFilter::ConditionalTag, type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create :cms_node, filename: 'node', layout_id: layout.id }
  let!(:item) { create(:article_page, cur_site: site, cur_node: node, layout_id: layout.id) }

  context 'When upper_html have condition tags' do
    html = <<~HTML
      <div class="condition">
        \#{if is_page()}
          \#{page_name}
        \#{elsif is_node()}
          \#{parent_name}
        \#{else}
          <time>\#{page_released.long}</time>
        \#{end}
        </div>
        <div class="condition">
          \#{if is_page('dummy')}
            \#{parent_name}
          \#{end}
          \#{if in_node('node')}
            <p>in_node</p>
          \#{end}
          \#{if has_pages()}
            <p>has_pages</p>
          \#{end}
      </div>
    HTML
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
      html = <<~HTML
        <html><body><br><br><br>
        <div class="condition">
          \#{if is_page()}
            foo&#39;s manual
          \#{elsif is_node()}
            bar&#39;s manual
          \#{else}
            baz&#39;s manual
          \#{end}
        </div>
        </body></html>
      HTML
      layout.html = html
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
