require 'spec_helper'

describe Gws::Notice::FoldersTreeComponent::Editable, type: :component, dbscope: :example do
  let!(:site) { gws_site }
  let!(:admin) { gws_user }
  let(:permissions) do
    %w(
      use_gws_notice
      read_private_gws_notices
      read_private_gws_notice_folders
      edit_private_gws_notice_folders
    )
  end
  let!(:role) { create :gws_role, cur_site: site, permissions: permissions }
  let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}" }
  let!(:user1) { create :gws_user, group_ids: [ group1.id ], gws_role_ids: [ role.id ] }

  around do |example|
    with_request_url("/.g#{site.id}/notice/frames/-/-/folders_trees") do
      with_controller_class(Gws::Notice::Frames::FoldersTreesController) do
        example.run
      end
    end
  end

  before do
    @save_perform_caching = described_class.perform_caching
    described_class.perform_caching = true
  end

  after do
    described_class.perform_caching = @save_perform_caching
    Rails.cache.clear
  end

  context "usual case" do
    let!(:folder1) do
      create(
        :gws_notice_folder, cur_site: site, cur_user: admin, group_ids: [], user_ids: [ admin.id ],
        member_group_ids: [], member_ids: [ admin.id ],
        readable_setting_range: "public", readable_group_ids: [], readable_member_ids: [])
    end
    let!(:folder2) do
      create(
        :gws_notice_folder, cur_site: site, cur_user: admin, group_ids: [], user_ids: [ admin.id ],
        member_group_ids: [], member_ids: [ admin.id ],
        readable_setting_range: "select", readable_group_ids: [], readable_member_ids: [ user1.id ])
    end
    let!(:folder3) do
      create(
        :gws_notice_folder, cur_site: site, cur_user: admin, group_ids: [], user_ids: [ admin.id ],
        member_group_ids: [], member_ids: [ admin.id ],
        readable_setting_range: "private", readable_group_ids: [], readable_member_ids: [ admin.id ])
    end
    let!(:folder4) do
      create(
        :gws_notice_folder, cur_site: site, cur_user: admin, group_ids: [], user_ids: [ admin.id ],
        member_group_ids: [], member_ids: [ admin.id, user1.id ],
        readable_setting_range: "private", readable_group_ids: [], readable_member_ids: [ admin.id ])
    end

    context "with admin" do
      let!(:component) { described_class.new(cur_site: site, cur_user: admin) }

      it do
        expect(component.cache_exist?).to be_falsey

        html = render_inline component
        html.css(".content-navi-refresh").tap do |content_navi_refresh|
          expect(content_navi_refresh).to have(1).items
          expect(content_navi_refresh[0].text.strip).to eq "refresh"
        end
        html.css(".gws-notice-folder_tree-menu").tap do |menu|
          expect(menu).to have(1).items
          expect(menu[0].text.strip).to eq I18n.t('gws/notice.all')
        end
        html.css('[name="expand-all"]').tap do |expand_all|
          expect(expand_all).to have(1).items
          expect(expand_all.text.strip).to eq I18n.t("ss.buttons.expand_all")
        end
        html.css('[name="collapse-all"]').tap do |collapse_all|
          expect(collapse_all).to have(1).items
          expect(collapse_all.text.strip).to eq I18n.t("ss.buttons.collapse_all")
        end

        html.css(".ss-tree-item-link[data-node-id='#{folder1.id}']").tap do |tree_item_link|
          expect(tree_item_link).to have(1).items
          expect(tree_item_link.text.strip).to include(folder1.name)
        end
        html.css(".ss-tree-item-link[data-node-id='#{folder2.id}']").tap do |tree_item_link|
          expect(tree_item_link).to have(1).items
          expect(tree_item_link.text.strip).to include(folder2.name)
        end
        html.css(".ss-tree-item-link[data-node-id='#{folder3.id}']").tap do |tree_item_link|
          expect(tree_item_link).to have(1).items
          expect(tree_item_link.text.strip).to include(folder3.name)
        end
        html.css(".ss-tree-item-link[data-node-id='#{folder4.id}']").tap do |tree_item_link|
          expect(tree_item_link).to have(1).items
          expect(tree_item_link.text.strip).to include(folder4.name)
        end

        expect(component.cache_exist?).to be_truthy
      end
    end

    context "with user1" do
      let!(:component) { described_class.new(cur_site: site, cur_user: user1) }

      it do
        expect(component.cache_exist?).to be_falsey

        html = render_inline component
        html.css(".content-navi-refresh").tap do |content_navi_refresh|
          expect(content_navi_refresh).to have(1).items
          expect(content_navi_refresh[0].text.strip).to eq "refresh"
        end
        html.css(".gws-notice-folder_tree-menu").tap do |menu|
          expect(menu).to have(1).items
          expect(menu[0].text.strip).to eq I18n.t('gws/notice.all')
        end
        html.css('[name="expand-all"]').tap do |expand_all|
          expect(expand_all).to have(1).items
          expect(expand_all.text.strip).to eq I18n.t("ss.buttons.expand_all")
        end
        html.css('[name="collapse-all"]').tap do |collapse_all|
          expect(collapse_all).to have(1).items
          expect(collapse_all.text.strip).to eq I18n.t("ss.buttons.collapse_all")
        end

        html.css(".ss-tree-item-link[data-node-id='#{folder1.id}']").tap do |tree_item_link|
          expect(tree_item_link).to have(1).items
          expect(tree_item_link.text.strip).to include(folder1.name)
        end
        html.css(".ss-tree-item-link[data-node-id='#{folder2.id}']").tap do |tree_item_link|
          expect(tree_item_link).to have(1).items
          expect(tree_item_link.text.strip).to include(folder2.name)
        end
        html.css(".ss-tree-item-link[data-node-id='#{folder3.id}']").tap do |tree_item_link|
          expect(tree_item_link).to be_blank
        end
        html.css(".ss-tree-item-link[data-node-id='#{folder4.id}']").tap do |tree_item_link|
          expect(tree_item_link).to have(1).items
          expect(tree_item_link.text.strip).to include(folder4.name)
        end

        expect(component.cache_exist?).to be_truthy
      end
    end
  end
end
