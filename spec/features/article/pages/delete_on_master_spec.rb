require 'spec_helper'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:node) { create :article_node_page }
  let!(:item) { create :article_page, cur_node: node }

  before { login_cms_user }

  context "branches are existed" do
    context "on show view" do
      it do
        visit article_pages_path(site: site, cid: node)
        click_on item.name
        within '#addon-workflow-agents-addons-branch' do
          wait_for_turbo_frame "#workflow-branch-frame"
          wait_event_to_fire "turbo:frame-load" do
            click_on I18n.t("workflow.create_branch")
          end
          expect(page).to have_css('.see.branch', text: I18n.t("workflow.notice.created_branch_page"))
          expect(page).to have_css('table.branches')
          expect(page).to have_css('.see.branch', text: item.name)
        end

        # visit show_path
        click_on I18n.t("ss.links.delete")
        expect(page).to have_css(".addon-head", text: I18n.t('workflow.confirm.unable_to_delete_master_page'))
        within "form" do
          expect(page).to have_no_css(".send", text: I18n.t("ss.buttons.delete"))
        end
      end
    end

    context "on index view (#5195)" do
      it do
        visit article_pages_path(site: site, cid: node)
        click_on item.name
        within '#addon-workflow-agents-addons-branch' do
          wait_for_turbo_frame "#workflow-branch-frame"
          wait_event_to_fire "turbo:frame-load" do
            click_on I18n.t("workflow.create_branch")
          end
          expect(page).to have_css('.see.branch', text: I18n.t("workflow.notice.created_branch_page"))
          expect(page).to have_css('table.branches')
          expect(page).to have_css('.see.branch', text: item.name)
        end

        visit article_pages_path(site: site, cid: node)
        within "[data-id='#{item.id}']" do
          first('[type="checkbox"]').click
        end
        wait_for_js_ready
        within ".list-head-action" do
          click_on I18n.t("ss.buttons.delete")
        end
        within "form" do
          expect(page).to have_css(".addon-head", text: I18n.t("ss.confirm.target_to_delete"))
          expect(page).to have_css(".info", text: "差し替えページが作成されているため削除できません。")
          # Checkbox isn't displyaed, or checkbox is disabled.
          expect(page).to have_no_css('[type="checkbox"]')
          expect(first('[type="checkbox"]')["disabled"]).to be_truthy
          # The "Delete" button shall be displayed.
          expect(page).to have_css(".send", text: I18n.t("ss.buttons.delete"))
        end
      end
    end
  end
end
