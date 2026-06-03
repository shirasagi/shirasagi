require 'spec_helper'

describe "cms/line/settings", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:item) { create :cms_line_setting }
  let(:default_template_types) { %w(text image page json_body) }

  let(:show_path) { cms_line_setting_path site }
  let(:edit_path) { edit_cms_line_setting_path site }

  def types_label(types)
    types.map { |k| I18n.t("cms.options.line_template_type.#{k}") }.join(", ")
  end

  describe "basic crud" do
    before { login_cms_user }

    it "#show" do
      visit show_path
      within "#crumbs" do
        expect(page).to have_link(I18n.t("cms.line"), href: cms_line_messages_path(site))
        expect(page).to have_text(I18n.t("cms.line_setting"))
      end
      within "#addon-basic" do
        expect(page).to have_text(types_label(default_template_types))
      end
      expect(Cms::Line::Setting.site(site).count).to eq 1
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        uncheck "item_template_types_page"
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')
      expect(Cms::Line::Setting.site(site).count).to eq 1

      within "#addon-basic" do
        expect(page).to have_text(types_label(default_template_types - %w(page)))
      end
    end
  end
end
