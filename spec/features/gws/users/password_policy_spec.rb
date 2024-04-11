require 'spec_helper'

describe "gws_users", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:item) { create :gws_user, group_ids: gws_user.group_ids }

  before { login_gws_user }

  context "with password policy" do
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

    shared_examples "password policy is" do
      it do
        visit gws_users_path(site: site)
        click_on item.name
        click_on I18n.t("ss.links.edit")

        within "form#item-form" do
          fill_in "item[in_password]", with: password
          click_on I18n.t("ss.buttons.save")
        end
        wait_for_error msg
      end
    end

    context "when upcase_only_password is given" do
      let(:password) { upcase_only_password }
      let(:msg) do
        I18n.t("errors.messages.password_short_downcase", count: setting.password_min_downcase_length)
      end

      it_behaves_like "password policy is"
    end

    context "when downcase_only_password is given" do
      let(:password) { downcase_only_password }
      let(:msg) do
        I18n.t("errors.messages.password_short_digit", count: setting.password_min_digit_length)
      end

      it_behaves_like "password policy is"
    end

    context "when digit_only_password is given" do
      let(:password) { digit_only_password }
      let(:msg) do
        I18n.t("errors.messages.password_short_symbol", count: setting.password_min_symbol_length)
      end

      it_behaves_like "password policy is"
    end

    context "when symbol_only_password is given" do
      let(:password) { symbol_only_password }
      let(:msg) do
        I18n.t("errors.messages.password_short_upcase", count: setting.password_min_upcase_length)
      end

      it_behaves_like "password policy is"
    end

    context "when password_contained_prohibited_chars is given" do
      let(:password) { password_contained_prohibited_chars }
      let(:msg) do
        I18n.t("errors.messages.password_contains_prohibited_chars", prohibited_chars: prohibited_chars.join)
      end

      it_behaves_like "password policy is"
    end

    # 他人のパスワードを変更する際、「以前のものから何文字以上違う文字を含む」というポリシーは適用できない。
    xcontext "when successful password is given, and then insufficient_password is given" do
      let(:password) { insufficient_password }
      let(:msg) do
        I18n.t("errors.messages.password_min_change_chars", count: setting.password_min_change_char_count)
      end

      before do
        item.in_password = password1
        item.save!
      end

      it_behaves_like "password policy is"
    end
  end
end
