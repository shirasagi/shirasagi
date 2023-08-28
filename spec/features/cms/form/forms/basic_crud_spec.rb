require 'spec_helper'

describe Cms::Form::FormsController, type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let(:name) { unique_id }
  let(:html) { unique_id }
  let(:html2) { unique_id }

  context 'basic crud' do
    before { login_cms_user }

    it do
      #
      # Create
      #
      visit cms_forms_path(site)

      click_on I18n.t('ss.links.new')
      within 'form#item-form' do
        fill_in 'item[name]', with: name
        fill_in_code_mirror 'item[html]', with: html
        click_on I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      expect(Cms::Form.site(site).count).to eq 1
      Cms::Form.site(site).first.tap do |item|
        expect(item.name).to eq name
        expect(item.html).to eq html
      end

      #
      # Read & Update
      #
      visit cms_forms_path(site)
      click_on name
      click_on I18n.t('ss.links.edit')
      within 'form#item-form' do
        fill_in_code_mirror 'item[html]', with: html2
        click_on I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      expect(Cms::Form.site(site).count).to eq 1
      Cms::Form.site(site).first.tap do |item|
        expect(item.name).to eq name
        expect(item.html).to eq html2
      end

      #
      # Delete
      #
      visit cms_forms_path(site)
      click_on name
      click_on I18n.t('ss.links.delete')
      within 'form' do
        click_on I18n.t('ss.buttons.delete')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
      expect(Cms::Form.site(site).count).to eq 0
    end

    it do
      # import
      visit import_cms_forms_path(site: site.id)
      within "form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/cms/form/cms_forms_1656954898.json"
        page.accept_confirm { click_on I18n.t("ss.buttons.import") }
      end
      expect(page).to have_content I18n.t("ss.notice.imported")
      expect(Cms::Form.site(site).all.size).to eq 2
      expect(Cms::Column::Base.site(site).all.size).to eq 12

      # download 1 form
      visit cms_forms_path(site: site.id)
      wait_for_js_ready
      within "#main .index" do
        find("input[name='ids[]']", match: :first).set(true) #choose
        find(".btn-list-head-action.download").click
      end
      wait_for_download

      json = JSON.parse(File.read(downloads.first))
      expect(json.size).to eq 1
      expect(json.present?).to be_truthy

      File.delete(downloads.first)

      # download all forms
      visit cms_forms_path(site: site.id)
      within ".nav-menu" do
        click_on I18n.t("ss.links.download")
      end
      wait_for_download

      json = JSON.parse(File.read(downloads.first))
      expect(json.size).to eq 2
      expect(json.present?).to be_truthy
    end
  end
end
