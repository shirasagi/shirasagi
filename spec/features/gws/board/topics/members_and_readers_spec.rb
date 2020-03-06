require 'spec_helper'

describe "gws_board_topics", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}" }

  let!(:role_admin) { create :gws_role, :gws_role_board_admin }
  let!(:user_admin) { create :gws_user, group_ids: [ group1.id ], gws_role_ids: [ role_admin.id ] }

  let!(:role_user) { create :gws_role, :gws_role_board_user }
  let!(:user1_1) { create :gws_user, group_ids: [ group1.id ], gws_role_ids: [ role_user.id ] }
  let!(:user1_2) { create :gws_user, group_ids: [ group1.id ], gws_role_ids: [ role_user.id ] }
  let!(:user2) { create :gws_user, group_ids: [ group1.id ], gws_role_ids: [ role_user.id ] }

  let!(:cate) { create :gws_board_category, readable_group_ids: [ group1.id ] }
  let!(:item) do
    create(
      :gws_board_topic, category_ids: [ cate.id ], notify_state: "enabled", member_ids: [ user1_1.id, user1_2.id ],
      readable_member_ids: [ user2.id ], group_ids: user_admin.group_ids, user_ids: [ user_admin.id ]
    )
  end
  let!(:comment) do
    create(:gws_board_post, topic: item, parent: item, group_ids: user1_2.group_ids, user_ids: [ user1_2.id ])
  end

  before do
    site.canonical_scheme = %w(http https).sample
    site.canonical_domain = "#{unique_id}.example.jp"
    site.save!

    ActionMailer::Base.deliveries.clear
  end

  after { ActionMailer::Base.deliveries.clear }

  context "with admin user" do
    let(:text1) { unique_id }
    let(:text2) { unique_id }

    before { login_user user_admin }

    it do
      visit gws_board_main_path(site: site)

      within ".mod-navi.current-navi" do
        expect(page).to have_link(I18n.t('ss.navi.readable'))
        expect(page).to have_link(I18n.t('ss.navi.editable'))
        expect(page).to have_link(I18n.t('ss.navi.trash'))
        expect(page).to have_link(I18n.t('gws.category'))
      end

      #
      # Admin can post new comment
      #
      within ".mod-navi.current-navi" do
        click_on I18n.t('ss.navi.readable')
      end
      click_on item.name
      within "#menu" do
        expect(page).to have_link(I18n.t('ss.links.edit'))
        expect(page).to have_link(I18n.t('ss.links.print'))
        expect(page).to have_link(I18n.t('ss.links.back_to_index'))
      end
      within "#post-#{item.id}" do
        expect(page).to have_css(".name", text: item.name)
        expect(page).to have_css(".gws-category-label", text: cate.name)
        expect(page).to have_css(".body", text: item.text)

        click_on I18n.t("gws/board.links.comment")
      end

      within "form#item-form" do
        fill_in "item[text]", with: text1
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      item.reload
      expect(item.descendants.count).to eq 2

      expect(SS::Notification.all.count).to eq 1
      notice = SS::Notification.all.reorder(created: -1).first
      expect(notice.group_id).to eq site.id
      expect(notice.member_ids.length).to eq 2
      expect(notice.member_ids).to include(user1_1.id, user1_2.id)
      expect(notice.user_id).to eq user_admin.id
      expect(notice.subject).to eq I18n.t("gws_notification.gws/board/post.subject", name: item.name)

      #
      # Admin can edit member's comment
      #
      within "#post-#{comment.id}" do
        expect(page).to have_css("header h2", text: comment.name)
        expect(page).to have_css(".body", text: comment.text)

        click_on I18n.t("ss.links.edit")
      end
      within "form#item-form" do
        fill_in "item[text]", with: text2
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      comment.reload
      expect(comment.text).to eq text2

      expect(SS::Notification.all.count).to eq 2
      notice = SS::Notification.all.reorder(created: -1).first
      expect(notice.group_id).to eq site.id
      expect(notice.member_ids).to eq [ user1_1.id, user1_2.id ]
      expect(notice.user_id).to eq user_admin.id
      expect(notice.subject).to eq I18n.t("gws_notification.gws/board/post.subject", name: item.name)

      #
      # Admin can post new comment also on editable
      #
      within ".mod-navi.current-navi" do
        click_on I18n.t('ss.navi.editable')
      end
      click_on item.name
      within "#menu" do
        expect(page).to have_link(I18n.t('ss.links.edit'))
        expect(page).to have_link(I18n.t('ss.links.print'))
        expect(page).to have_link(I18n.t('ss.links.back_to_index'))
      end
      within "#post-#{item.id}" do
        expect(page).to have_css(".name", text: item.name)
        expect(page).to have_css(".gws-category-label", text: cate.name)
        expect(page).to have_css(".body", text: item.text)

        click_on I18n.t("gws/board.links.comment")
      end

      within "form#item-form" do
        fill_in "item[text]", with: unique_id
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      item.reload
      expect(item.descendants.count).to eq 3

      expect(SS::Notification.all.count).to eq 3
      notice = SS::Notification.all.reorder(created: -1).first
      expect(notice.group_id).to eq site.id
      expect(notice.member_ids.length).to eq 2
      expect(notice.member_ids).to include(user1_1.id, user1_2.id)
      expect(notice.user_id).to eq user_admin.id
      expect(notice.subject).to eq I18n.t("gws_notification.gws/board/post.subject", name: item.name)

      #
      # Admin can delete member's comment
      #
      within "#post-#{comment.id}" do
        click_on I18n.t("ss.links.delete")
      end
      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.deleted"))

      expect { comment.reload }.to raise_error Mongoid::Errors::DocumentNotFound

      item.reload
      expect(item.descendants.count).to eq 2

      expect(SS::Notification.all.count).to eq 4
      notice = SS::Notification.all.reorder(created: -1).first
      expect(notice.group_id).to eq site.id
      expect(notice.member_ids.length).to eq 2
      expect(notice.member_ids).to include(user1_1.id, user1_2.id)
      expect(notice.user_id).to eq user_admin.id
      expect(notice.subject).to eq I18n.t("gws_notification.gws/board/post/destroy.subject", name: item.name)
    end
  end

  context "with member" do
    let(:text1) { unique_id }
    let(:text2) { unique_id }
    before { login_user user1_1 }

    it do
      visit gws_board_main_path(site: site)
      expect(page).to have_no_css(".mod-navi.current-navi")
      within ".breadcrumb" do
        expect(page).to have_no_link(I18n.t('ss.navi.readable'))
      end
      expect(page).to have_no_css("#menu a")

      #
      # Member can post new comment
      #
      click_on item.name
      within "#menu" do
        expect(page).to have_no_link(I18n.t('ss.links.edit'))
        expect(page).to have_link(I18n.t('ss.links.print'))
        expect(page).to have_link(I18n.t('ss.links.back_to_index'))
      end
      within "#post-#{item.id}" do
        expect(page).to have_css(".name", text: item.name)
        expect(page).to have_css(".gws-category-label", text: cate.name)
        expect(page).to have_css(".body", text: item.text)

        click_on I18n.t("gws/board.links.comment")
      end

      within "form#item-form" do
        fill_in "item[text]", with: text1
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      item.reload
      expect(item.descendants.count).to eq 2

      post = item.descendants.first
      expect(post.text).to eq text1
      expect(post.group_ids).to include(*item.group_ids)
      expect(post.user_ids).to include(*(item.user_ids + [ user1_1.id ]))

      expect(SS::Notification.all.count).to eq 1
      notice = SS::Notification.all.reorder(created: -1).first
      expect(notice.group_id).to eq site.id
      expect(notice.member_ids).to eq [ user1_2.id ]
      expect(notice.user_id).to eq user1_1.id
      expect(notice.subject).to eq I18n.t("gws_notification.gws/board/post.subject", name: item.name)

      #
      # Member can edit owned comment
      #
      visit gws_board_main_path(site: site)
      click_on item.name
      within "#post-#{post.id}" do
        click_on I18n.t("ss.links.edit")
      end

      within "form#item-form" do
        fill_in "item[text]", with: text2
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      post.reload
      expect(post.text).to eq text2

      expect(SS::Notification.all.count).to eq 2
      notice = SS::Notification.all.reorder(created: -1).first
      expect(notice.group_id).to eq site.id
      expect(notice.member_ids).to eq [ user1_2.id ]
      expect(notice.user_id).to eq user1_1.id
      expect(notice.subject).to eq I18n.t("gws_notification.gws/board/post.subject", name: item.name)

      #
      # Member can delete owned comment
      #
      visit gws_board_main_path(site: site)
      click_on item.name
      within "#post-#{post.id}" do
        click_on I18n.t("ss.links.delete")
      end
      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.deleted"))

      expect { post.reload }.to raise_error Mongoid::Errors::DocumentNotFound

      expect(SS::Notification.all.count).to eq 3
      notice = SS::Notification.all.reorder(created: -1).first
      expect(notice.group_id).to eq site.id
      expect(notice.member_ids).to eq [ user1_2.id ]
      expect(notice.user_id).to eq user1_1.id
      expect(notice.subject).to eq I18n.t("gws_notification.gws/board/post/destroy.subject", name: item.name)

      #
      # Change category
      #
      visit gws_board_main_path(site: site)
      within ".gws-category-navi" do
        click_on I18n.t('gws.category')
        within ".dropdown-menu" do
          click_on cate.name
        end
      end

      click_on item.name
      within "#menu" do
        expect(page).to have_no_link(I18n.t('ss.links.edit'))
        expect(page).to have_link(I18n.t('ss.links.print'))
        expect(page).to have_link(I18n.t('ss.links.back_to_index'))
      end
      within "#post-#{item.id}" do
        expect(page).to have_css(".name", text: item.name)
        expect(page).to have_css(".gws-category-label", text: cate.name)
        expect(page).to have_css(".body", text: item.text)

        click_on I18n.t("gws/board.links.comment")
      end
    end
  end

  context "with reader" do
    before { login_user user2 }

    it do
      visit gws_board_main_path(site: site)
      expect(page).to have_no_css(".mod-navi.current-navi")
      within ".breadcrumb" do
        expect(page).to have_no_link(I18n.t('ss.navi.readable'))
      end
      expect(page).to have_no_css("#menu a")

      click_on item.name
      within "#menu" do
        expect(page).to have_no_link(I18n.t('ss.links.edit'))
        expect(page).to have_link(I18n.t('ss.links.print'))
        expect(page).to have_link(I18n.t('ss.links.back_to_index'))
      end
      within "#post-#{item.id}" do
        expect(page).to have_css(".name", text: item.name)
        expect(page).to have_css(".gws-category-label", text: cate.name)
        expect(page).to have_css(".body", text: item.text)
        expect(page).to have_no_link(I18n.t("gws/board.links.comment"))
      end
      within "#post-#{comment.id}" do
        expect(page).to have_css("header h2", text: comment.name)
        expect(page).to have_no_css(".gws-category-label")
        expect(page).to have_css(".body", text: comment.text)
        expect(page).to have_no_link(I18n.t("ss.links.edit"))
        expect(page).to have_no_link(I18n.t("ss.links.delete"))
      end

      # change category
      visit gws_board_main_path(site: site)
      within ".gws-category-navi" do
        click_on I18n.t('gws.category')
        within ".dropdown-menu" do
          click_on cate.name
        end
      end

      click_on item.name
      within "#menu" do
        expect(page).to have_no_link(I18n.t('ss.links.edit'))
        expect(page).to have_link(I18n.t('ss.links.print'))
        expect(page).to have_link(I18n.t('ss.links.back_to_index'))
      end
      within "#post-#{item.id}" do
        expect(page).to have_css(".name", text: item.name)
        expect(page).to have_css(".gws-category-label", text: cate.name)
        expect(page).to have_css(".body", text: item.text)
        expect(page).to have_no_link(I18n.t("gws/board.links.comment"))
      end
      within "#post-#{comment.id}" do
        expect(page).to have_css("header h2", text: comment.name)
        expect(page).to have_no_css(".gws-category-label")
        expect(page).to have_css(".body", text: comment.text)
        expect(page).to have_no_link(I18n.t("ss.links.edit"))
        expect(page).to have_no_link(I18n.t("ss.links.delete"))
      end
    end
  end
end
