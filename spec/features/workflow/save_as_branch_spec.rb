require 'spec_helper'

describe "close_confirmation", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:group) { cms_group }

  let!(:permissions) do
    Cms::Role.permission_names.select { |item| item =~ /_private_/ && item !~ /^release_/ }
  end
  let!(:role) { create :cms_role, name: unique_id, permissions: permissions, cur_site: site }
  let!(:user1) { create :cms_user, uid: unique_id, name: unique_id, group_ids: [group.id], cms_role_ids: [role.id] }

  context "with article/page" do
    let!(:node) { create(:article_node_page, group_ids: [group.id]) }
    let!(:item1) { create :article_page, cur_node: node, state: "public", group_ids: [group.id] }
    let!(:item2) { create :article_page, cur_node: node, state: "closed", group_ids: [group.id] }

    let(:edit_public_item_path) { edit_article_page_path site.id, node, item1 }
    let(:edit_closed_item_path) { edit_article_page_path site.id, node, item2 }

    context "with admin" do
      before { login_cms_user }

      it do
        visit edit_public_item_path
        expect(page).to have_css(".save[value='#{I18n.t("ss.buttons.withdraw")}']")
        expect(page).to have_css(".branch_save[value='#{I18n.t("cms.buttons.save_as_branch")}']")
        expect(page).to have_css(".publish_save[value='#{I18n.t("ss.buttons.publish_save")}']")
      end

      it do
        visit edit_closed_item_path
        expect(page).to have_css(".save[value='#{I18n.t("ss.buttons.draft_save")}']")
        expect(page).to have_no_css(".branch_save")
        expect(page).to have_css(".publish_save[value='#{I18n.t("ss.buttons.publish_save")}']")
      end
    end

    context "with user1" do
      before { login_user user1 }

      it do
        visit edit_public_item_path
        expect(page).to have_no_css(".save")
        expect(page).to have_css(".branch_save[value='#{I18n.t("cms.buttons.save_as_branch")}']")
        expect(page).to have_no_css(".publish_save")

        within "#item-form" do
          fill_in "item[name]", with: unique_id
          fill_in_ckeditor "item[html]", with: unique_id

          click_on I18n.t('cms.buttons.save_as_branch')
        end
        wait_for_notice I18n.t("workflow.notice.created_branch_page")

        item1.reload
        expect(item1.master?).to be_truthy
        expect(item1.branches).to have(1).items
        item1.branches.first.tap do |branch|
          expect(branch).to be_present
          expect(branch.branch?).to be_truthy
          expect(branch.master_id).to eq item1.id
        end

        within "#addon-workflow-agents-addons-branch" do
          expect(page).to have_css(".master .branches", text: item1.name)
        end
      end

      it do
        visit edit_closed_item_path
        expect(page).to have_css(".save[value='#{I18n.t("ss.buttons.save")}']")
        expect(page).to have_no_css(".branch_save")
        expect(page).to have_no_css(".publish_save")
      end
    end

    context "when page has branch page" do
      let!(:item1_branch) { create :article_page, cur_node: node, master: item1, state: "closed", group_ids: [group.id] }
      let!(:item2_branch) { create :article_page, cur_node: node, master: item2, state: "closed", group_ids: [group.id] }

      before do
        item1.branch_ids = [ item1_branch.id ]
        item1.save!
        item2.branch_ids = [ item2_branch.id ]
        item2.save!
      end

      context "with admin" do
        before { login_cms_user }

        it do
          visit edit_public_item_path
          expect(page).to have_css(".save[value='#{I18n.t("ss.buttons.withdraw")}']")
          expect(page).to have_no_css(".branch_save")
          expect(page).to have_css(".publish_save[value='#{I18n.t("ss.buttons.publish_save")}']")
        end

        it do
          visit edit_closed_item_path
          expect(page).to have_css(".save[value='#{I18n.t("ss.buttons.draft_save")}']")
          expect(page).to have_no_css(".branch_save")
          expect(page).to have_css(".publish_save[value='#{I18n.t("ss.buttons.publish_save")}']")
        end
      end

      context "with user1" do
        before { login_user user1 }

        it do
          visit edit_public_item_path
          expect(page).to have_no_css(".save")
          expect(page).to have_no_css(".branch_save")
          expect(page).to have_no_css(".publish_save")
        end

        it do
          visit edit_closed_item_path
          expect(page).to have_css(".save[value='#{I18n.t("ss.buttons.save")}']")
          expect(page).to have_no_css(".branch_save")
          expect(page).to have_no_css(".publish_save")
        end
      end
    end
  end

  context "with cms/page" do
    let!(:node) { create(:cms_node_page, group_ids: [group.id]) }
    let!(:item1) { create :cms_page, cur_node: node, state: "public", group_ids: [group.id] }
    let!(:item2) { create :cms_page, cur_node: node, state: "closed", group_ids: [group.id] }

    let(:edit_public_item_path) { edit_node_page_path site.id, node, item1 }
    let(:edit_closed_item_path) { edit_node_page_path site.id, node, item2 }

    context "with admin" do
      before { login_cms_user }

      it do
        visit edit_public_item_path
        expect(page).to have_css(".save[value='#{I18n.t("ss.buttons.withdraw")}']")
        expect(page).to have_css(".branch_save[value='#{I18n.t("cms.buttons.save_as_branch")}']")
        expect(page).to have_css(".publish_save[value='#{I18n.t("ss.buttons.publish_save")}']")
      end

      it do
        visit edit_closed_item_path
        expect(page).to have_css(".save[value='#{I18n.t("ss.buttons.draft_save")}']")
        expect(page).to have_no_css(".branch_save")
        expect(page).to have_css(".publish_save[value='#{I18n.t("ss.buttons.publish_save")}']")
      end
    end

    context "with user1" do
      before { login_user user1 }

      it do
        visit edit_public_item_path
        expect(page).to have_no_css(".save")
        expect(page).to have_css(".branch_save[value='#{I18n.t("cms.buttons.save_as_branch")}']")
        expect(page).to have_no_css(".publish_save")

        within "#item-form" do
          fill_in "item[name]", with: unique_id
          fill_in_ckeditor "item[html]", with: unique_id

          click_on I18n.t('cms.buttons.save_as_branch')
        end
        wait_for_notice I18n.t("workflow.notice.created_branch_page")

        item1.reload
        expect(item1.master?).to be_truthy
        expect(item1.branches).to have(1).items
        item1.branches.first.tap do |branch|
          expect(branch).to be_present
          expect(branch.branch?).to be_truthy
          expect(branch.master_id).to eq item1.id
        end

        within "#addon-workflow-agents-addons-branch" do
          expect(page).to have_css(".master .branches", text: item1.name)
        end
      end

      it do
        visit edit_closed_item_path
        expect(page).to have_css(".save[value='#{I18n.t("ss.buttons.save")}']")
        expect(page).to have_no_css(".branch_save")
        expect(page).to have_no_css(".publish_save")
      end
    end

    context "when page has branch page" do
      let!(:item1_branch) { create :cms_page, cur_node: node, master: item1, state: "closed", group_ids: [group.id] }
      let!(:item2_branch) { create :cms_page, cur_node: node, master: item2, state: "closed", group_ids: [group.id] }

      before do
        item1.branch_ids = [ item1_branch.id ]
        item1.save!
        item2.branch_ids = [ item2_branch.id ]
        item2.save!
      end

      context "with admin" do
        before { login_cms_user }

        it do
          visit edit_public_item_path
          expect(page).to have_css(".save[value='#{I18n.t("ss.buttons.withdraw")}']")
          expect(page).to have_no_css(".branch_save")
          expect(page).to have_css(".publish_save[value='#{I18n.t("ss.buttons.publish_save")}']")
        end

        it do
          visit edit_closed_item_path
          expect(page).to have_css(".save[value='#{I18n.t("ss.buttons.draft_save")}']")
          expect(page).to have_no_css(".branch_save")
          expect(page).to have_css(".publish_save[value='#{I18n.t("ss.buttons.publish_save")}']")
        end
      end

      context "with user1" do
        before { login_user user1 }

        it do
          visit edit_public_item_path
          expect(page).to have_no_css(".save")
          expect(page).to have_no_css(".branch_save")
          expect(page).to have_no_css(".publish_save")
        end

        it do
          visit edit_closed_item_path
          expect(page).to have_css(".save[value='#{I18n.t("ss.buttons.save")}']")
          expect(page).to have_no_css(".branch_save")
          expect(page).to have_no_css(".publish_save")
        end
      end
    end
  end

  context "with event/page" do
    let!(:node) { create(:event_node_page, group_ids: [group.id]) }
    let!(:item1) { create :event_page, cur_node: node, state: "public", group_ids: [group.id] }
    let!(:item2) { create :event_page, cur_node: node, state: "closed", group_ids: [group.id] }

    let(:edit_public_item_path) { edit_event_page_path site.id, node, item1 }
    let(:edit_closed_item_path) { edit_event_page_path site.id, node, item2 }

    context "with admin" do
      before { login_cms_user }

      it do
        visit edit_public_item_path
        expect(page).to have_css(".save[value='#{I18n.t("ss.buttons.withdraw")}']")
        expect(page).to have_css(".branch_save[value='#{I18n.t("cms.buttons.save_as_branch")}']")
        expect(page).to have_css(".publish_save[value='#{I18n.t("ss.buttons.publish_save")}']")
      end

      it do
        visit edit_closed_item_path
        expect(page).to have_css(".save[value='#{I18n.t("ss.buttons.draft_save")}']")
        expect(page).to have_no_css(".branch_save")
        expect(page).to have_css(".publish_save[value='#{I18n.t("ss.buttons.publish_save")}']")
      end
    end

    context "with user1" do
      before { login_user user1 }

      it do
        visit edit_public_item_path
        expect(page).to have_no_css(".save")
        expect(page).to have_css(".branch_save[value='#{I18n.t("cms.buttons.save_as_branch")}']")
        expect(page).to have_no_css(".publish_save")

        within "#item-form" do
          fill_in "item[name]", with: unique_id
          fill_in_ckeditor "item[html]", with: unique_id

          click_on I18n.t('cms.buttons.save_as_branch')
        end
        wait_for_notice I18n.t("workflow.notice.created_branch_page")

        item1.reload
        expect(item1.master?).to be_truthy
        expect(item1.branches).to have(1).items
        item1.branches.first.tap do |branch|
          expect(branch).to be_present
          expect(branch.branch?).to be_truthy
          expect(branch.master_id).to eq item1.id
        end

        within "#addon-workflow-agents-addons-branch" do
          expect(page).to have_css(".master .branches", text: item1.name)
        end
      end

      it do
        visit edit_closed_item_path
        expect(page).to have_css(".save[value='#{I18n.t("ss.buttons.save")}']")
        expect(page).to have_no_css(".branch_save")
        expect(page).to have_no_css(".publish_save")
      end
    end

    context "when page has branch page" do
      let!(:item1_branch) { create :event_page, cur_node: node, master: item1, state: "closed", group_ids: [group.id] }
      let!(:item2_branch) { create :event_page, cur_node: node, master: item2, state: "closed", group_ids: [group.id] }

      before do
        item1.branch_ids = [ item1_branch.id ]
        item1.save!
        item2.branch_ids = [ item2_branch.id ]
        item2.save!
      end

      context "with admin" do
        before { login_cms_user }

        it do
          visit edit_public_item_path
          expect(page).to have_css(".save[value='#{I18n.t("ss.buttons.withdraw")}']")
          expect(page).to have_no_css(".branch_save")
          expect(page).to have_css(".publish_save[value='#{I18n.t("ss.buttons.publish_save")}']")
        end

        it do
          visit edit_closed_item_path
          expect(page).to have_css(".save[value='#{I18n.t("ss.buttons.draft_save")}']")
          expect(page).to have_no_css(".branch_save")
          expect(page).to have_css(".publish_save[value='#{I18n.t("ss.buttons.publish_save")}']")
        end
      end

      context "with user1" do
        before { login_user user1 }

        it do
          visit edit_public_item_path
          expect(page).to have_no_css(".save")
          expect(page).to have_no_css(".branch_save")
          expect(page).to have_no_css(".publish_save")
        end

        it do
          visit edit_closed_item_path
          expect(page).to have_css(".save[value='#{I18n.t("ss.buttons.save")}']")
          expect(page).to have_no_css(".branch_save")
          expect(page).to have_no_css(".publish_save")
        end
      end
    end
  end
end
