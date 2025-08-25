require 'spec_helper'

describe "cms_syntax_checker_unfavorable_words", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }

  context "basic crud" do
    let(:name) { "name-#{unique_id}" }
    let(:state) { %w(enabled enabled).sample }
    let(:state_label) { I18n.t("ss.options.state.#{state}") }
    let(:words) { Array.new(3) { "word-#{unique_id}" } }
    let(:name2) { "name-#{unique_id}" }
    let(:state2) { %w(enabled enabled).sample }
    let(:state2_label) { I18n.t("ss.options.state.#{state}") }
    let(:words2) { Array.new(3) { "word-#{unique_id}" } }

    it do
      login_cms_user to: cms_syntax_checker_main_path(site: site)
      click_on I18n.t("mongoid.models.cms/unfavorable_word")
      click_on I18n.t("ss.links.new")
      within "form#item-form" do
        fill_in "item[name]", with: name
        select state_label, from: "item[state]"
        fill_in "item[body]", with: words.join("\n")

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Cms::UnfavorableWord.all.count).to eq 1
      Cms::UnfavorableWord.all.first.tap do |item|
        expect(item.site_id).to eq site.id
        expect(item.name).to eq name
        expect(item.state).to eq state
        expect(item.body).to eq words.join("\r\n")
      end

      visit cms_syntax_checker_main_path(site: site)
      click_on I18n.t("mongoid.models.cms/unfavorable_word")
      click_on name
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        fill_in "item[name]", with: name2
        select state2_label, from: "item[state]"
        fill_in "item[body]", with: words2.join("\n")

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Cms::UnfavorableWord.all.count).to eq 1
      Cms::UnfavorableWord.all.first.tap do |item|
        expect(item.site_id).to eq site.id
        expect(item.name).to eq name2
        expect(item.state).to eq state2
        expect(item.body).to eq words2.join("\r\n")
      end

      visit cms_syntax_checker_main_path(site: site)
      click_on I18n.t("mongoid.models.cms/unfavorable_word")
      click_on name2
      click_on I18n.t("ss.links.delete")
      within "form#item-form" do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      expect(Cms::UnfavorableWord.all.count).to eq 0
    end
  end
end
