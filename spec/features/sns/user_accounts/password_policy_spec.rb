require 'spec_helper'

describe "sns_cur_user_account", type: :feature, dbscope: :example, js: true, ldap: true do
  shared_examples "password_policy" do
    it do
      visit sns_cur_user_account_path
      click_on I18n.t("ss.links.edit_password")

      within "form#item-form" do
        fill_in "item[old_password]", with: user.in_password
        fill_in "item[new_password]", with: password
        fill_in "item[new_password_again]", with: password
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_error msg
    end
  end

  shared_examples "password validation with password policy" do
    let(:chars) { (" ".."~").to_a }
    let(:upcases) { ("A".."Z").to_a }
    let(:downcases) { ("a".."z").to_a }
    let(:digits) { ("0".."9").to_a }
    let(:symbols) { chars - upcases - downcases - digits }
    let(:prohibited_chars) { chars.sample(rand(4..6)).join.strip.chars }
    let!(:setting) do
      Sys::Setting.create(
        password_min_use: "enabled", password_min_length: rand(16..20),
        password_min_upcase_use: "enabled", password_min_upcase_length: rand(2..4),
        password_min_downcase_use: "enabled", password_min_downcase_length: rand(2..4),
        password_min_digit_use: "enabled", password_min_digit_length: rand(2..4),
        password_min_symbol_use: "enabled", password_min_symbol_length: rand(2..4),
        password_prohibited_char_use: "enabled", password_prohibited_char: prohibited_chars.join,
        password_min_change_char_use: "enabled", password_min_change_char_count: rand(3..5)
      )
    end
    let(:upcase_only_password) { (upcases - prohibited_chars).sample(setting.password_min_length).join }
    let(:downcase_only_password) { (downcases - prohibited_chars).sample(setting.password_min_length).join }
    let(:digit_only_password) { (digits - prohibited_chars).sample(setting.password_min_length).join }
    let(:symbol_only_password) { (symbols - prohibited_chars).sample(setting.password_min_length).join }
    let(:password_contained_prohibited_chars) { prohibited_chars.join }
    let(:password1) do
      etra_length = setting.password_min_length
      - setting.password_min_upcase_length - setting.password_min_downcase_length
      - setting.password_min_digit_length - setting.password_min_symbol_length

      password = ""
      password << (upcases - prohibited_chars).sample(setting.password_min_upcase_length).join
      password << (downcases - prohibited_chars).sample(setting.password_min_downcase_length).join
      password << (digits - prohibited_chars).sample(setting.password_min_digit_length).join
      password << (symbols - prohibited_chars).sample(setting.password_min_symbol_length).join
      password << (chars - prohibited_chars).sample(etra_length).join
      password
    end
    let(:insufficient_password) do
      prev_chars = password1.chars.uniq
      password = ""
      password << prev_chars.sample(setting.password_min_length - setting.password_min_change_char_count + 1).join
      password << (chars - prev_chars - prohibited_chars).sample(setting.password_min_change_char_count - 1).join
      password
    end

    context "when upcase_only_password is given" do
      let(:password) { upcase_only_password }
      let(:msg) do
        I18n.t("errors.messages.password_short_downcase", count: setting.password_min_downcase_length)
      end

      before do
        login_user user
      end

      it_behaves_like "password_policy"
    end

    context "when downcase_only_password is given" do
      let(:password) { downcase_only_password }
      let(:msg) do
        I18n.t("errors.messages.password_short_digit", count: setting.password_min_digit_length)
      end

      before do
        login_user user
      end

      it_behaves_like "password_policy"
    end

    context "when digit_only_password is given" do
      let(:password) { digit_only_password }
      let(:msg) do
        I18n.t("errors.messages.password_short_symbol", count: setting.password_min_symbol_length)
      end

      before do
        login_user user
      end

      it_behaves_like "password_policy"
    end

    context "when symbol_only_password is given" do
      let(:password) { symbol_only_password }
      let(:msg) do
        I18n.t("errors.messages.password_short_upcase", count: setting.password_min_upcase_length)
      end

      before do
        login_user user
      end

      it_behaves_like "password_policy"
    end

    context "when password_contained_prohibited_chars is given" do
      let(:password) { password_contained_prohibited_chars }
      let(:msg) do
        I18n.t("errors.messages.password_contains_prohibited_chars", prohibited_chars: prohibited_chars.join)
      end

      before do
        login_user user
      end

      it_behaves_like "password_policy"
    end

    context "when successful password is given, and then insufficient_password is given" do
      let(:password) { insufficient_password }
      let(:msg) do
        I18n.t("errors.messages.password_min_change_chars", count: setting.password_min_change_char_count)
      end

      before do
        service = SS::PasswordUpdateService.new(cur_user: user, self_edit: true)
        service.old_password = "pass"
        service.new_password = password1
        service.new_password_again = password1
        expect(service.update_password).to be_truthy

        user.in_password = password1
        login_user user
      end

      after do
        if user.type_ldap?
          stop_ldap_service
        end
      end

      it_behaves_like "password_policy"
    end
  end

  context "with sns user" do
    let!(:user) { sys_user }

    it_behaves_like "password validation with password policy"
  end

  context "with ldap user" do
    let(:permissions) { %w(edit_sys_user_account edit_password_sys_user_account) }
    let!(:role) { create :sys_role, name: unique_id, permissions: permissions }
    let!(:user) { create :ss_ldap_user2, sys_role_ids: [ role.id ] }

    before do
      auth_setting = Sys::Auth::Setting.instance
      auth_setting.ldap_url = "ldap://localhost:#{SS::LdapSupport.docker_ldap_port}/"
      auth_setting.save!
    end

    after { ActiveSupport::CurrentAttributes.reset_all }

    it_behaves_like "password validation with password policy"
  end
end
