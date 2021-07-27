require 'spec_helper'
require Rails.root.join("lib/migrations/cms/20210628000000_set_cms_pages_size.rb")

RSpec.describe SS::Migration20210628000000, dbscope: :example do
  context "with html page" do
    let(:page) { create :cms_page }
    let(:html) { unique_id }

    before do
      page.set(html: html)
      described_class.new.change
    end

    it do
      page.reload
      expect(page.size).to eq html.bytesize
    end
  end

  context "with form page" do
    let(:site) { cms_site }
    let(:node) { create :article_node_page, cur_site: site }

    let(:form) { create :cms_form, cur_site: site, state: 'public', sub_type: 'entry', html: nil }
    let(:page) { create :article_page, cur_site: site, cur_node: node, form: form }
    let(:column1) do
      create(:cms_column_text_field, cur_site: site, name: "column1", cur_form: form, required: "optional", order: 1)
    end
    let(:column2) do
      create(:cms_column_text_field, cur_site: site, name: "column2", cur_form: form, required: "optional", order: 2)
    end
    let(:column_values) do
      [
        column1.value_type.new(column: column1, value: "value1"),
        column2.value_type.new(column: column2, value: "value2")
      ]
    end
    let(:rendered_html) do
      '<div class="ss-alignment ss-alignment-flow">value1</div><div class="ss-alignment ss-alignment-flow">value2</div>'
    end

    it "unset size and migration" do
      page.column_values = column_values
      page.save!
      page.reload

      expect(page.render_html).to eq rendered_html
      expect(page.size).to eq rendered_html.bytesize

      page.unset(:size)
      described_class.new.change

      page.reload
      expect(page.render_html).to eq rendered_html
      expect(page.size).to eq rendered_html.bytesize
    end

    it "when site removed" do
      page.column_values = column_values
      page.save!
      page.reload

      expect(page.render_html).to eq rendered_html
      expect(page.size).to eq rendered_html.bytesize

      page.unset(:size)
      site.destroy
      described_class.new.change

      page.reload
      expect(page.render_html).to eq nil
      expect(page.size).to eq nil
    end
  end
end
