require 'spec_helper'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let(:now) { Time.zone.now.change(usec: 0) }
  let(:site) { cms_site }
  let!(:group) { create(:cms_group, name: unique_id) }
  let!(:user1) { create(:cms_user, name: unique_id, email: "#{unique_id}@example.jp", group_ids: [ group.id ]) }
  let!(:node) { create :article_node_page, filename: "docs", name: "article" }
  let!(:item1) do
    Timecop.freeze(now - 3.hours) do
      create(:article_page, cur_node: node, cur_user: user1, group_ids: user1.group_ids, state: item_state)
    end
  end
  let!(:item2) do
    Timecop.freeze(now - 2.hours) do
      create(:article_page, cur_node: node, cur_user: cms_user, group_ids: cms_user.group_ids, state: item_state)
    end
  end
  let(:index_path) { article_pages_path site.id, node }

  context "Manipulate Permissions and check accessibility" do
    before do
      cms_user.cms_roles.each do |role|
        role.permissions = role.permissions - ["close_other_article_pages" , "release_other_article_pages"]
        role.save!
      end

    end

    context "check make public if not permitted" do
      let(:item_state) { "closed" }

      it do
        Timecop.freeze(now) do
          login_cms_user

          visit index_path
          within ".list-head" do
            wait_for_event_fired("ss:checked-all-list-items") { find('input[type="checkbox"]').set(true) }
            click_button I18n.t("ss.links.make_them_public")
          end

          within "form" do
            expect(page).to have_css("[data-id='#{item1.id}']", text: I18n.t("ss.confirm.not_allowed_to_publish"))
            expect(page).to have_css("[data-id='#{item2.id}'] [type='checkbox']")
            click_button I18n.t("ss.links.make_them_public")
          end
          wait_for_notice I18n.t("ss.notice.published")
        end

        item1.reload
        expect(item1.state).to eq "closed"
        expect(item1.backups.count).to eq 1 # no changes

        item2.reload
        expect(item2.state).to eq "public"
        expect(item2.backups.count).to eq 2
        item2.backups.to_a.tap do |backups|
          backups[0].tap do |backup|
            expect(backup.created.in_time_zone).to eq now
            expect(backup.data[:state]).to eq "public"
          end
          backups[1].tap do |backup|
            expect(backup.created.in_time_zone).to eq now - 2.hours
            expect(backup.data[:state]).to eq "closed"
          end
        end
      end
    end

    context "check make private if not permitted" do
      let(:item_state) { "public" }

      it do
        Timecop.freeze(now) do
          login_cms_user

          visit index_path
          within ".list-head" do
            wait_for_event_fired("ss:checked-all-list-items") { find('input[type="checkbox"]').set(true) }
            click_button I18n.t('ss.links.make_them_close')
          end

          within "form" do
            expect(page).to have_css("[data-id='#{item1.id}']", text: I18n.t("ss.confirm.not_allowed_to_close"))
            expect(page).to have_css("[data-id='#{item2.id}'] [type='checkbox']")
            click_button I18n.t('ss.links.make_them_close')
          end
          wait_for_notice I18n.t("ss.notice.depublished")
        end

        item1.reload
        expect(item1.state).to eq "public"
        expect(item1.backups.count).to eq 1 # no changes

        item2.reload
        expect(item2.state).to eq "closed"
        expect(item2.backups.count).to eq 2
        item2.backups.to_a.tap do |backups|
          backups[0].tap do |backup|
            expect(backup.created.in_time_zone).to eq now
            expect(backup.data[:state]).to eq "closed"
          end
          backups[1].tap do |backup|
            expect(backup.created.in_time_zone).to eq now - 2.hours
            expect(backup.data[:state]).to eq "public"
          end
        end
      end
    end
  end
end
