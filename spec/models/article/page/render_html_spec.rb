require 'spec_helper'

describe Article::Page, dbscope: :example do
  let!(:site) { cms_site }
  let!(:admin) { cms_user }
  let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'entry', group_ids: admin.group_ids) }
  let!(:column) { create(:cms_column_free, cur_site: site, cur_form: form, required: "optional", order: 1) }
  let!(:node) { create(:article_node_page, cur_site: site, st_form_ids: [ form.id ]) }
  let(:html) do
    <<~HTML
      <p>hello-#{unique_id}</p>
    HTML
  end
  let(:params) do
    # controller の get_params を模したパラメータ
    {
      # post されたパラメータを先頭に
      name: "name-#{unique_id}",
      form_id: form.id,
      column_values: [
        { _id: BSON::ObjectId.new.to_s, _type: column.value_type.name, column_id: column.id, order: 0,
          in_wrap: { value: html } }
      ],
      # fix_params を末尾に
      cur_site: site,
      cur_user: admin,
      cur_node: node,
    }
  end

  context "when a page is new record" do
    it do
      page = Article::Page.new params
      rendered_html = page.render_html
      fragment = Nokogiri::HTML5.fragment(rendered_html)
      fragment.css("[data-type='#{column.value_type.name}']").tap do |column_elements|
        expect(column_elements).to have(1).items
        expect(column_elements.to_html).to include(html)
      end
    end
  end

  context "when a page is persisted" do
    let!(:page) do
      page = create(:article_page, cur_site: site, cur_user: admin, cur_node: node, form: form)
      Article::Page.find(page.id)
    end

    it do
      page.attributes = params
      rendered_html = page.render_html
      fragment = Nokogiri::HTML5.fragment(rendered_html)
      fragment.css("[data-type='#{column.value_type.name}']").tap do |column_elements|
        expect(column_elements).to have(1).items
        expect(column_elements.to_html).to include(html)
      end
    end
  end

  Cms::Part.plugins.map(&:path).each do |path|
    # opendata 機能は単体では動作せず、構成が大変
    next if path.start_with?("opendata/")
    # "ckan/reference" は opendata 機能と組み合わせて利用する必要があり、構成が大変
    next if path == "ckan/reference"

    # cms/layout や cms/form に組み込んだパーツをレンダリングできるかどうか確認する
    # エラーになる場合、書き出し時にエラーが発生したり、ページが使用するサイズを正しく計算できなかったりする
    context "when the part `#{path}` is integrated into cms/layout" do
      it do
        part = create(path.sub("/", "_part_").to_sym, cur_site: site)
        layout = create_cms_layout(part, cur_site: site)
        html = "html-#{unique_id}"
        page = create(:article_page, cur_site: site, cur_node: node, layout: layout, state: "public", html: html)
        page = Article::Page.find(page.id)
        rendered_html = page.render_html
        expect(rendered_html).to include(html)
      end
    end

    context "when the part `#{path}` is integrated into cms/form" do
      it do
        part = create(path.sub("/", "_part_").to_sym, cur_site: site)
        layout = create_cms_layout(cur_site: site)

        mark = "mark-#{unique_id}"
        html = <<~HTML
          <div>#{mark}</div>
          {{ parts["#{part.filename.sub(".part.html", "")}"].html }}
        HTML
        form = create(:cms_form, cur_site: site, state: 'public', sub_type: 'static', html: html)
        column = create(
          :cms_column_text_field, cur_site: site, cur_form: form, required: "optional", order: 10, input_type: 'text'
        )

        page = create(
          :article_page, cur_site: site, cur_node: node, layout: layout, form: form, state: "public",
          column_values: [ column.value_type.new(column: column, name: column.name, value: "text-#{unique_id}") ])
        page = Article::Page.find(page.id)
        rendered_html = page.render_html
        expect(rendered_html).to include(mark)
      end
    end
  end
end
