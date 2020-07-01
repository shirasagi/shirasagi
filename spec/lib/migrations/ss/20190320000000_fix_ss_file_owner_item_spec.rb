require 'spec_helper'
require Rails.root.join("lib/migrations/ss/20190320000000_fix_ss_file_owner_item.rb")

RSpec.describe SS::Migration20190320000000, dbscope: :example do
  # cms
  let!(:cms_form1) do
    create(:cms_form, cur_site: cms_site, state: 'public', sub_type: 'entry', group_ids: [cms_group.id])
  end
  let!(:cms_column1) do
    create(:cms_column_file_upload, cur_site: cms_site, cur_form: cms_form1, required: "optional", order: 1)
  end
  let!(:cms_column2) do
    create(:cms_column_free, cur_site: cms_site, cur_form: cms_form1, required: "optional", order: 2)
  end
  let!(:article_node) { create :article_node_page, cur_site: cms_site, st_form_ids: [cms_form1.id] }
  let!(:article_page1) { create :article_page, cur_site: cms_site, cur_node: article_node, cur_user: cms_user }
  let!(:article_page2) { create :article_page, cur_site: cms_site, cur_node: article_node, cur_user: cms_user }
  let!(:file1) { tmp_ss_file(user: cms_user, contents: "#{Rails.root}/spec/fixtures/ss/logo.png") }
  let!(:file2) { tmp_ss_file(user: cms_user, contents: "#{Rails.root}/spec/fixtures/ss/logo.png") }
  let!(:file3) { tmp_ss_file(user: cms_user, contents: "#{Rails.root}/spec/fixtures/ss/logo.png") }
  # gws
  let!(:gws_schedule_plan1) { create :gws_schedule_plan, cur_site: gws_site, cur_user: gws_user }
  let!(:gws_mem_message1) { create :gws_memo_message, cur_site: gws_site, cur_user: gws_user }
  let!(:file4) { tmp_ss_file(user: gws_user, contents: "#{Rails.root}/spec/fixtures/ss/logo.png") }
  let!(:file5) { tmp_ss_file(user: gws_user, contents: "#{Rails.root}/spec/fixtures/ss/logo.png") }

  before do
    article_page1.set(file_ids: [ file1.id ])

    article_page2.form = cms_form1
    article_page2.column_values = [
      cms_column1.value_type.new(column: cms_column1, file_id: file2.id, file_label: file2.humanized_name),
      cms_column2.value_type.new(column: cms_column2, value: unique_id * 2, file_ids: [ file3.id ])
    ]
    article_page2.save!
    file2.unset(:owner_item_id, :owner_item_type, :site_id)
    file3.unset(:owner_item_id, :owner_item_type, :site_id)

    gws_schedule_plan1.set(file_ids: [ file4.id ])

    # corrupted image file
    gws_mem_message1.set(file_ids: [ file5.id ])
    # replace image data with text
    ::File.open(file5.path, "wt") { |file| file.write unique_id }

    [ file1, file2, file3, file4, file5 ].each do |file|
      file.reload
    end
  end

  describe "#change" do
    it do
      [ file1, file2, file3, file4, file5 ].each do |file|
        expect(file.owner_item_id).to be_blank
        expect(file.owner_item_type).to be_blank
        expect(file.owner_item).to be_blank
        expect(file.site_id).to be_blank
      end

      described_class.new.change

      file1.reload
      expect(file1.owner_item_id).to eq article_page1.id
      expect(file1.owner_item_type).to eq article_page1.class.name
      expect(file1.owner_item).to be_present
      expect(file1.site_id).to be_blank
      expect(file1.thumb).to be_present

      file2.reload
      expect(file2.owner_item_id).to eq article_page2.id
      expect(file2.owner_item_type).to eq article_page2.class.name
      expect(file2.owner_item).to be_present
      expect(file2.site_id).to be_blank
      expect(file2.thumb).to be_present

      file3.reload
      expect(file3.owner_item_id).to eq article_page2.id
      expect(file3.owner_item_type).to eq article_page2.class.name
      expect(file3.owner_item).to be_present
      expect(file3.site_id).to be_blank
      expect(file3.thumb).to be_present

      file4.reload
      expect(file4.owner_item_id).to eq gws_schedule_plan1.id
      expect(file4.owner_item_type).to eq gws_schedule_plan1.class.name
      expect(file4.owner_item).to be_present
      expect(file4.site_id).to be_blank
      expect(file4.thumb).to be_present

      file5.reload
      expect(file5.owner_item_id).to eq gws_mem_message1.id
      expect(file5.owner_item_type).to eq gws_mem_message1.class.name
      expect(file5.owner_item).to be_present
      expect(file5.site_id).to eq gws_mem_message1.site.id
      # file5 has no thumbnail files because file5 is corrupted
      expect(file5.thumb).to be_blank
    end
  end
end
