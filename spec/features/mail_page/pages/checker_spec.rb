require 'spec_helper'

describe "event_pages", type: :feature, js: true do
  let!(:site) { cms_site }
  let!(:node) { create :mail_page_node_page, cur_site: site }

  context "with some errors" do
    let(:path1) { unique_id }
    let(:html1) do
      <<~HTML
        <img src="/#{unique_id}" >
        <a href="#{path1}">#{unique_id}</a>
      HTML
    end

    it do
      login_cms_user to: mail_page_pages_path(site: site, cid: node)
      click_on I18n.t("ss.links.new")
      within "form#item-form" do
        fill_in_ckeditor "item[html]", with: html1
        wait_for_event_fired "ss:check:done" do
          within ".cms-body-checker" do
            click_on I18n.t("ss.buttons.run")
          end
        end

        expect(page).to have_css("#errorSyntaxChecker", text: I18n.t("errors.messages.set_img_alt"))
        expect(page).to have_css('#errorLinkChecker', text: "#{I18n.t("errors.messages.link_check_failure")} #{path1}")
      end
    end
  end

  context "without errors" do
    let(:html1) do
      <<~HTML
        <h2>#{unique_id}</h2>
        <p>#{unique_id}</p>
      HTML
    end

    it do
      login_cms_user to: mail_page_pages_path(site: site, cid: node)
      click_on I18n.t("ss.links.new")
      within "form#item-form" do
        fill_in_ckeditor "item[html]", with: html1
        wait_for_event_fired "ss:check:done" do
          within ".cms-body-checker" do
            click_on I18n.t("ss.buttons.run")
          end
        end

        expect(page).to have_css("#errorSyntaxChecker", text: I18n.t("errors.template.no_errors"))
        expect(page).to have_css('#errorLinkChecker', text: I18n.t("errors.template.no_links"))
      end
    end
  end
end
