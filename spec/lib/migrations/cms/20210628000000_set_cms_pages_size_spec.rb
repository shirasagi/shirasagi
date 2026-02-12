require 'spec_helper'
require Rails.root.join("lib/migrations/cms/20210628000000_set_cms_pages_size.rb")

RSpec.describe SS::Migration20210628000000, dbscope: :example do
  context "with html page" do
    let!(:site) { cms_site }
    let!(:user) { cms_user }
    let(:html) { unique_id }
    let!(:page) { create :cms_page, cur_site: site, cur_user: user, html: html }

    before do
      page.unset(:size)
      described_class.new.change
    end

    it do
      page.reload
      expect(page.size).to eq html.bytesize
    end
  end

  context "with html and file" do
    let!(:site) { cms_site }
    let!(:user) { cms_user }
    let!(:file) { tmp_ss_file(site: site, user: user, contents: "#{Rails.root}/spec/fixtures/ss/logo.png") }
    let(:html) { unique_id }
    let!(:page) { create :cms_page, cur_site: site, cur_user: user, html: html, file_ids: [ file.id ] }

    before do
      page.unset(:size)
      described_class.new.change
    end

    it do
      page.reload
      expect(page.size).to eq html.bytesize + file.size
    end
  end

  context "with form page" do
    let!(:site) { cms_site }
    let!(:user) { cms_user }
    let!(:file) { tmp_ss_file(site: site, user: user, contents: "#{Rails.root}/spec/fixtures/ss/logo.png") }
    let!(:node) { create :article_node_page, cur_site: site, cur_user: user }

    let!(:form) { create :cms_form, cur_site: site, state: 'public', sub_type: 'entry', html: nil }
    let!(:column1) do
      create(:cms_column_text_field, cur_site: site, name: "column1", cur_form: form, required: "optional", order: 1)
    end
    let!(:column2) do
      create(:cms_column_free, cur_site: site, name: "column2", cur_form: form, required: "optional", order: 2)
    end
    let!(:page) do
      page = create(
        :article_page, cur_site: site, cur_user: user, cur_node: node, form: form,
        column_values: [
          column1.value_type.new(column: column1, value: "value1"),
          column2.value_type.new(column: column2, value: "value2", file_ids: [ file.id ])
        ])
      # page はメンバー変数などで汚染されている；まっさらなページを取得して操作する。
      Article::Page.find(page.id)
    end
    let(:rendered_html) do
      page.render_html
    end

    it "unset size and migration" do
      expect(rendered_html.length).to be > 100

      page.unset(:size)
      described_class.new.change

      Article::Page.find(page.id).tap do |page_after_migration|
        expect(page_after_migration.size).to eq rendered_html.bytesize + file.size
      end
    end

    it "when site removed" do
      expect(rendered_html.length).to be > 100

      page.set(size: 50)
      site.destroy

      # Run migration
      described_class.new.change

      Article::Page.find(page.id).tap do |page_after_migration|
        # size is unable to update because site was deleted
        expect(page_after_migration.size).to eq 50
      end
    end
  end
end
