require 'spec_helper'
require Rails.root.join("lib/migrations/cms/20200521000000_recover_missing_attachments.rb")

RSpec.describe SS::Migration20200521000000, dbscope: :example do
  describe ".each_file_id" do
    let(:html) do
      html = []
      html << "<p><a class=\"icon-jpg\" href=\"/fs/3/7/1/_/cat0098-066.jpg\">cat0098-066.jpg (JPG 867KB)</a></p>"
      html << "<p><img alt=\"cat0098-066.jpg\" src=\"/fs/3/7/2/_/cat0098-066.jpg\" /></p>"
      html << "<p><a alt=\"cat0098-066.jpg\" class=\"ajax-box\" href=\"/fs/3/7/3/_/cat0098-066.jpg\">"
      html << "  <img alt=\"cat0098-066.jpg\" src=\"/fs/3/7/4/_/thumb/cat0098-066.jpg\" />"
      html << "</a></p>"
      html.join("\n")
    end

    it do
      ids = []
      described_class.each_file_id(html) do |id|
        ids << id
      end

      expect(ids.length).to eq 4
      expect(ids).to include(371, 372, 373, 374)
    end
  end

  describe "#change" do
    let!(:site) { cms_site }
    let!(:user1) { create :cms_user, name: unique_id, group_ids: cms_user.group_ids, cms_role_ids: cms_user.cms_role_ids }
    let!(:user2) { create :cms_user, name: unique_id, group_ids: cms_user.group_ids, cms_role_ids: cms_user.cms_role_ids }

    # page1_file2 is missing file
    let!(:page1_file1) { tmp_ss_file(user: user1, site: site, contents: "#{Rails.root}/spec/fixtures/ss/logo.png") }
    let!(:page1_file2) { tmp_ss_file(user: user2, site: site, contents: "#{Rails.root}/spec/fixtures/ss/logo.png") }
    let!(:node) { create(:article_node_page, cur_user: user1, cur_site: site) }
    let!(:page1) do
      html = []
      html << "<p><a class=\"icon-jpg\" href=\"#{page1_file1.url}\">#{page1_file1.humanized_name}</a></p>"
      html << "<p><a class=\"icon-jpg\" href=\"#{page1_file2.url}\">#{page1_file2.humanized_name}</a></p>"

      create(:article_page, cur_user: user1, cur_site: site, cur_node: node, html: html.join, file_ids: [ page1_file1.id ])
    end

    let!(:page2_file1) { tmp_ss_file(user: user1, site: site, contents: "#{Rails.root}/spec/fixtures/ss/logo.png") }
    let!(:page2_file2) { tmp_ss_file(user: user2, site: site, contents: "#{Rails.root}/spec/fixtures/ss/logo.png") }
    let!(:page2) do
      html = []
      html << "<p><a class=\"icon-jpg\" href=\"#{page2_file1.url}\">#{page2_file1.humanized_name}</a></p>"
      html << "<p><a class=\"icon-jpg\" href=\"#{page2_file2.url}\">#{page2_file2.humanized_name}</a></p>"

      create(:cms_page, cur_user: user1, cur_site: site, html: html.join, file_ids: [ page2_file1.id ])
    end

    let!(:page3_file1) { tmp_ss_file(user: user1, site: site, contents: "#{Rails.root}/spec/fixtures/ss/logo.png") }
    let!(:page3_file2) { tmp_ss_file(user: user2, site: site, contents: "#{Rails.root}/spec/fixtures/ss/logo.png") }
    let!(:page3) do
      form = create(:cms_form, cur_site: site, state: 'public', sub_type: 'entry', group_ids: user1.group_ids)
      column = create(:cms_column_free, cur_site: site, cur_form: form, required: "optional", order: 1)
      page = create(:article_page, cur_user: user1, cur_site: site, cur_node: node)

      html = []
      html << "<p><a class=\"icon-jpg\" href=\"#{page3_file1.url}\">#{page3_file1.humanized_name}</a></p>"
      html << "<p><a class=\"icon-jpg\" href=\"#{page3_file2.url}\">#{page3_file2.humanized_name}</a></p>"

      page.form = form
      page.column_values = [
        column.value_type.new(column: column, value: nil, file_ids: nil), # blank free column
        column.value_type.new(column: column, value: html.join, file_ids: [ page3_file1.id ])
      ]
      page.save!

      page
    end

    before do
      page1.reload
      expect(page1.file_ids.length).to eq 1

      page1_file1.reload
      expect(page1_file1.owner_item.id).to eq page1.id
      expect(page1_file1.model).to eq page1.class.model_name.i18n_key.to_s

      page1_file2.reload
      expect(page1_file2.owner_item).to be_blank
      expect(page1_file2.model).to eq "ss/temp_file"

      page2_file2.reload
      expect(page2_file2.owner_item).to be_blank
      expect(page2_file2.model).to eq "ss/temp_file"

      page3_file2.reload
      expect(page3_file2.owner_item).to be_blank
      expect(page3_file2.model).to eq "ss/temp_file"

      described_class.new.change
    end

    it do
      page1.reload
      expect(page1.file_ids.length).to eq 2

      page1_file2.reload
      expect(page1_file2.owner_item.id).to eq page1.id
      expect(page1_file2.model).to eq page1.class.model_name.i18n_key.to_s

      page2.reload
      expect(page2.file_ids.length).to eq 2

      page2_file2.reload
      expect(page2_file2.owner_item.id).to eq page2.id
      expect(page2_file2.model).to eq page2.class.model_name.i18n_key.to_s

      page3.reload
      expect(page3.column_values.length).to eq 2
      expect(page3.column_values.exists(value: true).first.file_ids.length).to eq 2

      page3_file2.reload
      expect(page3_file2.owner_item.id).to eq page3.id
      expect(page3_file2.model).to eq page3.class.name
    end
  end
end
