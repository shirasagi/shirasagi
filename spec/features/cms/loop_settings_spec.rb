require 'spec_helper'

describe "cms_loop_settings", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:item) { create(:cms_loop_setting, site: site) }
  let(:index_path) { cms_loop_settings_path site.id }
  let(:new_path) { new_cms_loop_setting_path site.id }
  let(:show_path) { cms_loop_setting_path site.id, item }
  let(:edit_path) { edit_cms_loop_setting_path site.id, item }
  let(:delete_path) { delete_cms_loop_setting_path site.id, item }
  let(:shirasagi_html) { "<div class='item-#{unique_id}'>#{unique_id}</div>" }
  let(:liquid_html) { "{% for item in items %}{{ item.name }}{% endfor %}" }

  context "with auth" do
    before { login_cms_user }

    describe "#index" do
      it do
        visit index_path
        expect(status_code).to eq 200
        expect(current_path).to eq index_path
      end
    end

    describe "#new" do
      it do
        visit new_path
        within "form#item-form" do
          fill_in "item[name]", with: "name-#{unique_id}"
          fill_in "item[description]", with: "description-#{unique_id}"
          fill_in "item[html]", with: "html-#{unique_id}"
          click_button I18n.t('ss.buttons.save')
        end
        expect(status_code).to eq 200
        expect(current_path).not_to eq new_path
        expect(page).to have_no_css("form#item-form")
      end
    end

    describe "#show" do
      it do
        visit show_path
        expect(status_code).to eq 200
        expect(current_path).to eq show_path
      end
    end

    describe "#edit" do
      it do
        visit edit_path
        within "form#item-form" do
          fill_in "item[name]", with: "name-#{unique_id}"
          fill_in "item[description]", with: "description-#{unique_id}"
          fill_in "item[html]", with: "html-#{unique_id}"
          click_button I18n.t('ss.buttons.save')
        end
        expect(status_code).to eq 200
        expect(current_path).not_to eq sns_login_path
        expect(page).to have_no_css("form#item-form")
      end
    end

    describe "#delete" do
      it do
        visit delete_path
        within "form" do
          click_button I18n.t('ss.buttons.delete')
        end
        expect(status_code).to eq 200
        expect(current_path).to eq index_path
      end
    end
    describe "#new with html_format" do
      it "creates loop setting with SHIRASAGI format" do
        visit new_path
        within "form#item-form" do
          fill_in "item[name]", with: "shirasagi-setting-#{unique_id}"
          fill_in "item[description]", with: "description-#{unique_id}"
          fill_in "item[custom_html]", with: shirasagi_html

          select "SHIRASAGI", from: "item[html_format]"

          click_button I18n.t('ss.buttons.save')
        end
        expect(status_code).to eq 200
        expect(current_path).not_to eq new_path

        loop_setting = Cms::LoopSetting.where(name: /shirasagi-setting/).first
        expect(loop_setting.html_format).to eq "shirasagi"
        expect(loop_setting.custom_html).to eq shirasagi_html
      end

      it "creates loop setting with Liquid format" do
        visit new_path
        within "form#item-form" do
          fill_in "item[name]", with: "liquid-setting-#{unique_id}"
          fill_in "item[description]", with: "description-#{unique_id}"
          fill_in "item[custom_html]", with: liquid_html

          select "Liquid", from: "item[html_format]"

          click_button I18n.t('ss.buttons.save')
        end
        expect(status_code).to eq 200
        expect(current_path).not_to eq new_path

        loop_setting = Cms::LoopSetting.where(name: /liquid-setting/).first
        expect(loop_setting.html_format).to eq "liquid"
        expect(loop_setting.custom_html).to eq liquid_html
      end
    end

    describe "#show" do
      it do
        visit show_path
        expect(status_code).to eq 200
        expect(current_path).to eq show_path
      end
    end

    describe "#show with html_format" do
      let(:shirasagi_item) { create(:cms_loop_setting, site: site, html_format: "shirasagi", html: "shirasagi-html") }
      let(:liquid_item) { create(:cms_loop_setting, site: site, html_format: "liquid", custom_html: liquid_html) }

      it "displays SHIRASAGI format loop setting" do
        visit cms_loop_setting_path site.id, shirasagi_item
        expect(status_code).to eq 200
        expect(page).to have_content("SHIRASAGI")
        expect(page).to have_content("shirasagi-html")
      end

      it "displays Liquid format loop setting" do
        visit cms_loop_setting_path site.id, liquid_item
        expect(status_code).to eq 200
        expect(page).to have_content("Liquid")
        expect(page).to have_content(liquid_html)
      end
    end

    describe "#edit" do
      it do
        visit edit_path
        within "form#item-form" do
          fill_in "item[name]", with: "name-#{unique_id}"
          fill_in "item[description]", with: "description-#{unique_id}"
          fill_in "item[custom_html]", with: shirasagi_html
          click_button I18n.t('ss.buttons.save')
        end
        expect(status_code).to eq 200
        expect(current_path).not_to eq sns_login_path
        expect(page).to have_no_css("form#item-form")
      end
    end

    describe "#edit with html_format" do
      let(:shirasagi_item) { create(:cms_loop_setting, site: site, html_format: "shirasagi") }
      let(:liquid_item) { create(:cms_loop_setting, site: site, html_format: "liquid") }

      it "edits SHIRASAGI format loop setting" do
        visit edit_cms_loop_setting_path site.id, shirasagi_item
        within "form#item-form" do
          fill_in "item[name]", with: "updated-shirasagi-#{unique_id}"
          fill_in "item[custom_html]", with: shirasagi_html
          select "SHIRASAGI", from: "item[html_format]"
          click_button I18n.t('ss.buttons.save')
        end
        expect(status_code).to eq 200
        expect(current_path).not_to eq sns_login_path

        shirasagi_item.reload
        expect(shirasagi_item.name).to include("updated-shirasagi")
        expect(shirasagi_item.html_format).to eq "shirasagi"
        expect(shirasagi_item.custom_html).to eq shirasagi_html
      end

      it "edits Liquid format loop setting" do
        visit edit_cms_loop_setting_path site.id, liquid_item
        within "form#item-form" do
          fill_in "item[name]", with: "updated-liquid-#{unique_id}"
          fill_in "item[custom_html]", with: liquid_html
          select "Liquid", from: "item[html_format]"
          click_button I18n.t('ss.buttons.save')
        end
        expect(status_code).to eq 200
        expect(current_path).not_to eq sns_login_path

        liquid_item.reload
        expect(liquid_item.name).to include("updated-liquid")
        expect(liquid_item.html_format).to eq "liquid"
        expect(liquid_item.custom_html).to eq liquid_html
      end

      it "changes format from SHIRASAGI to Liquid" do
        visit edit_cms_loop_setting_path site.id, shirasagi_item
        within "form#item-form" do
          fill_in "item[custom_html]", with: liquid_html
          select "Liquid", from: "item[html_format]"
          click_button I18n.t('ss.buttons.save')
        end
        expect(status_code).to eq 200

        shirasagi_item.reload
        expect(shirasagi_item.html_format).to eq "liquid"
        expect(shirasagi_item.custom_html).to eq liquid_html
      end

      it "changes format from Liquid to SHIRASAGI" do
        visit edit_cms_loop_setting_path site.id, liquid_item
        within "form#item-form" do
          fill_in "item[custom_html]", with: shirasagi_html
          select "SHIRASAGI", from: "item[html_format]"
          click_button I18n.t('ss.buttons.save')
        end
        expect(status_code).to eq 200

        liquid_item.reload
        expect(liquid_item.html_format).to eq "shirasagi"
        expect(liquid_item.custom_html).to eq shirasagi_html
      end
    end

    describe "#delete" do
      it do
        visit delete_path
        within "form" do
          click_button I18n.t('ss.buttons.delete')
        end
        expect(status_code).to eq 200
        expect(current_path).to eq index_path
        expect(Cms::LoopSetting.where(id: item.id)).to be_blank
      end
    end
  end

  context "E2E test for html_format functionality" do
    before { login_cms_user }

    describe "complete workflow with html_format" do
      it "creates, edits, and uses loop settings with different html formats" do
        # 1. SHIRASAGI形式のループ設定を作成
        visit new_path
        shirasagi_name = "e2e-shirasagi-#{unique_id}"
        within "form#item-form" do
          fill_in "item[name]", with: shirasagi_name
          fill_in "item[description]", with: "E2E test SHIRASAGI format"
          fill_in "item[custom_html]", with: shirasagi_html
          select "SHIRASAGI", from: "item[html_format]"
          click_button I18n.t('ss.buttons.save')
        end
        expect(status_code).to eq 200

        # 作成されたループ設定を確認
        shirasagi_setting = Cms::LoopSetting.where(name: shirasagi_name).first
        expect(shirasagi_setting).to be_present
        expect(shirasagi_setting.html_format).to eq "shirasagi"

        # 2. Liquid形式のループ設定を作成
        visit new_path
        liquid_name = "e2e-liquid-#{unique_id}"
        within "form#item-form" do
          fill_in "item[name]", with: liquid_name
          fill_in "item[description]", with: "E2E test Liquid format"
          fill_in "item[custom_html]", with: liquid_html
          select "Liquid", from: "item[html_format]"
          click_button I18n.t('ss.buttons.save')
        end
        expect(status_code).to eq 200

        # 作成されたループ設定を確認
        liquid_setting = Cms::LoopSetting.where(name: liquid_name).first
        expect(liquid_setting).to be_present
        expect(liquid_setting.html_format).to eq "liquid"

        # 3. 一覧画面で両方の設定が表示されることを確認
        visit index_path
        expect(page).to have_content(shirasagi_name)
        expect(page).to have_content(liquid_name)

        # 4. SHIRASAGI形式の設定を編集
        visit edit_cms_loop_setting_path site.id, shirasagi_setting
        within "form#item-form" do
          fill_in "item[custom_html]", with: shirasagi_html
          click_button I18n.t('ss.buttons.save')
        end
        expect(status_code).to eq 200

        shirasagi_setting.reload
        expect(shirasagi_setting.custom_html).to eq shirasagi_html

        # 5. Liquid形式の設定を編集
        visit edit_cms_loop_setting_path site.id, liquid_setting
        within "form#item-form" do
          fill_in "item[custom_html]", with: liquid_html
          click_button I18n.t('ss.buttons.save')
        end
        expect(status_code).to eq 200

        liquid_setting.reload
        expect(liquid_setting.custom_html).to eq liquid_html

        # 6. 詳細画面で正しく表示されることを確認
        visit cms_loop_setting_path site.id, shirasagi_setting
        expect(page).to have_content("SHIRASAGI")
        expect(page).to have_content(shirasagi_html)

        visit cms_loop_setting_path site.id, liquid_setting
        expect(page).to have_content("Liquid")
        expect(page).to have_content(liquid_html)
      end
    end
  end
end
