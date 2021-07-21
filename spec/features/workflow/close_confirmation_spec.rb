require 'spec_helper'

describe "close_confirmation", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:group) { cms_group }

  let!(:permissions) do
    Cms::Role.permission_names.select { |item| item =~ /_private_/ && item !~ /^release_/ }
  end
  let!(:role) { create :cms_role, name: "role", permissions: permissions, cur_site: site }
  let!(:user1) { create :cms_user, uid: unique_id, name: unique_id, group_ids: [group.id], cms_role_ids: [role.id] }

  def expected_alert(save_with)
    within "form#item-form" do
      click_button save_with
    end
    expect(page).to have_css("#alertExplanation", text: I18n.t("cms.confirm.close"))
    click_on I18n.t("ss.buttons.ignore_alert")
    expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
    wait_for_ajax
  end

  def unexpected_alert(save_with)
    within "form#item-form" do
      click_button save_with
    end
    expect(page).to have_no_css("#alertExplanation", text: I18n.t("cms.confirm.close"))
    wait_for_notice I18n.t("ss.notice.saved")
    wait_for_ajax
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
          expected_alert(I18n.t('ss.buttons.draft_save'))

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
          expected_alert(I18n.t('ss.buttons.save'))

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
          expected_alert(I18n.t('ss.buttons.draft_save'))

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
          expected_alert(I18n.t('ss.buttons.save'))

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
          expected_alert(I18n.t('ss.buttons.draft_save'))

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
          expected_alert(I18n.t('ss.buttons.save'))

          visit edit_closed_item_path
          unexpected_alert(I18n.t('ss.buttons.save'))
        end
      end
    end
  end
end
