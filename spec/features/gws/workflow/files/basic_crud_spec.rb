require 'spec_helper'

describe "gws_workflow_files", type: :feature, dbscope: :example, js: true do
  context "basic crud" do
    let(:site) { gws_site }
    let(:user) { gws_user }
    let(:index_path) { gws_workflow_files_path(site, state: 'all') }
    let!(:file) { tmp_ss_file(contents: '0123456789', user: user) }
    let(:item_name) { unique_id }
    let(:item_text) { unique_id }
    let(:item_name2) { unique_id }
    let(:item_text2) { unique_id }

    before { login_gws_user }

    it do
      visit index_path

      #
      # Create
      #
      within ".nav-menu" do
        click_link I18n.t('ss.links.new')
      end
      within "form#item-form" do
        fill_in "item[name]", with: item_name
        fill_in "item[text]", with: item_text
        wait_cbox_open do
          click_on I18n.t("ss.buttons.upload")
        end
      end
      within_cbox do
        within "article.file-view" do
          wait_cbox_close do
            click_on file.name
          end
        end
      end
      within "form#item-form" do
        expect(page).to have_content(file.name)
        click_on I18n.t("ss.buttons.save")
      end

      wait_for_notice I18n.t('ss.notice.saved')
      expect(Gws::Workflow::File.site(site).count).to eq 1
      item = Gws::Workflow::File.site(site).first
      expect(item.name).to eq item_name
      expect(item.text).to eq item_text
      expect(item.files.count).to eq 1
      item.files.first.tap do |item_file|
        expect(item_file.id).to eq file.id
        expect(item_file.site_id).to be_blank
        expect(item_file.model).to eq "gws/workflow/file"
        expect(item_file.owner_item_id).to eq item.id
        expect(item_file.owner_item_type).to eq item.class.name
      end

      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

      #
      # Update
      #
      within ".nav-menu" do
        click_on I18n.t('ss.links.edit')
      end
      within "form#item-form" do
        fill_in "item[name]", with: item_name2
        fill_in "item[text]", with: item_text2
        click_on I18n.t("ss.buttons.save")
      end

      wait_for_notice I18n.t('ss.notice.saved')
      expect(Gws::Workflow::File.site(site).count).to eq 1
      item = Gws::Workflow::File.site(site).first
      expect(item.name).to eq item_name2
      expect(item.text).to eq item_text2
      expect(item.files.count).to eq 1
      item.files.first.tap do |item_file|
        expect(item_file.id).to eq file.id
        expect(item_file.site_id).to be_blank
        expect(item_file.model).to eq "gws/workflow/file"
        expect(item_file.owner_item_id).to eq item.id
        expect(item_file.owner_item_type).to eq item.class.name
      end

      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

      #
      # Soft Delete
      #
      within ".nav-menu" do
        click_on I18n.t('ss.links.delete')
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.delete")
      end

      wait_for_notice I18n.t('ss.notice.deleted')
      expect(Gws::Workflow::File.site(site).count).to eq 1
      Gws::Workflow::File.site(site).first.tap do |workflow|
        expect(workflow.deleted).not_to be_nil
      end
    end
  end
end
