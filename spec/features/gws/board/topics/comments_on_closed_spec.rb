require 'spec_helper'

describe "gws_board_topics", type: :feature, dbscope: :example do
  context "comments" do
    let(:site) { gws_site }
    let!(:user1) do
      create(
        :gws_user, notice_board_email_user_setting: "notify", send_notice_mail_addresses: "#{unique_id}@example.jp",
        group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids
      )
    end
    let!(:cate) { create :gws_board_category, subscribed_member_ids: [ user1.id ] }
    let(:show_path) { gws_board_topic_path site, 'editable', '-', topic }
    let(:name) { unique_id }
    let(:text) { unique_id }
    let(:text2) { unique_id }

    before do
      site.canonical_scheme = %w(http https).sample
      site.canonical_domain = "#{unique_id}.example.jp"
      site.save!

      login_gws_user

      ActionMailer::Base.deliveries.clear
    end

    after { ActionMailer::Base.deliveries.clear }

    context "crud of comment on closed thread topic" do
      let(:topic) do
        create :gws_board_topic, mode: 'thread', category_ids: [ cate.id ], notify_state: "enabled", state: "closed"
      end

      it do
        #
        # Create
        #
        visit show_path
        expect(page).to have_css("article.topic .name", text: topic.name)
        expect(page).to have_css("article.topic .body", text: topic.text)

        within "article.topic div.menu" do
          click_on I18n.t("gws/board.links.comment")
        end

        within "form#item-form" do
          fill_in "item[name]", with: name
          fill_in "item[text]", with: text
          click_on I18n.t('ss.buttons.save')
        end

        expect(page).to have_css("aside.comment h2", text: name)
        expect(page).to have_css("aside.comment .body", text: text)

        expect(Gws::Board::Post.where(topic_id: topic.id).count).to eq 1
        comment = Gws::Board::Post.where(topic_id: topic.id).first
        expect(comment.name).to eq name
        expect(comment.text).to eq text

        expect(SS::Notification.all.count).to eq 0
        expect(ActionMailer::Base.deliveries.length).to eq 0

        #
        # Update
        #
        visit show_path
        within "#post-#{comment.id}" do
          click_on I18n.t("ss.links.edit")
        end
        within "form#item-form" do
          fill_in "item[text]", with: text2
          click_on I18n.t('ss.buttons.save')
        end

        comment.reload
        expect(comment.text).to eq text2

        expect(SS::Notification.all.count).to eq 0
        expect(ActionMailer::Base.deliveries.length).to eq 0

        #
        # Delete
        #
        visit show_path
        within "#post-#{comment.id}" do
          click_on I18n.t("ss.links.delete")
        end
        within "form" do
          click_on I18n.t('ss.buttons.delete')
        end

        expect { comment.reload }.to raise_error Mongoid::Errors::DocumentNotFound

        expect(SS::Notification.all.count).to eq 0
        expect(ActionMailer::Base.deliveries.length).to eq 0
      end
    end

    context "crud with tree topic" do
      let(:topic) do
        create :gws_board_topic, mode: 'tree', category_ids: [ cate.id ], notify_state: "enabled", state: "closed"
      end
      let(:name2) { unique_id }
      let(:text2) { unique_id }
      let(:text3) { unique_id }

      it do
        #
        # Create
        #
        visit show_path
        expect(page).to have_css("article.topic .name", text: topic.name)
        expect(page).to have_css("article.topic .body", text: topic.text)

        within "article.topic div.menu" do
          click_on I18n.t("gws/board.links.comment")
        end

        within "form#item-form" do
          fill_in "item[name]", with: name
          fill_in "item[text]", with: text
          click_on I18n.t('ss.buttons.save')
        end

        expect(page).to have_css("aside.comment h2", text: name)
        expect(page).to have_css("aside.comment .body", text: text)

        expect(Gws::Board::Post.where(topic_id: topic.id).count).to eq 1
        comment = Gws::Board::Post.where(topic_id: topic.id).first
        expect(comment.name).to eq name
        expect(comment.text).to eq text

        expect(SS::Notification.all.count).to eq 0
        expect(ActionMailer::Base.deliveries.length).to eq 0

        #
        # Create comment to comment
        #
        within "aside.comment div.menu" do
          click_on I18n.t("gws/board.links.comment")
        end

        within "form#item-form" do
          fill_in "item[name]", with: name2
          fill_in "item[text]", with: text2
          click_button I18n.t('ss.buttons.save')
        end

        expect(page).to have_css("aside.comment h2", text: name)
        expect(page).to have_css("aside.comment .body", text: text)
        expect(page).to have_css("aside.comment h2", text: name2)
        expect(page).to have_css("aside.comment .body", text: text2)

        expect(Gws::Board::Post.where(topic_id: topic.id).count).to eq 2
        comment = Gws::Board::Post.where(topic_id: topic.id).order_by(created: -1).first
        expect(comment.name).to eq name2
        expect(comment.text).to eq text2

        expect(SS::Notification.all.count).to eq 0
        expect(ActionMailer::Base.deliveries.length).to eq 0

        #
        # Update
        #
        visit show_path
        within "#post-#{comment.id}" do
          click_on I18n.t("ss.links.edit")
        end
        within "form#item-form" do
          fill_in "item[text]", with: text3
          click_on I18n.t('ss.buttons.save')
        end

        comment.reload
        expect(comment.text).to eq text3

        expect(SS::Notification.all.count).to eq 0
        expect(ActionMailer::Base.deliveries.length).to eq 0

        #
        # Delete
        #
        visit show_path
        within "#post-#{comment.id}" do
          click_on I18n.t("ss.links.delete")
        end
        within "form" do
          click_on I18n.t('ss.buttons.delete')
        end

        expect { comment.reload }.to raise_error Mongoid::Errors::DocumentNotFound

        expect(SS::Notification.all.count).to eq 0
        expect(ActionMailer::Base.deliveries.length).to eq 0
      end
    end
  end
end
