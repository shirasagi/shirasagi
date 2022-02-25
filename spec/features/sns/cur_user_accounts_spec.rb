require 'spec_helper'

describe "sns_cur_user_accounts", type: :feature, dbscope: :example, js: true do
  let(:user) { ss_user }

  before { login_user user }

  context "basic crud" do
    let(:name) { unique_id }
    let(:kana) { unique_id }
    let(:email) { unique_email }
    let(:tel) { unique_tel }
    let(:tel_ext) { unique_tel }

    it do
      visit sns_cur_user_account_path
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[kana]", with: kana
        fill_in "item[email]", with: email
        fill_in "item[tel]", with: tel
        fill_in "item[tel_ext]", with: tel_ext

        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      user.reload
      expect(user.name).to eq name
      expect(user.kana).to eq kana
      expect(user.email).to eq email
      expect(user.tel).to eq tel
      expect(user.tel_ext).to eq tel_ext
    end
  end

  context "edit password" do
    let(:model) { SS::PasswordUpdateService }
    let(:new_password) { unique_id }

    # If you want to see specs for password policies, you can see here: spec/features/sys/password_policy_spec.rb

    context "basic crud" do
      it do
        visit sns_cur_user_account_path
        click_on I18n.t("ss.links.edit_password")

        within "form#item-form" do
          fill_in "item[old_password]", with: user.in_password
          fill_in "item[new_password]", with: new_password
          fill_in "item[new_password_again]", with: new_password

          click_on I18n.t('ss.buttons.save')
        end
        wait_for_notice I18n.t("ss.notice.saved")

        user.reload
        expect(SS::User.authenticate(user.email, new_password)).to be_truthy
      end
    end

    context "when old password is missed" do
      it do
        visit sns_cur_user_account_path
        click_on I18n.t("ss.links.edit_password")

        within "form#item-form" do
          fill_in "item[new_password]", with: new_password
          fill_in "item[new_password_again]", with: new_password

          click_on I18n.t('ss.buttons.save')
        end

        attribute = model.human_attribute_name(:old_password)
        message = I18n.t("errors.messages.blank")
        message = I18n.t("errors.format", attribute: attribute, message: message)
        expect(page).to have_css("div#errorExplanation", text: message)
      end
    end

    context "when old password is mismatched to current password" do
      it do
        visit sns_cur_user_account_path
        click_on I18n.t("ss.links.edit_password")

        within "form#item-form" do
          fill_in "item[old_password]", with: unique_id
          fill_in "item[new_password]", with: new_password
          fill_in "item[new_password_again]", with: new_password

          click_on I18n.t('ss.buttons.save')
        end

        attribute = model.human_attribute_name(:old_password)
        message = I18n.t("errors.messages.mismatch")
        message = I18n.t("errors.format", attribute: attribute, message: message)
        expect(page).to have_css("div#errorExplanation", text: message)
      end
    end

    context "when new_password is missed" do
      it do
        visit sns_cur_user_account_path
        click_on I18n.t("ss.links.edit_password")

        within "form#item-form" do
          fill_in "item[old_password]", with: user.in_password
          fill_in "item[new_password_again]", with: new_password

          click_on I18n.t('ss.buttons.save')
        end

        attribute = model.human_attribute_name(:new_password)
        message = I18n.t("errors.messages.blank")
        message = I18n.t("errors.format", attribute: attribute, message: message)
        expect(page).to have_css("div#errorExplanation", text: message)
      end
    end

    context "when new_password_again is missed" do
      it do
        visit sns_cur_user_account_path
        click_on I18n.t("ss.links.edit_password")

        within "form#item-form" do
          fill_in "item[old_password]", with: user.in_password
          fill_in "item[new_password]", with: new_password

          click_on I18n.t('ss.buttons.save')
        end

        attribute = model.human_attribute_name(:new_password_again)
        message = I18n.t("errors.messages.blank")
        message = I18n.t("errors.format", attribute: attribute, message: message)
        expect(page).to have_css("div#errorExplanation", text: message)
      end
    end

    context "when new_password and new_password_again is mismatched" do
      it do
        visit sns_cur_user_account_path
        click_on I18n.t("ss.links.edit_password")

        within "form#item-form" do
          fill_in "item[old_password]", with: user.in_password
          fill_in "item[new_password]", with: unique_id
          fill_in "item[new_password_again]", with: unique_id

          click_on I18n.t('ss.buttons.save')
        end

        attribute = model.human_attribute_name(:new_password)
        message = I18n.t("errors.messages.confirmation", attribute: model.human_attribute_name(:new_password_again))
        message = I18n.t("errors.format", attribute: attribute, message: message)
        expect(page).to have_css("div#errorExplanation", text: message)
      end
    end
  end
end
