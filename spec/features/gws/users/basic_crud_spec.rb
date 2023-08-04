require 'spec_helper'

describe "gws_users", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let(:item) { create :ss_user, group_ids: [gws_user.group_ids.first] }
  let(:index_path) { gws_users_path site }
  let(:new_path) { "#{index_path}/new" }
  let(:show_path) { "#{index_path}/#{item.id}" }
  let(:edit_path) { "#{index_path}/#{item.id}/edit" }
  let(:delete_path) { "#{index_path}/#{item.id}/delete" }
  let(:name) { unique_id }
  let(:sys_role1) { create(:sys_role_general, name: I18n.t("sys.roles.user", locale: I18n.default_locale)) }
  let(:title1) { create(:gws_user_title, code: "E100") }
  let(:occupation1) { create(:gws_user_occupation, code: "B133") }

  context "with auth" do
    before { login_gws_user }

    it "basic crud" do
      visit index_path
      expect(current_path).to eq index_path

      #new"
      visit new_path
      wait_for_js_ready
      within "form#item-form" do
        within first('.mod-gws-user-groups') do
          wait_cbox_open { click_on I18n.t('ss.apis.groups.index') }
        end
      end
      wait_for_cbox do
        wait_cbox_close { click_on site.name }
      end
      within "form#item-form" do
        within first('.mod-gws-user-groups') do
          expect(page).to have_css("[data-id='#{site.id}']", text: site.name)
        end
        fill_in "item[name]", with: name
        fill_in "item[email]", with: "#{name}@example.jp"
        expect(page).to have_css('#item_email_errors', text: '')
        fill_in "item[in_password]", with: "pass"
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      #show
      visit show_path
      expect(current_path).to eq show_path

      #edit
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "name"
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      #delete
      visit delete_path
      within "form#item-form" do
        click_button I18n.t('ss.buttons.delete')
      end
      wait_for_notice I18n.t('ss.notice.deleted')
      expect(current_path).to eq index_path

      #delete disabled user
      visit delete_path
      within "form#item-form" do
        click_button I18n.t('ss.buttons.delete')
      end
      wait_for_notice I18n.t('ss.notice.deleted')
      expect(current_path).to eq index_path

      #download template
      visit index_path
      click_on I18n.t("ss.links.import")
      click_on I18n.t("ss.links.download_template")

      wait_for_download

      expect(downloads.first).to be_present
      expect(::File.file?(downloads.first)).to be_truthy

      #import
      sys_role1
      title1
      occupation1

      visit index_path
      click_link I18n.t('ss.links.import')
      within "form#item-form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/gws/user/gws_users.csv"
        page.accept_confirm do
          click_button I18n.t('ss.import')
        end
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(current_path).to eq index_path
    end

    it "download all" do
      visit index_path
      click_on I18n.t("ss.links.download")
      wait_for_js_ready
      within "form#item-form" do
        click_on I18n.t("ss.buttons.download")
      end

      wait_for_download

      I18n.with_locale(I18n.default_locale) do
        SS::Csv.open(downloads.first) do |csv|
          csv_table = csv.read
          expect(csv_table.length).to be > 1
          expect(csv_table[0][Gws::User.t(:id)]).to be_present
          expect(csv_table[0][Gws::User.t(:name)]).to be_present
          expect(csv_table[0][Gws::User.t(:uid)]).to be_present
        end
      end

      expect(Gws::History.all.count).to be > 1
      Gws::History.all.reorder(created: -1).first.tap do |history|
        expect(history.severity).to eq "info"
        expect(history.controller).to eq "gws/users"
        expect(history.path).to eq download_all_gws_users_path(site: site)
        expect(history.action).to eq "download_all"
      end
    end

    it "delete_all disabled user" do
      visit index_path
      expect(current_path).to eq index_path

      #new"
      visit new_path
      within "form#item-form" do
        within first('.mod-gws-user-groups') do
          wait_cbox_open { click_on I18n.t('ss.apis.groups.index') }
        end
      end
      wait_for_cbox do
        wait_cbox_close { click_on site.name }
      end
      within "form#item-form" do
        within first('.mod-gws-user-groups') do
          expect(page).to have_css("[data-id='#{site.id}']", text: site.name)
        end
        fill_in "item[name]", with: name
        fill_in "item[email]", with: "#{name}@example.jp"
        expect(page).to have_css('#item_email_errors', text: '')
        fill_in "item[in_password]", with: "pass"
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      #delete
      visit delete_path
      within "form#item-form" do
        click_button I18n.t('ss.buttons.delete')
      end
      wait_for_notice I18n.t("ss.notice.deleted")
      expect(current_path).to eq index_path

      #delete_all disabled user
      within ".index-search" do
        fill_in "s[keyword]", with: item.name
        select I18n.t('ss.options.state.disabled'), from: 's[state]'
        click_button I18n.t("ss.buttons.search")
      end
      wait_for_js_ready
      expect(page).to have_css(".list-item", count: 1)

      within ".list-head" do
        wait_event_to_fire("ss:checked-all-list-items") { find('label.check input').set(true) }
        page.accept_alert(I18n.t("ss.confirm.delete")) do
          click_button I18n.t("ss.links.delete")
        end
      end
      wait_for_notice I18n.t('ss.notice.deleted')

      within ".index-search" do
        select I18n.t('ss.options.state.disabled'), from: 's[state]'
        click_button I18n.t("ss.buttons.search")
      end
      wait_for_js_ready
      expect(page).to have_no_content(item.name)
      expect(page).to have_css(".list-item", count: 0)
    end
  end

  context 'with form data' do
    let(:form) do
      Gws::UserForm.create!(cur_site: site, state: 'public')
    end
    let!(:column1) { create(:gws_column_text_field, cur_site: site, cur_form: form, input_type: "text") }
    let(:name) { unique_id }
    let(:new_name) { unique_id }

    before { login_gws_user }

    it 'basic crud' do
      visit index_path
      expect(current_path).to eq index_path

      #new
      visit new_path
      wait_for_js_ready
      within 'form#item-form' do
        within first('.mod-gws-user-groups') do
          wait_cbox_open { click_on I18n.t('ss.apis.groups.index') }
        end
      end
      wait_for_cbox do
        wait_cbox_close { click_on site.name }
      end
      within 'form#item-form' do
        within first('.mod-gws-user-groups') do
          expect(page).to have_css("[data-id='#{site.id}']", text: site.name)
        end
        fill_in 'item[name]', with: name
        fill_in 'item[email]', with: "#{name}@example.jp"
        expect(page).to have_css('#item_email_errors', text: '')
        fill_in 'item[in_password]', with: 'pass'
        fill_in "custom[#{column1.id}]", with: unique_id
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      expect { Gws::User.all.active.find_by(name: name) }.not_to raise_error

      #show
      visit index_path
      click_on name
      wait_for_js_ready
      expect(page).to have_css('dl.see dd', text: name)

      #edit
      within ".nav-menu" do
        click_on I18n.t('ss.links.edit')
      end
      within 'form#item-form' do
        fill_in 'item[name]', with: new_name
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      expect { Gws::User.all.active.find_by(name: new_name) }.not_to raise_error

      #delete
      within ".nav-menu" do
        click_on I18n.t('ss.links.delete')
      end
      within 'form#item-form' do
        click_button I18n.t('ss.buttons.delete')
      end
      wait_for_notice I18n.t('ss.notice.deleted')

      expect { Gws::User.all.active.find_by(name: new_name) }.to raise_error Mongoid::Errors::DocumentNotFound
    end
  end
end
