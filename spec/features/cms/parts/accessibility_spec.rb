require 'spec_helper'

describe "cms_parts", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:admin) { cms_user }

  context "syntax check" do
    let(:user) { admin }
    let(:html_with_error) do
      <<~HTML
        <p><a href="/#{unique_id}">ﾃｽﾄ</a></p>
      HTML
    end
    let(:new_or_edit) { %i[new edit].sample }

    before do
      @net_connect_allowed = WebMock.net_connect_allowed?
      WebMock.disable_net_connect!(allow_localhost: true)
    end

    after do
      WebMock.allow_net_connect! if @net_connect_allowed
    end

    it "shows accessibility errors and link errors" do
      if new_or_edit == :new
        login_user user, to: new_cms_part_path(site: site)
      else
        item = create(:cms_part_free, cur_site: site)
        login_user user, to: edit_cms_part_path(site: site, id: item)
      end

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
        end
        within "#errorLinkChecker" do
          expect(page).to have_content(I18n.t("errors.messages.link_check_failed_not_found"))
        end
      end
    end
  end

  context "with accessibility error and permissions" do
    let(:layout_permissions) do
      %w(
        read_private_cms_parts edit_private_cms_parts delete_private_cms_parts
        read_other_cms_parts edit_other_cms_parts delete_other_cms_parts
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
        login_user user, to: new_cms_part_path(site: site)
      else
        item = create(:cms_part_free, cur_site: site)
        login_user user, to: edit_cms_part_path(site: site, id: item)
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
        check I18n.t("ss.buttons.ignore_alerts_and_save")

        click_button I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      Cms::Part.where(name: "アクセシビリティテスト").first.tap do |part|
        expect(part).to be_present
        expect(part.html).to eq html_with_error
      end
    end

    it "auto correct removes error" do
      if new_or_edit == :new
        login_user user, to: new_cms_part_path(site: site)
      else
        item = create(:cms_part_free, cur_site: site)
        login_user user, to: edit_cms_part_path(site: site, id: item)
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

        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      Cms::Part.where(name: "自動修正テスト").first.tap do |part|
        expect(part.html).to eq html_with_error.unicode_normalize(:nfkc)
      end
    end
  end

  context "with accessibility error and no ignore permission" do
    let!(:site) { cms_site }
    let!(:admin) { cms_user }
    let(:layout_permissions) do
      %w(
        read_private_cms_parts edit_private_cms_parts delete_private_cms_parts
        read_other_cms_parts edit_other_cms_parts delete_other_cms_parts
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
        login_user user, to: new_cms_part_path(site: site)
      else
        item = create(:cms_part_free, cur_site: site)
        login_user user, to: edit_cms_part_path(site: site, id: item)
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
        expect(Cms::Part.all.count).to eq 0
      else
        Cms::Part.all.find(item.id).tap do |after|
          # no edit made
          expect(after.html).to eq item.html
        end
      end
    end
  end
end
