require 'spec_helper'

describe "gws_users", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:group) { gws_group }
  let(:item) { create :ss_user, group_ids: [gws_user.group_ids.first] }
  let(:index_path) { gws_users_path site }
  let(:new_path) { "#{index_path}/new" }
  let(:show_path) { "#{index_path}/#{item.id}" }
  let(:edit_path) { "#{index_path}/#{item.id}/edit" }
  let(:delete_path) { "#{index_path}/#{item.id}/delete" }
  let(:name) { unique_id }

  context "with auth" do
    before { login_gws_user }

    it "basic crud" do
      visit index_path
      expect(current_path).to eq index_path

      #new"
      visit new_path
      first('.mod-gws-user-groups').click_on I18n.t('ss.apis.groups.index')
      wait_for_cbox
      first('tbody.items a.select-item').click

      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[email]", with: "#{name}@example.jp"
        fill_in "item[in_password]", with: "pass"
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_no_css('#item-form')

      #show
      visit show_path
      expect(current_path).to eq show_path

      #edit
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "name"
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_no_css('#item-form')

      #delete
      visit delete_path
      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
      expect(current_path).to eq index_path

      #download
      visit index_path
      click_link I18n.t('ss.links.download')
      visit "#{index_path}/download_template"

      #import
      visit index_path
      click_link I18n.t('ss.links.import')
      within "form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/gws/user/gws_users.csv"
        page.accept_confirm do
          click_button I18n.t('ss.import')
        end
      end
      expect(current_path).to eq index_path
    end
  end

  context 'with form data' do
    let(:form) do
      Gws::UserForm.create!(cur_site: site, state: 'public')
    end
    let!(:column1) { create(:gws_column_text_field, cur_site: site, cur_form: form) }
    let(:name) { unique_id }
    let(:new_name) { unique_id }

    before { login_gws_user }

    it 'basic crud' do
      visit index_path
      expect(current_path).to eq index_path

      #new"
      visit new_path
      first('.mod-gws-user-groups').click_on I18n.t('ss.apis.groups.index')
      wait_for_cbox
      first('tbody.items a.select-item').click

      within 'form#item-form' do
        fill_in 'item[name]', with: name
        fill_in 'item[email]', with: "#{name}@example.jp"
        fill_in 'item[in_password]', with: 'pass'
        fill_in "custom[#{column1.id}]", with: unique_id
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_ajax
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      expect { Gws::User.all.active.find_by(name: name) }.not_to raise_error

      #show
      click_on name
      expect(page).to have_css('dl.see dd', text: name)

      #edit
      click_on I18n.t('ss.links.edit')
      within 'form#item-form' do
        fill_in 'item[name]', with: new_name
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      expect { Gws::User.all.active.find_by(name: new_name) }.not_to raise_error

      #delete
      click_on I18n.t('ss.links.delete')
      within 'form' do
        click_button I18n.t('ss.buttons.delete')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      expect { Gws::User.all.active.find_by(name: new_name) }.to raise_error Mongoid::Errors::DocumentNotFound
    end
  end
end
