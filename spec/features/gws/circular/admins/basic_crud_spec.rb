require 'spec_helper'

describe "gws_circular_admins", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:user1) { create(:gws_user, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids) }

  context "basic crud" do
    let(:name) { unique_id }
    let(:name2) { unique_id }

    before { login_gws_user }

    it do
      #
      # Create as draft
      #
      visit gws_circular_admins_path(site)
      click_on I18n.t("ss.links.new")

      within "form#item-form" do
        fill_in "item[name]", with: name
        within "#addon-gws-agents-addons-member" do
          wait_cbox_open { click_on I18n.t("ss.apis.users.index") }
        end
      end
      wait_for_cbox do
        click_on user1.name
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.draft_save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      expect(Gws::Circular::Post.all.topic.count).to eq 1
      topic = Gws::Circular::Post.all.topic.first
      expect(topic.site_id).to eq site.id
      expect(topic.name).to eq name
      expect(topic.member_ids).to include(user1.id)
      expect(topic.state).to eq "draft"
      expect(topic.deleted).to be_blank

      expect(SS::Notification.all.count).to eq 0

      #
      # Update name and Publish
      #
      visit gws_circular_admins_path(site)
      click_on topic.name
      click_on I18n.t("ss.links.edit")

      within "form#item-form" do
        fill_in "item[name]", with: name2
        click_on I18n.t("ss.buttons.publish_save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      expect(Gws::Circular::Post.all.topic.count).to eq 1
      topic.reload
      expect(topic.site_id).to eq site.id
      expect(topic.name).to eq name2
      expect(topic.member_ids).to include(user1.id)
      expect(topic.state).to eq "public"
      expect(topic.deleted).to be_blank

      save_updated = topic.updated
      save_created = topic.created

      expect(SS::Notification.all.count).to eq 1
      SS::Notification.all.reorder(id: -1).first.tap do |notice|
        expect(notice.group_id).to eq site.id
        expect(notice.member_ids).to eq [ user1.id ]
        expect(notice.user_id).to eq gws_user.id
        expect(notice.subject).to eq I18n.t("gws_notification.gws/circular/post.subject", name: topic.name)
        expect(notice.text).to be_blank
        expect(notice.html).to be_blank
        expect(notice.format).to eq "text"
        expect(notice.user_settings).to be_blank
        expect(notice.state).to eq "public"
        expect(notice.send_date).to be_present
        expect(notice.url).to eq "/.g#{site.id}/circular/-/posts/#{topic.id}"
        expect(notice.reply_module).to be_blank
        expect(notice.reply_model).to be_blank
        expect(notice.reply_item_id).to be_blank
      end

      #
      # Delete (soft delete)
      #
      visit gws_circular_admins_path(site)
      click_on topic.name
      within ".nav-menu" do
        click_on I18n.t("ss.links.delete")
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.delete")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))

      topic.reload
      expect(topic.deleted).to be_present
      expect(topic.updated).to eq save_updated
      expect(topic.created).to eq save_created

      # no notifications are send on deleting circular
      expect(SS::Notification.all.count).to eq 1

      #
      # Restore (Undo delete)
      #
      visit gws_circular_admins_path(site)
      click_on I18n.t("ss.links.trash")
      click_on topic.name
      within ".nav-menu" do
        click_on I18n.t("ss.links.restore")
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.restore")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.restored'))

      topic.reload
      expect(topic.deleted).to be_blank
      expect(topic.updated).to eq save_updated
      expect(topic.created).to eq save_created

      # no notifications are send on deleting circular
      expect(SS::Notification.all.count).to eq 1

      #
      # Delete (sort delete --> hard delete)
      #
      visit gws_circular_admins_path(site)
      click_on topic.name
      within ".nav-menu" do
        click_on I18n.t("ss.links.delete")
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.delete")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))

      visit gws_circular_admins_path(site)
      click_on I18n.t("gws/circular.tabs.trash")
      click_on topic.name
      within ".nav-menu" do
        click_on I18n.t("ss.links.delete")
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.delete")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))

      expect(Gws::Circular::Post.all.topic.count).to eq 0
      expect { Gws::Circular::Post.all.find(topic.id) }.to raise_error Mongoid::Errors::DocumentNotFound

      # no notifications are send on deleting circular
      expect(SS::Notification.all.count).to eq 1
    end
  end

  context "create with category" do
    let!(:cate1) { create(:gws_circular_category) }
    let!(:cate2) { create(:gws_circular_category) }
    let(:name) { unique_id }
    let(:name2) { unique_id }

    before { login_gws_user }

    it do
      # Create as draft with cate1
      visit gws_circular_admins_path(site)
      click_on I18n.t("ss.links.new")

      within "form#item-form" do
        fill_in "item[name]", with: name
      end

      within "form#item-form" do
        within "#addon-gws-agents-addons-circular-category" do
          wait_cbox_open { click_on I18n.t('gws.apis.categories.index') }
        end
      end
      wait_for_cbox do
        click_on cate1.name
      end

      within "form#item-form" do
        within "#addon-gws-agents-addons-member" do
          wait_cbox_open { click_on I18n.t("ss.apis.users.index") }
        end
      end
      wait_for_cbox do
        click_on user1.name
      end

      within "form#item-form" do
        click_on I18n.t("ss.buttons.draft_save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      expect(Gws::Circular::Post.all.topic.count).to eq 1
      topic = Gws::Circular::Post.all.topic.first
      expect(topic.site_id).to eq site.id
      expect(topic.name).to eq name
      expect(topic.member_ids).to include(user1.id)
      expect(topic.state).to eq "draft"
      expect(topic.category_ids).to include(cate1.id)
      expect(topic.deleted).to be_blank

      expect(SS::Notification.all.count).to eq 0
    end
  end

  context "when public post turned to draft" do
    let(:name) { unique_id }

    before { login_gws_user }

    it do
      #
      # Create as public
      #
      visit gws_circular_admins_path(site)
      click_on I18n.t("ss.links.new")

      within "form#item-form" do
        fill_in "item[name]", with: name
        within "#addon-gws-agents-addons-member" do
          wait_cbox_open { click_on I18n.t("ss.apis.users.index") }
        end
      end
      wait_for_cbox do
        click_on user1.name
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.publish_save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      expect(Gws::Circular::Post.all.topic.count).to eq 1
      topic = Gws::Circular::Post.all.topic.first
      expect(topic.site_id).to eq site.id
      expect(topic.name).to eq name
      expect(topic.member_ids).to include(user1.id)
      expect(topic.state).to eq "public"
      expect(topic.deleted).to be_blank

      expect(SS::Notification.all.count).to eq 1
      SS::Notification.all.reorder(id: -1).first.tap do |notice|
        expect(notice.group_id).to eq site.id
        expect(notice.member_ids).to eq [ user1.id ]
        expect(notice.user_id).to eq gws_user.id
        expect(notice.subject).to eq I18n.t("gws_notification.gws/circular/post.subject", name: topic.name)
        expect(notice.text).to be_blank
        expect(notice.html).to be_blank
        expect(notice.format).to eq "text"
        expect(notice.user_settings).to be_blank
        expect(notice.state).to eq "public"
        expect(notice.send_date).to be_present
        expect(notice.url).to eq "/.g#{site.id}/circular/-/posts/#{topic.id}"
        expect(notice.reply_module).to be_blank
        expect(notice.reply_model).to be_blank
        expect(notice.reply_item_id).to be_blank
      end

      #
      # Make post draft
      #
      visit gws_circular_admins_path(site)
      click_on topic.name
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        click_on I18n.t("ss.buttons.draft_save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      expect(Gws::Circular::Post.all.topic.count).to eq 1
      topic = Gws::Circular::Post.all.topic.first
      expect(topic.site_id).to eq site.id
      expect(topic.name).to eq name
      expect(topic.member_ids).to include(user1.id)
      expect(topic.state).to eq "draft"
      expect(topic.deleted).to be_blank

      expect(SS::Notification.all.count).to eq 2
      SS::Notification.all.reorder(id: -1).first.tap do |notice|
        expect(notice.group_id).to eq site.id
        expect(notice.member_ids).to eq [ user1.id ]
        expect(notice.user_id).to eq gws_user.id
        expect(notice.subject).to eq I18n.t("gws_notification.gws/circular/post/remove.subject", name: topic.name)
        expect(notice.text).to be_blank
        expect(notice.html).to be_blank
        expect(notice.format).to eq "text"
        expect(notice.user_settings).to be_blank
        expect(notice.state).to eq "public"
        expect(notice.send_date).to be_present
        expect(notice.url).to be_blank
        expect(notice.reply_module).to be_blank
        expect(notice.reply_model).to be_blank
        expect(notice.reply_item_id).to be_blank
      end
    end
  end

  context "when member is removed from published post" do
    let!(:user2) { create(:gws_user, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids) }
    let(:name) { unique_id }

    before { login_gws_user }

    it do
      #
      # Create as public
      #
      visit gws_circular_admins_path(site)
      click_on I18n.t("ss.links.new")

      within "form#item-form" do
        fill_in "item[name]", with: name
        within "#addon-gws-agents-addons-member" do
          wait_cbox_open { click_on I18n.t("ss.apis.users.index") }
        end
      end
      wait_for_cbox do
        # click_on user1.name
        first("[data-id='#{user1.id}'] input[type='checkbox']").click
        # click_on user2.name
        first("[data-id='#{user2.id}'] input[type='checkbox']").click

        click_on I18n.t("ss.links.select")
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.publish_save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      expect(Gws::Circular::Post.all.topic.count).to eq 1
      topic = Gws::Circular::Post.all.topic.first
      expect(topic.site_id).to eq site.id
      expect(topic.name).to eq name
      expect(topic.member_ids).to include(user1.id, user2.id)
      expect(topic.state).to eq "public"
      expect(topic.deleted).to be_blank

      expect(SS::Notification.all.count).to eq 1
      SS::Notification.all.reorder(id: -1).first.tap do |notice|
        expect(notice.group_id).to eq site.id
        expect(notice.members.count).to eq 2
        expect(notice.member_ids).to include(user1.id, user2.id)
        expect(notice.user_id).to eq gws_user.id
        expect(notice.subject).to eq I18n.t("gws_notification.gws/circular/post.subject", name: topic.name)
        expect(notice.text).to be_blank
        expect(notice.html).to be_blank
        expect(notice.format).to eq "text"
        expect(notice.user_settings).to be_blank
        expect(notice.state).to eq "public"
        expect(notice.send_date).to be_present
        expect(notice.url).to eq "/.g#{site.id}/circular/-/posts/#{topic.id}"
        expect(notice.reply_module).to be_blank
        expect(notice.reply_model).to be_blank
        expect(notice.reply_item_id).to be_blank
      end

      #
      # Remove user1
      #
      visit gws_circular_admins_path(site)
      click_on topic.name
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        within "#addon-gws-agents-addons-member" do
          within ".ajax-selected [data-id='#{user1.id}']" do
            click_on I18n.t("ss.buttons.delete")
          end
        end
        click_on I18n.t("ss.buttons.publish_save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      expect(Gws::Circular::Post.all.topic.count).to eq 1
      topic = Gws::Circular::Post.all.topic.first
      expect(topic.site_id).to eq site.id
      expect(topic.name).to eq name
      expect(topic.member_ids).not_to include(user1.id)
      expect(topic.member_ids).to include(user2.id)
      expect(topic.state).to eq "public"
      expect(topic.deleted).to be_blank

      expect(SS::Notification.all.count).to eq 2
      SS::Notification.all.reorder(id: -1).first.tap do |notice|
        expect(notice.group_id).to eq site.id
        expect(notice.member_ids).to eq [ user1.id ]
        expect(notice.user_id).to eq gws_user.id
        expect(notice.subject).to eq I18n.t("gws_notification.gws/circular/post/remove.subject", name: topic.name)
        expect(notice.text).to be_blank
        expect(notice.html).to be_blank
        expect(notice.format).to eq "text"
        expect(notice.user_settings).to be_blank
        expect(notice.state).to eq "public"
        expect(notice.send_date).to be_present
        expect(notice.url).to be_blank
        expect(notice.reply_module).to be_blank
        expect(notice.reply_model).to be_blank
        expect(notice.reply_item_id).to be_blank
      end
    end
  end
end
