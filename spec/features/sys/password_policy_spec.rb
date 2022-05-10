require 'spec_helper'

describe "sys_password_policies", type: :feature, dbscope: :example, js: true do
  context "basic crud" do
    let(:password_limit_days) { rand(1..100) }
    let(:password_warning_days) { rand(1..password_limit_days) }
    let(:password_min_length) { rand(12..20) }
    let(:password_min_upcase_length) { rand(1..3) }
    let(:password_min_downcase_length) { rand(1..3) }
    let(:password_min_digit_length) { rand(1..3) }
    let(:password_min_symbol_length) { rand(1..3) }
    let(:password_prohibited_char) { %w(a b c d e f g h i j k l).sample(3).join }
    let(:password_min_change_char_count) { rand(1..4) }

    before { login_sys_user }

    it do
      visit sys_password_policy_path
      click_on I18n.t("ss.links.edit")

      within "form#item-form" do
        select I18n.t("ss.options.state.enabled"), from: "item[password_limit_use]"
        fill_in "item[password_limit_days]", with: password_limit_days

        select I18n.t("ss.options.state.enabled"), from: "item[password_warning_use]"
        fill_in "item[password_warning_days]", with: password_warning_days

        select I18n.t("ss.options.state.enabled"), from: "item[password_min_use]"
        fill_in "item[password_min_length]", with: password_min_length

        select I18n.t("ss.options.state.enabled"), from: "item[password_min_upcase_use]"
        fill_in "item[password_min_upcase_length]", with: password_min_upcase_length

        select I18n.t("ss.options.state.enabled"), from: "item[password_min_upcase_use]"
        fill_in "item[password_min_upcase_length]", with: password_min_upcase_length

        select I18n.t("ss.options.state.enabled"), from: "item[password_min_downcase_use]"
        fill_in "item[password_min_downcase_length]", with: password_min_downcase_length

        select I18n.t("ss.options.state.enabled"), from: "item[password_min_digit_use]"
        fill_in "item[password_min_digit_length]", with: password_min_digit_length

        select I18n.t("ss.options.state.enabled"), from: "item[password_min_symbol_use]"
        fill_in "item[password_min_symbol_length]", with: password_min_symbol_length

        select I18n.t("ss.options.state.enabled"), from: "item[password_prohibited_char_use]"
        fill_in "item[password_prohibited_char]", with: password_prohibited_char

        select I18n.t("ss.options.state.enabled"), from: "item[password_min_change_char_use]"
        fill_in "item[password_min_change_char_count]", with: password_min_change_char_count

        click_on I18n.t("ss.buttons.save")
      end

      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      Sys::Setting.first.tap do |setting|
        expect(setting.password_limit_use).to eq "enabled"
        expect(setting.password_limit_days).to eq password_limit_days

        expect(setting.password_warning_use).to eq "enabled"
        expect(setting.password_warning_days).to eq password_warning_days

        expect(setting.password_min_use).to eq "enabled"
        expect(setting.password_min_length).to eq password_min_length

        expect(setting.password_min_upcase_use).to eq "enabled"
        expect(setting.password_min_upcase_length).to eq password_min_upcase_length

        expect(setting.password_min_downcase_use).to eq "enabled"
        expect(setting.password_min_downcase_length).to eq password_min_downcase_length

        expect(setting.password_min_digit_use).to eq "enabled"
        expect(setting.password_min_digit_length).to eq password_min_digit_length

        expect(setting.password_min_symbol_use).to eq "enabled"
        expect(setting.password_min_symbol_length).to eq password_min_symbol_length

        expect(setting.password_prohibited_char_use).to eq "enabled"
        expect(setting.password_prohibited_char).to eq password_prohibited_char

        expect(setting.password_min_change_char_use).to eq "enabled"
        expect(setting.password_min_change_char_count).to eq password_min_change_char_count
      end
    end
  end

  context "password expiration" do
    let!(:setting) do
      Sys::Setting.create(
        password_limit_use: "enabled", password_limit_days: 10,
        password_warning_use: "enabled", password_warning_days: 5
      )
    end

    before do
      login_sys_user
    end

    context "when password is expired" do
      it do
        sys_user.set(password_changed_at: Time.zone.now.beginning_of_hour - setting.password_limit_days.days)
        visit sns_mypage_path
        within "div.warning" do
          expect(page).to have_link(I18n.t("ss.warning.password_expired"), href: sns_cur_user_account_path)
        end
      end
    end

    context "when password is nearly expired" do
      it do
        sys_user.set(password_changed_at: Time.zone.now.beginning_of_hour - setting.password_warning_days.days)
        visit sns_mypage_path
        within "div.warning" do
          expect(page).to have_link(I18n.t("ss.warning.password_neary_expired"), href: sns_cur_user_account_path)
        end
      end
    end

    context "when password is alived" do
      it do
        visit sns_mypage_path
        expect(page).to have_no_css("div.warning")
      end
    end
  end

  context "password validation with password policy" do
    # at first, you must create a user
    let!(:user) { sys_user }

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

    before do
      login_user user
    end

    def fill_password_and_save(password)
      visit sns_cur_user_account_path
      click_on I18n.t("ss.links.edit_password")

      within "form#item-form" do
        fill_in "item[old_password]", with: user.in_password
        fill_in "item[new_password]", with: password
        fill_in "item[new_password_again]", with: password
        click_on I18n.t("ss.buttons.save")
      end
    end

    context "when upcase_only_password is given" do
      it do
        fill_password_and_save(upcase_only_password)
        msg = I18n.t("errors.messages.password_short_downcase", count: setting.password_min_downcase_length)
        expect(page).to have_css("div#errorExplanation", text: msg)
      end
    end

    context "when downcase_only_password is given" do
      it do
        fill_password_and_save(downcase_only_password)
        msg = I18n.t("errors.messages.password_short_digit", count: setting.password_min_digit_length)
        expect(page).to have_css("div#errorExplanation", text: msg)
      end
    end

    context "when digit_only_password is given" do
      it do
        fill_password_and_save(digit_only_password)
        msg = I18n.t("errors.messages.password_short_symbol", count: setting.password_min_symbol_length)
        expect(page).to have_css("div#errorExplanation", text: msg)
      end
    end

    context "when symbol_only_password is given" do
      it do
        fill_password_and_save(symbol_only_password)
        msg = I18n.t("errors.messages.password_short_upcase", count: setting.password_min_upcase_length)
        expect(page).to have_css("div#errorExplanation", text: msg)
      end
    end

    context "when password_contained_prohibited_chars is given" do
      it do
        fill_password_and_save(password_contained_prohibited_chars)
        msg = I18n.t("errors.messages.password_contains_prohibited_chars", prohibited_chars: prohibited_chars.join)
        expect(page).to have_css("div#errorExplanation", text: msg)
      end
    end

    context "when successful password is given, and then insufficient_password is given" do
      it do
        fill_password_and_save(password1)
        wait_for_notice I18n.t('ss.notice.saved')

        user.in_password = password1
        fill_password_and_save(insufficient_password)
        msg = I18n.t("errors.messages.password_min_change_chars", count: setting.password_min_change_char_count)
        expect(page).to have_css("div#errorExplanation", text: msg)
      end
    end
  end
end
