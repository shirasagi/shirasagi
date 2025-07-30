require 'spec_helper'

describe "close_confirmation", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:group) { cms_group }

  let!(:permissions) do
    Cms::Role.permission_names.select { |item| item =~ /_private_/ && item !~ /^release_/ }
  end
  let!(:role) { create :cms_role, name: "role", permissions: permissions, cur_site: site }
  let!(:user1) { create :cms_user, uid: unique_id, name: unique_id, group_ids: [group.id], cms_role_ids: [role.id] }

  def closed?
    script = <<~SCRIPT
      return document.evaluate(
        "//*[@id='addon-cms-agents-addons-release']//dd[contains(text(), '#{I18n.t("ss.options.state.closed")}')]",
        document, null, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null
      ).snapshotLength
    SCRIPT
    page.execute_script(script) > 0
  end

  def expected_alert(save_with, notice = nil)
    within "form#item-form" do
      wait_for_ckeditor_ready(find(:fillable_field, "item[html]"))
      click_button save_with
    end
    expect(page).to have_css("#alertExplanation", text: I18n.t("cms.confirm.close"))
    click_on I18n.t("ss.buttons.ignore_alert")
    wait_for_notice notice || I18n.t('ss.notice.saved')
    if closed?
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
    end
  end

  def unexpected_alert(save_with, notice = nil)
    within "form#item-form" do
      wait_for_ckeditor_ready(find(:fillable_field, "item[html]"))
      click_button save_with
    end
    expect(page).to have_no_css("#alertExplanation", text: I18n.t("cms.confirm.close"))
    wait_for_notice notice || I18n.t("ss.notice.saved")
    if closed?
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
    end
  end

  context "with article/page" do
    let!(:node) { create(:article_node_page, filename: "docs", name: "node", group_ids: [group.id]) }
    let!(:item1) { create :article_page, cur_node: node, state: "public", group_ids: [group.id] }
    let!(:item2) { create :article_page, cur_node: node, state: "closed", group_ids: [group.id] }

    let(:new_path) { new_article_page_path site.id, node }
    let(:edit_public_item_path) { edit_article_page_path site.id, node, item1 }
    let(:edit_closed_item_path) { edit_article_page_path site.id, node, item2 }

    context "with admin" do
      before { login_cms_user }

      context "draft_save" do
        it "#new" do
          visit new_path
          within "form#item-form" do
            fill_in "item[name]", with: "sample"
          end
          unexpected_alert(I18n.t('ss.buttons.draft_save'))
        end

        it "#edit" do
          visit edit_public_item_path
          expected_alert(I18n.t('ss.buttons.withdraw'))

          visit edit_closed_item_path
          unexpected_alert(I18n.t('ss.buttons.draft_save'))
        end
      end

      context "publish" do
        it "#new" do
          visit new_path
          within "form#item-form" do
            fill_in "item[name]", with: "sample"
          end
          unexpected_alert(I18n.t('ss.buttons.publish_save'))
        end

        it "#edit" do
          visit edit_public_item_path
          unexpected_alert(I18n.t('ss.buttons.publish_save'))

          visit edit_closed_item_path
          unexpected_alert(I18n.t('ss.buttons.publish_save'))
        end
      end
    end

    context "with user1" do
      before { login_user user1 }

      context "save" do
        it "#new" do
          visit new_path
          within "form#item-form" do
            fill_in "item[name]", with: "sample"
          end
          unexpected_alert(I18n.t('ss.buttons.save'))
        end

        it "#edit" do
          visit edit_public_item_path
          unexpected_alert(I18n.t('cms.buttons.save_as_branch'), I18n.t('workflow.notice.created_branch_page'))

          visit edit_closed_item_path
          unexpected_alert(I18n.t('ss.buttons.save'))
        end
      end
    end
  end

  context "with cms/page" do
    let!(:node) { create(:cms_node_page, filename: "docs", name: "node", group_ids: [group.id]) }
    let!(:item1) { create :cms_page, cur_node: node, state: "public", group_ids: [group.id] }
    let!(:item2) { create :cms_page, cur_node: node, state: "closed", group_ids: [group.id] }

    let(:new_path) { new_node_page_path site.id, node }
    let(:edit_public_item_path) { edit_node_page_path site.id, node, item1 }
    let(:edit_closed_item_path) { edit_node_page_path site.id, node, item2 }

    context "with admin" do
      before { login_cms_user }

      context "draft_save" do
        it "#new" do
          visit new_path
          within "form#item-form" do
            fill_in "item[name]", with: "sample"
            fill_in "item[basename]", with: "sample"
          end
          unexpected_alert(I18n.t('ss.buttons.draft_save'))
        end

        it "#edit" do
          visit edit_public_item_path
          expected_alert(I18n.t('ss.buttons.withdraw'))

          visit edit_closed_item_path
          unexpected_alert(I18n.t('ss.buttons.draft_save'))
        end
      end

      context "publish" do
        it "#new" do
          visit new_path
          within "form#item-form" do
            fill_in "item[name]", with: "sample"
            fill_in "item[basename]", with: "sample"
          end
          unexpected_alert(I18n.t('ss.buttons.publish_save'))
        end

        it "#edit" do
          visit edit_public_item_path
          unexpected_alert(I18n.t('ss.buttons.publish_save'))

          visit edit_closed_item_path
          unexpected_alert(I18n.t('ss.buttons.publish_save'))
        end
      end
    end

    context "with user1" do
      before { login_user user1 }

      context "save" do
        it "#new" do
          visit new_path
          within "form#item-form" do
            fill_in "item[name]", with: "sample"
            fill_in "item[basename]", with: "sample"
          end
          unexpected_alert(I18n.t('ss.buttons.save'))
        end

        it "#edit" do
          visit edit_public_item_path
          unexpected_alert(I18n.t('cms.buttons.save_as_branch'), I18n.t('workflow.notice.created_branch_page'))

          visit edit_closed_item_path
          unexpected_alert(I18n.t('ss.buttons.save'))
        end
      end
    end
  end

  context "with event/page" do
    let!(:node) { create(:event_node_page, filename: "docs", name: "node", group_ids: [group.id]) }
    let!(:item1) { create :event_page, cur_node: node, state: "public", group_ids: [group.id] }
    let!(:item2) { create :event_page, cur_node: node, state: "closed", group_ids: [group.id] }

    let(:new_path) { new_event_page_path site.id, node }
    let(:edit_public_item_path) { edit_event_page_path site.id, node, item1 }
    let(:edit_closed_item_path) { edit_event_page_path site.id, node, item2 }

    context "with admin" do
      before { login_cms_user }

      context "draft_save" do
        it "#new" do
          visit new_path
          within "form#item-form" do
            fill_in "item[name]", with: "sample"
          end
          unexpected_alert(I18n.t('ss.buttons.draft_save'))
        end

        it "#edit" do
          visit edit_public_item_path
          expected_alert(I18n.t('ss.buttons.withdraw'))

          visit edit_closed_item_path
          unexpected_alert(I18n.t('ss.buttons.draft_save'))
        end
      end

      context "publish" do
        it "#new" do
          visit new_path
          within "form#item-form" do
            fill_in "item[name]", with: "sample"
          end
          unexpected_alert(I18n.t('ss.buttons.publish_save'))
        end

        it "#edit" do
          visit edit_public_item_path
          unexpected_alert(I18n.t('ss.buttons.publish_save'))

          visit edit_closed_item_path
          unexpected_alert(I18n.t('ss.buttons.publish_save'))
        end
      end
    end

    context "with user1" do
      before { login_user user1 }

      context "save" do
        it "#new" do
          visit new_path
          within "form#item-form" do
            fill_in "item[name]", with: "sample"
          end
          unexpected_alert(I18n.t('ss.buttons.save'))
        end

        it "#edit" do
          visit edit_public_item_path
          unexpected_alert(I18n.t('cms.buttons.save_as_branch'), I18n.t('workflow.notice.created_branch_page'))

          visit edit_closed_item_path
          unexpected_alert(I18n.t('ss.buttons.save'))
        end
      end
    end
  end
end
