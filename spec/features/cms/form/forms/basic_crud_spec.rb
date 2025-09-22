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
      wait_for_notice I18n.t('ss.notice.saved')
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
      wait_for_notice I18n.t('ss.notice.saved')
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
      wait_for_notice I18n.t('ss.notice.deleted')
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

  context 'layout html functionality' do
    let!(:liquid_setting) do
      create(:cms_loop_setting,
        site: site,
        html_format: "liquid",
        html: "{% for item in items %}<div class='loop-item'>{{ item.name }}</div>{% endfor %}",
        state: "public",
        name: "Test Liquid Setting #{unique_id}"
      )
    end

    before { login_cms_user }

    it 'can create form with layout html and loop setting' do
      visit cms_forms_path(site)
      click_on I18n.t('ss.links.new')

      within 'form#item-form' do
        fill_in 'item[name]', with: name
        fill_in_code_mirror 'item[html]', with: html

        # Select loop setting
        select liquid_setting.name, from: 'item[loop_setting_id]'

        click_on I18n.t('ss.buttons.save')
      end

      wait_for_notice I18n.t('ss.notice.saved')

      form = Cms::Form.site(site).where(name: name).first
      expect(form).to be_present
      expect(form.html).to eq html
      expect(form.loop_setting_id).to eq liquid_setting.id
    end

    it 'preserves directly entered HTML when loop_setting_id is set' do
      custom_html = "<div class='custom-form'>{% for item in items %}<div class='custom-item'>{{ item.name }}</div>{% endfor %}</div>"

      visit cms_forms_path(site)
      click_on I18n.t('ss.links.new')

      within 'form#item-form' do
        fill_in 'item[name]', with: name
        fill_in_code_mirror 'item[html]', with: custom_html

        # Select loop setting
        select liquid_setting.name, from: 'item[loop_setting_id]'

        click_on I18n.t('ss.buttons.save')
      end

      wait_for_notice I18n.t('ss.notice.saved')

      form = Cms::Form.site(site).where(name: name).first
      expect(form).to be_present
      expect(form.html).to eq custom_html
      expect(form.loop_setting_id).to eq liquid_setting.id

      # Verify that the custom HTML is preserved, not overwritten by loop_setting.html
      expect(form.html).to include("custom-form")
      expect(form.html).to include("custom-item")
      expect(form.html).not_to include("loop-item") # from loop_setting.html
    end

    it 'can edit form and change loop setting' do
      # Create form first
      form = create(:cms_form, cur_site: site, name: name, html: html)

      visit edit_cms_form_path(site: site.id, id: form.id)

      # Wait for the page to load and check if fields exist
      expect(page).to have_select('item[loop_setting_id]')
      expect(page).to have_field('item[html]')

      within 'form#item-form' do
        # Change loop setting
        select liquid_setting.name, from: 'item[loop_setting_id]'

        # Modify HTML
        fill_in_code_mirror 'item[html]', with: html2

        click_on I18n.t('ss.buttons.save')
      end

      wait_for_notice I18n.t('ss.notice.saved')

      form.reload
      expect(form.html).to eq html2
      expect(form.loop_setting_id).to eq liquid_setting.id
    end

    it 'can remove loop setting and keep custom HTML' do
      # Create form with loop setting
      form = create(:cms_form, cur_site: site, name: name, html: html, loop_setting_id: liquid_setting.id)

      visit edit_cms_form_path(site: site.id, id: form.id)

      # Wait for the page to load and check if fields exist
      expect(page).to have_select('item[loop_setting_id]')
      expect(page).to have_field('item[html]')

      within 'form#item-form' do
        # Remove loop setting
        select I18n.t('cms.input_directly'), from: 'item[loop_setting_id]'

        # Modify HTML
        fill_in_code_mirror 'item[html]', with: html2

        click_on I18n.t('ss.buttons.save')
      end

      wait_for_notice I18n.t('ss.notice.saved')

      form.reload
      expect(form.html).to eq html2
      expect(form.loop_setting_id).to be_nil
    end
  end
end
