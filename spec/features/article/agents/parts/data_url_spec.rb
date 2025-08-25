require 'spec_helper'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:layout1) { create_cms_layout cur_site: site }
  let!(:article_node) { create :article_node_page, cur_site: site, layout: layout1 }
  let!(:category_node) { create :category_node_page, cur_site: site, layout: layout1 }
  let!(:article_page) do
    html = <<~HTML
      <p><img src="data:image/gif;base64,R0lGODlhAQABAIAAAAAAAAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw%3D%3D" /></p>
    HTML
    create(
      :article_page, cur_site: site, cur_node: article_node, layout: layout1,
      html: html, category_ids: [ category_node.id ])
  end
  let!(:article_part) do
    loop_html = <<~HTML
      <ul class="list">
        {% for page in pages %}
        <li class="list-item" data-id="{{ page.id }}" data-filename="{{ page.filename }}">
          <a class="list-item-link" href="{{ page.url }}">
            {% assign img_src = page.html | ss_img_src | expand_path: page.parent.url -%}
            <img src="{{ page.thumb.url | default: img_src }}" alt="{{ page.index_name | default: page.name }}">
          </a>
        </li>
        {% endfor %}
      </ul>
    HTML
    create(:article_part_page, cur_site: site, cur_node: category_node, loop_format: "liquid", loop_liquid: loop_html)
  end

  let!(:layout2) { create_cms_layout article_part, cur_site: site }
  let!(:top_page) do
    create :cms_page, cur_site: site, layout: layout2
  end

  before do
    ::FileUtils.rm_f(article_page.path)
    ::FileUtils.rm_f(top_page.path)
  end

  it do
    visit top_page.full_url
    within "[data-id='#{article_page.id}']" do
      expect(first("img")["src"]).to be_start_with "data:image/gif;base64,"
    end
  end
end
