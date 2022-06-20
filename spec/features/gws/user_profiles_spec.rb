require 'spec_helper'

describe "gws_user_profiles", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }

  shared_examples "what gws/user_profiles is" do
    context "basic crud" do
      let(:name) { unique_id }
      let(:kana) { unique_id }
      let(:email) { unique_email }
      let(:tel) { unique_tel }
      let(:tel_ext) { unique_tel }

      it do
        visit gws_user_profile_path(site: site)
        within '#addon-basic' do
          expect(page).to have_content(user.name)
        end

        click_on I18n.t("ss.links.edit")
        within "#item-form" do
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
        expect(user.initial_password_warning).to be_present
      end
    end

    context "edit password" do
      let(:model) { SS::PasswordUpdateService }
      let(:new_password) { unique_id }

      # If you want to see specs for password policies, you can see here: spec/features/sys/password_policy_spec.rb

      context "basic crud" do
        it do
          visit gws_user_profile_path(site: site)
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
          expect(user.initial_password_warning).to be_blank
        end
      end

      context "when old password is missed" do
        it do
          visit gws_user_profile_path(site: site)
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
    end
  end

  context "with super user" do
    let(:user) do
      user = gws_user
      user.update(initial_password_warning: 1)
      user
    end

    before { login_user user }

    it_behaves_like "what gws/user_profiles is"
  end

  context "with regular user" do
    let(:user) do
      user = create :gws_user, group_ids: gws_user.group_ids
      user.update(initial_password_warning: 1)
      user
    end

    before { login_user user }

    it_behaves_like "what gws/user_profiles is"
  end
end
