require 'spec_helper'

describe "gws_workflow_files", type: :feature, dbscope: :example do
  context "basic crud", js: true do
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
      click_link I18n.t('ss.links.new')
      within "form#item-form" do
        fill_in "item[name]", with: item_name
        fill_in "item[text]", with: item_text
        click_on I18n.t("ss.buttons.upload")
      end
      wait_for_cbox do
        within "article.file-view" do
          click_on file.name
        end
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.save")
      end

      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      expect(Gws::Workflow::File.site(site).count).to eq 1
      item = Gws::Workflow::File.site(site).first
      expect(item.name).to eq item_name
      expect(item.text).to eq item_text
      expect(item.files.count).to eq 1
      expect(item.files.first.id).to eq file.id

      #
      # Update
      #
      click_on I18n.t('ss.links.edit')
      within "form#item-form" do
        fill_in "item[name]", with: item_name2
        fill_in "item[text]", with: item_text2
        click_on I18n.t("ss.buttons.save")
      end

      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      expect(Gws::Workflow::File.site(site).count).to eq 1
      item = Gws::Workflow::File.site(site).first
      expect(item.name).to eq item_name2
      expect(item.text).to eq item_text2
      expect(item.files.count).to eq 1
      expect(item.files.first.id).to eq file.id

      #
      # Soft Delete
      #
      click_on I18n.t('ss.links.delete')
      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end

      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
      expect(Gws::Workflow::File.site(site).count).to eq 1
      Gws::Workflow::File.site(site).first.tap do |workflow|
        expect(workflow.deleted).not_to be_nil
      end
    end
  end
end
