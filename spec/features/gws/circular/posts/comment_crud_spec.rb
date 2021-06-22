require 'spec_helper'

describe "gws_circular_posts", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:now) { Time.zone.now.beginning_of_minute }
  let!(:user1) { create(:gws_user, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids) }
  let!(:cate1) { create(:gws_circular_category) }

  before { login_user user1 }

  describe "basic comment crud" do
    let!(:item) do
      create(
        :gws_circular_post, cur_user: gws_user, due_date: now + 1.day, category_ids: [ cate1.id ], member_ids: [ user1.id ],
        state: "public", user_ids: [ gws_user.id ]
      )
    end
    let(:texts) { Array.new(rand(2..3)) { unique_id } }
    let(:texts2) { Array.new(rand(2..3)) { unique_id } }

    it do
      # we have already 1 notification
      expect(SS::Notification.all.count).to eq 1

      #
      # Create
      #
      visit gws_circular_main_path(site: site)
      click_on item.name
      within "#post-#{item.id}" do
        click_on I18n.t("gws/board.links.comment")
      end

      within "form#item-form" do
        fill_in "item[text]", with: texts.join("\n")
        expect(find('#item_browsing_authority_all')).to be_checked
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      item.reload
      expect(item.comments.count).to eq 1
      comment = item.comments.first
      expect(comment.text).to eq texts.join("\r\n")
      expect(comment.browsing_authority).to eq 'all'

      within "#post-#{comment.id}" do
        expect(page).to have_css(".body", text: texts.first)
      end

      # no notifications are sent and we have still 1 notification, though
      expect(SS::Notification.all.count).to eq 1

      #
      # Update
      #
      visit gws_circular_main_path(site: site)
      click_on item.name
      within "#post-#{comment.id}" do
        click_on I18n.t("ss.links.edit")
      end

      within "form#item-form" do
        fill_in "item[text]", with: texts2.join("\n")
        choose 'item_browsing_authority_author_or_commenter'
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      comment.reload
      expect(comment.text).to eq texts2.join("\r\n")
      expect(comment.browsing_authority).to eq 'author_or_commenter'

      # no notifications are sent and we have still 1 notification, though
      expect(SS::Notification.all.count).to eq 1

      #
      # Delete
      #
      visit gws_circular_main_path(site: site)
      click_on item.name
      within "#post-#{comment.id}" do
        click_on I18n.t("ss.links.delete")
      end

      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))

      item.reload
      expect(item.comments.count).to eq 0
      expect { item.comments.find(comment.id) }.to raise_error Mongoid::Errors::DocumentNotFound

      # no notifications are sent and we have still 1 notification, though
      expect(SS::Notification.all.count).to eq 1
    end
  end
end
