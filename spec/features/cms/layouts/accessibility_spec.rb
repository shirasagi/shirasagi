require 'spec_helper'

describe "cms_layouts", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:admin) { cms_user }

  context "shows accessibility errors and link errors" do
    let(:user) { admin }
    let(:html_with_error) do
      <<~HTML
        <p><a href="/#{unique_id}">ﾃｽﾄ</a></p>
      HTML
    end

    before do
      @net_connect_allowed = WebMock.net_connect_allowed?
      WebMock.disable_net_connect!(allow_localhost: true)
    end

    after do
      WebMock.allow_net_connect! if @net_connect_allowed
    end

    context "#new" do
      it do
        login_user user, to: new_cms_layout_path(site: site)

        within "form#item-form" do
          fill_in "item[name]", with: "アクセシビリティテスト"
          fill_in "item[basename]", with: "a11y-test"
          fill_in_code_mirror "item[html]", with: html_with_error

          wait_for_event_fired "ss:check:done" do
            within ".cms-body-checker" do
              click_on I18n.t("ss.buttons.run")
            end
          end
        end

        within "form#item-form" do
          within "#errorSyntaxChecker" do
            expect(page).to have_content(I18n.t("errors.messages.invalid_kana_character"))
            expect(page).to have_content(I18n.t("errors.messages.check_link_text"))
          end
          within "#errorLinkChecker" do
            expect(page).to have_content(I18n.t("errors.messages.link_check_failed_not_found"))
          end
        end

        expect(Cms::Layout.all.count).to eq 0
      end
    end

    context "#edit" do
      it do
        item = create(:cms_layout, cur_site: site)
        login_user user, to: edit_cms_layout_path(site: site, id: item)

        within "form#item-form" do
          fill_in "item[name]", with: "アクセシビリティテスト"
          fill_in "item[basename]", with: "a11y-test"
          fill_in_code_mirror "item[html]", with: html_with_error

          wait_for_event_fired "ss:check:done" do
            within ".cms-body-checker" do
              click_on I18n.t("ss.buttons.run")
            end
          end
        end

        within "form#item-form" do
          within "#errorSyntaxChecker" do
            expect(page).to have_content(I18n.t("errors.messages.invalid_kana_character"))
            expect(page).to have_content(I18n.t("errors.messages.check_link_text"))
          end
          within "#errorLinkChecker" do
            expect(page).to have_content(I18n.t("errors.messages.link_check_failed_not_found"))
          end
        end

        Cms::Layout.find(item.id).tap do |after_item|
          # アクセシビリティチェックを実行すると、常に結果が保存/更新される
          expect(after_item.syntax_check_result_checked.in_time_zone).to be_within(30.seconds).of(Time.zone.now)
          expect(after_item.syntax_check_result_violation_count).to eq 2
        end
      end
    end
  end

  context "with accessibility error and permissions" do
    let(:layout_permissions) do
      %w(
        read_private_cms_layouts edit_private_cms_layouts delete_private_cms_layouts
        read_other_cms_layouts edit_other_cms_layouts delete_other_cms_layouts
        edit_cms_ignore_syntax_check
      )
    end
    let!(:role) do
      create :cms_role, cur_site: site, name: "role-#{unique_id}", permissions: layout_permissions
    end
    let(:user) { create :cms_test_user, group_ids: admin.group_ids, cms_role_ids: role.id }
    let(:html_with_error) { '<p>ﾃｽﾄ</p>' }
    let(:new_or_edit) { %i[new edit].sample }

    it "shows accessibility error and allows ignore if permitted" do
      if new_or_edit == :new
        login_user user, to: new_cms_layout_path(site: site)
      else
        item = create(:cms_layout, cur_site: site)
        login_user user, to: edit_cms_layout_path(site: site, id: item)
      end
      within "form#item-form" do
        fill_in "item[name]", with: "アクセシビリティテスト"
        fill_in "item[basename]", with: "a11y-test"
        fill_in_code_mirror "item[html]", with: html_with_error
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_error I18n.t("errors.messages.accessibility_error")

      within "form#item-form" do
        within "#errorSyntaxChecker" do
          expect(page).to have_content(I18n.t("errors.messages.invalid_kana_character"))
        end

        # 権限があれば「警告を無視して保存」チェックボックスが表示される
        expect(page).to have_unchecked_field('ignore_syntax_check')
        check I18n.t("ss.buttons.ignore_alerts_and_save")
        click_button I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      Cms::Layout.where(name: "アクセシビリティテスト").first.tap do |layout|
        expect(layout).to be_present
        expect(layout.html).to eq html_with_error
        # アクセシビリティチェックを実行すると、常に結果が保存/更新される
        expect(layout.syntax_check_result_checked.in_time_zone).to be_within(30.seconds).of(Time.zone.now)
        expect(layout.syntax_check_result_violation_count).to eq 1
      end
    end

    it "auto correct removes error" do
      if new_or_edit == :new
        login_user user, to: new_cms_layout_path(site: site)
      else
        item = create(:cms_layout, cur_site: site)
        login_user user, to: edit_cms_layout_path(site: site, id: item)
      end
      within "form#item-form" do
        fill_in "item[name]", with: "自動修正テスト"
        fill_in "item[basename]", with: "auto-correct-test"
        fill_in_code_mirror "item[html]", with: html_with_error
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_error I18n.t("errors.messages.accessibility_error")

      within "form#item-form" do
        wait_for_event_fired "ss:correct:done" do
          within "#errorSyntaxChecker" do
            expect(page).to have_content(I18n.t("errors.messages.invalid_kana_character"))
            click_button I18n.t("cms.auto_correct.link")
          end
        end

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      Cms::Layout.where(name: "自動修正テスト").first.tap do |layout|
        expect(layout.html).to eq html_with_error.unicode_normalize(:nfkc)
        # アクセシビリティチェックを実行すると、常に結果が保存/更新される
        expect(layout.syntax_check_result_checked.in_time_zone).to be_within(30.seconds).of(Time.zone.now)
        expect(layout.syntax_check_result_violation_count).to eq 0
      end
    end
  end

  context "with accessibility error and no ignore permission" do
    let(:layout_permissions) do
      %w(
        read_private_cms_layouts edit_private_cms_layouts delete_private_cms_layouts
        read_other_cms_layouts edit_other_cms_layouts delete_other_cms_layouts
      )
    end
    let!(:role) do
      create :cms_role, cur_site: site, name: "role-#{unique_id}", permissions: layout_permissions
    end
    let(:user) { create :cms_test_user, group_ids: admin.group_ids, cms_role_ids: role.id }
    let(:html_with_error) { '<p>ﾃｽﾄ</p>' }
    let(:new_or_edit) { %i[new edit].sample }

    it "shows accessibility error and does not allow ignore" do
      if new_or_edit == :new
        login_user user, to: new_cms_layout_path(site: site)
      else
        item = create(:cms_layout, cur_site: site)
        login_user user, to: edit_cms_layout_path(site: site, id: item)
      end
      within "form#item-form" do
        fill_in "item[name]", with: "アクセシビリティテスト"
        fill_in "item[basename]", with: "a11y-test2"
        fill_in_code_mirror "item[html]", with: html_with_error
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_error I18n.t("errors.messages.accessibility_error")

      within "form#item-form" do
        within "#errorSyntaxChecker" do
          expect(page).to have_content(I18n.t("errors.messages.invalid_kana_character"))
        end
        # 権限がなければ「警告を無視して保存」チェックボックスが表示されない
        expect(page).to have_no_field('ignore_syntax_check')
        expect(page).to have_no_content(I18n.t("ss.buttons.ignore_alerts_and_save"))
      end
      if new_or_edit == :new
        expect(Cms::Layout.all.count).to eq 0
      else
        Cms::Layout.all.find(item.id).tap do |after|
          # no edit made
          expect(after.html).to eq item.html
          # アクセシビリティチェックを実行すると、常に結果が保存/更新される
          expect(after.syntax_check_result_checked.in_time_zone).to be_within(30.seconds).of(Time.zone.now)
          expect(after.syntax_check_result_violation_count).to eq 1
        end
      end
    end
  end

  context "continuous correction" do
    let!(:dictionary) { create :cms_word_dictionary, cur_site: site }
    let(:html_with_error) { '<p>ﾃｽﾄ</p><p>①②③④⑤⑥⑦⑧⑨</p>' }
    let(:new_or_edit) { %i[new edit].sample }

    it do
      if new_or_edit == :new
        login_user admin, to: new_cms_layout_path(site: site)
      else
        item = create(:cms_layout, cur_site: site)
        login_user admin, to: edit_cms_layout_path(site: site, id: item)
      end
      within "form#item-form" do
        fill_in_code_mirror "item[html]", with: html_with_error

        wait_for_event_fired "ss:check:done" do
          within ".cms-body-checker" do
            click_on I18n.t("ss.buttons.run")
          end
        end
      end

      within "form#item-form" do
        within "#errorSyntaxChecker" do
          expect(page).to have_css("[name='btn-correct']", count: 10)
        end
      end

      10.times do
        wait_for_event_fired "ss:correct:done" do
          within "form#item-form" do
            within "#errorSyntaxChecker" do
              # click_button I18n.t("cms.auto_correct.link")
              first("[name='btn-correct']").click
            end
          end
        end
      end

      within "form#item-form" do
        within "#errorSyntaxChecker" do
          expect(page).to have_css("[name='btn-correct']", count: 0)
          expect(page).to have_css(".errorExplanationBody", text: I18n.t("errors.template.no_errors"))
        end
      end
    end
  end
end
