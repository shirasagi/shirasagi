require 'spec_helper'

describe "move_cms_pages", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:show_path) { node_page_path site, node1, item }

  let!(:item) { create :cms_page, cur_node: node1 }
  let!(:node1) { create :cms_node_page }
  let!(:node2) { create :cms_node_page }

  let(:destination) { ::File.join(node2.filename, "#{unique_id}.html") }

  context "with auth" do
    before { login_cms_user }
    after do
      Fs.rm_rf node1.path
      Fs.rm_rf node2.path
    end

    context "move master page" do
      it "#move" do
        visit show_path

        # create branch
        ensure_addon_opened("#addon-workflow-agents-addons-branch")
        within "#addon-workflow-agents-addons-branch" do
          click_button I18n.t('workflow.create_branch')
          expect(page).to have_css('.see.branch', text: item.name)
        end

        # move
        within "#menu" do
          click_on I18n.t('ss.links.move')
        end
        within "form#item-form" do
          expect(page).to have_css(".current-filename", text: item.filename)
          fill_in "destination", with: destination
          click_button I18n.t('ss.buttons.move')
        end
        wait_for_notice I18n.t("ss.notice.moved")

        within "form#item-form" do
          expect(page).to have_css(".current-filename", text: destination)
          expect(page).to have_css(".cms-apis-contents-html-page", text: I18n.t("cms.apis.contents.result"))
        end

        # check branch page
        within "#menu" do
          click_on I18n.t('ss.links.back_to_index')
        end
        within ".list-items" do
          expect(page).to have_css('.list-item a', text: item.name, count: 2)
        end

        item.reload
        expect(item.filename).to eq destination
        expect(item.filename).to start_with node2.filename

        branch_page = item.branches.first
        expect(branch_page.filename).to start_with node2.filename
      end
    end

    context "move branch page" do
      it "#move" do
        visit show_path

        # create branch
        ensure_addon_opened("#addon-workflow-agents-addons-branch")
        within "#addon-workflow-agents-addons-branch" do
          click_button I18n.t('workflow.create_branch')
          expect(page).to have_css('.see.branch', text: item.name)
          click_link item.name
        end
        within "#addon-workflow-agents-addons-branch" do
          expect(page).to have_css('.see.master', text: I18n.t('workflow.branch_message'))
        end

        # move
        within "#menu" do
          click_on I18n.t('ss.links.move')
        end
        within "form#item-form" do
          expect(page).to have_text I18n.t("cms.move_page.branch_page_error")
        end
      end
    end
  end
end
