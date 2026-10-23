require 'spec_helper'

describe "ads_agents_parts_banner", type: :feature, dbscope: :example, js: true do
  let(:site)  { cms_site }
  let(:node)  { create :ads_node_banner, cur_site: site }
  let!(:layout)   { create_cms_layout part, cur_site: site }
  let!(:node_cms) { create :cms_node, cur_site: site, layout: layout }

  context "vulnerability in Ads::Banner#link_target" do
    let(:vulnerable_link_target) do
      %(_self" onclick="window.xss=1; console.log('xss'); return false;)
    end
    let(:vulnerable_link_url) do
      %(/x" onclick="window.xss=1; console.log('xss'); return false;)
    end
    let!(:item1) do
      create :ads_banner, cur_site: site, cur_node: node, link_url: vulnerable_link_url
    end

    before do
      item1.set(link_target: vulnerable_link_target)
    end

    context "with default loop format" do
      let!(:part) { create :ads_part_banner, cur_site: site, cur_node: node, link_target: nil }

      it do
        visit node_cms.full_url
        wait_for_js_ready

        first(".ss-image-box-item a").click

        expect(page.evaluate_script("window.xss")).to be_blank

        logs = capture_console_logs
        expect(logs).not_to include(include("xss"))
      end
    end

    context "with shirasagi loop format" do
      let!(:part) do
        upper_html = <<~HTML
          <div class="ss-image-box-item-list">
        HTML
        lower_html = <<~HTML
          </div>
        HTML
        loop_html = <<~HTML
          <span class="ss-image-box-item loop-html" data-id="\#{id}">
            <a target="\#{link_target}" href="\#{link_url}">
              <img src="\#{img.src}" alt="\#{name}">
            </a>
          </span>
        HTML
        create(
          :ads_part_banner, cur_site: site, cur_node: node, loop_format: "shirasagi",
          upper_html: upper_html, loop_html: loop_html, lower_html: lower_html)
      end

      it do
        visit node_cms.full_url
        wait_for_js_ready

        first(".ss-image-box-item a").click

        expect(page.evaluate_script("window.xss")).to be_blank

        logs = capture_console_logs
        expect(logs).not_to include(include("xss"))
      end
    end

    context "with liquid loop format" do
      let!(:part) do
        loop_liquid = <<~HTML
          <div class="ss-image-box-item-list">
            {% for page in pages %}
            <span class="ss-image-box-item loop-html" data-id="{{ page.id }}">
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

      it do
        visit node_cms.full_url
        wait_for_js_ready

        first(".ss-image-box-item a").click

        expect(page.evaluate_script("window.xss")).to be_blank

        logs = capture_console_logs
        expect(logs).not_to include(include("xss"))
      end
    end
  end
end
