require 'spec_helper'

describe "sns_user_files", type: :feature, dbscope: :example, js: true do
  # let(:user) { ss_user }
  # let(:item) { tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/logo.png", user: user, model: 'ss/user_file') }
  # let(:index_path) { sns_cur_user_files_path }
  # let(:new_path) { new_sns_cur_user_file_path }
  # let(:show_path) { sns_cur_user_file_path item }
  # let(:edit_path) { edit_sns_cur_user_file_path item }
  # let(:delete_path) { delete_sns_cur_user_file_path item }

  before { login_ss_user }

  context "basic crud" do
    it do
      visit sns_cur_user_files_path
      click_on I18n.t("ss.links.new")
      within "form#item-form" do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/logo.png"
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(SS::UserFile.all.count).to eq 1
      item = SS::UserFile.all.first
      expect(item.name).to eq "logo.png"
      expect(item.user_id).to eq ss_user.id

      visit sns_cur_user_files_path
      click_on item.name
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      item.reload
      expect(item.name).to eq "modify"

      visit sns_cur_user_files_path
      click_on item.name
      click_on I18n.t("ss.links.delete")
      within "form" do
        click_on I18n.t('ss.buttons.delete')
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      expect { item.reload }.to raise_error Mongoid::Errors::DocumentNotFound
    end
  end

  context "when validation error occurred" do
    it do
      visit new_sns_cur_user_file_path
      within "form#item-form" do
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_error I18n.t("errors.messages.blank")

      within "form#item-form" do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/logo.png"
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(SS::UserFile.all.count).to eq 1
      item = SS::UserFile.all.first
      expect(item.name).to eq "logo.png"
      expect(item.user_id).to eq ss_user.id
    end
  end

  context "with svg file" do
    before { login_ss_user }

    it do
      visit sns_cur_user_files_path
      click_on I18n.t("ss.links.new")
      within "form#item-form" do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/shirasagi.svg"
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(SS::UserFile.all.count).to eq 1
      item = SS::UserFile.all.first
      expect(item.name).to eq "shirasagi.svg"
      expect(item.user_id).to eq ss_user.id

      visit sns_cur_user_files_path
      click_on item.name
      expect(page).to have_content("shirasagi.svg")
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      item.reload
      expect(item.name).to eq "modify"

      visit sns_cur_user_files_path
      click_on item.name
      click_on I18n.t("ss.links.delete")
      within "form" do
        click_on I18n.t('ss.buttons.delete')
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      expect { item.reload }.to raise_error Mongoid::Errors::DocumentNotFound
    end
  end
end
