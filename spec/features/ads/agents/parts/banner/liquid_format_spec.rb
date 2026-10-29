require 'spec_helper'

describe "ads_agents_parts_banner", type: :feature, dbscope: :example, js: true do
  let!(:site)  { cms_site }
  let!(:node)  { create :ads_node_banner, cur_site: site }
  let!(:part) do
    loop_liquid = <<~HTML
      <div class="ss-image-box-item-list">
        {% for page in pages %}
        <span class="ss-image-box-item loop-html" data-id="{{ page.id }}" data-tag="{{ page.tags | join: " " | escape }}">
          <a target="{{ part.link_target | default: page.link_target | default: "_self" | escape }}" href="{{ page.link_url | escape }}">
            {% if page.file %}
              <img src="{{ page.file.url | escape }}" alt="{{ page.name | escape }}">
            {% else %}
              {{ page.name | escape }}
            {% endif %}
          </a>
        </span>
        {% endfor %}
      </div>
    HTML
    create(
      :ads_part_banner, cur_site: site, cur_node: node, loop_format: "liquid",
      loop_liquid: loop_liquid)
  end

  let!(:layout)   { create_cms_layout part, cur_site: site }
  let!(:node_cms) { create :cms_node, cur_site: site, layout: layout }

  context "public" do
    let!(:item1) do
      create(
        :ads_banner, cur_site: site, cur_node: node, link_url: unique_url, link_target: %w(_self _blank).sample,
        tags: %w(tag0 tag1))
    end
    let!(:item2) do
      create(
        :ads_banner, cur_site: site, cur_node: node, link_url: unique_url, link_target: %w(_self _blank).sample,
        tags: %w(tag0 tag2))
    end

    it do
      visit node_cms.full_url
      expect(page).to have_css(".ss-image-box")
      expect(page).to have_selector(".ss-image-box-item[data-tag~='tag0']", count: 2)
      expect(page).to have_selector(".ss-image-box-item[data-tag~='tag1']", count: 1)
      expect(page).to have_selector(".ss-image-box-item[data-tag~='tag2']", count: 1)
      expect(page).to have_css(".ss-image-box-item.loop-html[data-id]", count: 2)
      within ".ss-image-box-item[data-id='#{item1.id}']" do
        expect(page).to have_css("a[href='#{item1.link_url}'][target='#{item1.link_target}']")
        expect(page).to have_css("img[src='#{item1.file.url}']")
      end
      within ".ss-image-box-item[data-id='#{item2.id}']" do
        expect(page).to have_css("a[href='#{item2.link_url}'][target='#{item2.link_target}']")
        expect(page).to have_css("img[src='#{item2.file.url}']")
      end
    end
  end
end
