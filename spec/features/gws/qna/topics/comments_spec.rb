require 'spec_helper'

describe "gws_qna_topics", type: :feature, dbscope: :example do
  context "comments" do
    let(:site) { gws_site }
    let!(:user1) do
      create(
        :gws_user, notice_qna_email_user_setting: "notify", send_notice_mail_addresses: "#{unique_id}@example.jp",
        group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids
      )
    end
    let!(:category) { create :gws_qna_category, subscribed_member_ids: [ user1.id ] }
    let(:show_path) { gws_qna_topic_path site, '-', '-', topic }
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

    context "crud with thread topic" do
      let(:topic) { create :gws_qna_topic, mode: 'thread', category_ids: [ category.id ] }

      it do
        #
        # Create
        #
        visit show_path
        expect(page).to have_css("article.topic .name", text: topic.name)
        expect(page).to have_css("article.topic .body", text: topic.text)

        within "article.topic div.menu" do
          click_on I18n.t("gws/qna.links.comment")
        end

        within "form#item-form" do
          fill_in "item[name]", with: name
          fill_in "item[text]", with: text
          click_button I18n.t('ss.buttons.save')
        end

        expect(page).to have_css("aside.comment h2", text: name)
        expect(page).to have_css("aside.comment .body", text: text)

        expect(Gws::Qna::Post.where(topic_id: topic.id).count).to eq 1
        comment = Gws::Qna::Post.where(topic_id: topic.id).first
        expect(comment.name).to eq name
        expect(comment.text).to eq text

        expect(SS::Notification.count).to eq 1
        notice = SS::Notification.reorder(created: -1).first
        expect(notice.group_id).to eq site.id
        expect(notice.member_ids).to eq [ user1.id ]
        expect(notice.user_id).to eq gws_user.id
        expect(notice.subject).to eq I18n.t("gws_notification.gws/qna/post.subject", name: topic.name)
        expect(notice.text).to be_blank
        expect(notice.html).to be_blank
        expect(notice.format).to eq "text"
        expect(notice.seen).to be_blank
        expect(notice.state).to eq "public"
        expect(notice.send_date).to be_present
        expect(notice.url).to eq "/.g#{site.id}/qna/-/-/topics/#{topic.id}#post-#{comment.id}"
        expect(notice.reply_module).to be_blank
        expect(notice.reply_model).to be_blank
        expect(notice.reply_item_id).to be_blank

        expect(ActionMailer::Base.deliveries.length).to eq 1
        mail = ActionMailer::Base.deliveries.last
        expect(mail.from.first).to eq site.sender_address
        expect(mail.bcc.first).to eq user1.send_notice_mail_addresses.first
        expect(mail.subject).to eq notice.subject
        url = "#{site.canonical_scheme}://#{site.canonical_domain}/.g#{site.id}/memo/notices/#{notice.id}"
        expect(mail.decoded.to_s).to include(mail.subject, url)

        #
        # Update
        #
        visit show_path
        within "#post-#{comment.id}" do
          click_on I18n.t("ss.links.edit")
        end
        within "form#item-form" do
          fill_in "item[text]", with: text2
          click_button I18n.t('ss.buttons.save')
        end

        comment.reload
        expect(comment.name).to eq name
        expect(comment.text).to eq text2

        expect(SS::Notification.count).to eq 2
        notice = SS::Notification.reorder(created: -1).first
        expect(notice.group_id).to eq site.id
        expect(notice.member_ids).to eq [ user1.id ]
        expect(notice.user_id).to eq gws_user.id
        expect(notice.subject).to eq I18n.t("gws_notification.gws/qna/post.subject", name: topic.name)
        expect(notice.text).to be_blank
        expect(notice.html).to be_blank
        expect(notice.format).to eq "text"
        expect(notice.seen).to be_blank
        expect(notice.state).to eq "public"
        expect(notice.send_date).to be_present
        expect(notice.url).to eq "/.g#{site.id}/qna/-/-/topics/#{topic.id}#post-#{comment.id}"
        expect(notice.reply_module).to be_blank
        expect(notice.reply_model).to be_blank
        expect(notice.reply_item_id).to be_blank

        expect(ActionMailer::Base.deliveries.length).to eq 2
        mail = ActionMailer::Base.deliveries.last
        expect(mail.from.first).to eq site.sender_address
        expect(mail.bcc.first).to eq user1.send_notice_mail_addresses.first
        expect(mail.subject).to eq notice.subject
        url = "#{site.canonical_scheme}://#{site.canonical_domain}/.g#{site.id}/memo/notices/#{notice.id}"
        expect(mail.decoded.to_s).to include(mail.subject, url)

        #
        # Delete
        #
        visit show_path
        within "#post-#{comment.id}" do
          click_on I18n.t("ss.links.delete")
        end
        within "form" do
          click_button I18n.t('ss.buttons.delete')
        end

        expect { comment.reload }.to raise_error Mongoid::Errors::DocumentNotFound

        expect(SS::Notification.count).to eq 3
        notice = SS::Notification.reorder(created: -1).first
        expect(notice.group_id).to eq site.id
        expect(notice.member_ids).to eq [ user1.id ]
        expect(notice.user_id).to eq gws_user.id
        expect(notice.subject).to eq I18n.t("gws_notification.gws/qna/post/destroy.subject", name: topic.name)
        expect(notice.text).to be_blank
        expect(notice.html).to be_blank
        expect(notice.format).to eq "text"
        expect(notice.seen).to be_blank
        expect(notice.state).to eq "public"
        expect(notice.send_date).to be_present
        expect(notice.url).to eq "/.g#{site.id}/qna/-/-/topics/#{topic.id}#post-#{comment.id}"
        expect(notice.reply_module).to be_blank
        expect(notice.reply_model).to be_blank
        expect(notice.reply_item_id).to be_blank

        expect(ActionMailer::Base.deliveries.length).to eq 3
        mail = ActionMailer::Base.deliveries.last
        expect(mail.from.first).to eq site.sender_address
        expect(mail.bcc.first).to eq user1.send_notice_mail_addresses.first
        expect(mail.subject).to eq notice.subject
        url = "#{site.canonical_scheme}://#{site.canonical_domain}/.g#{site.id}/memo/notices/#{notice.id}"
        expect(mail.decoded.to_s).to include(mail.subject, url)
      end
    end

    context "crud with tree topic" do
      let(:topic) { create :gws_qna_topic, mode: 'tree', category_ids: [ category.id ] }
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
          click_on I18n.t("gws/qna.links.comment")
        end

        within "form#item-form" do
          fill_in "item[name]", with: name
          fill_in "item[text]", with: text
          click_button I18n.t('ss.buttons.save')
        end

        expect(page).to have_css("aside.comment h2", text: name)
        expect(page).to have_css("aside.comment .body", text: text)

        expect(Gws::Qna::Post.where(topic_id: topic.id).count).to eq 1
        comment = Gws::Qna::Post.where(topic_id: topic.id).first
        expect(comment.name).to eq name
        expect(comment.text).to eq text

        expect(SS::Notification.count).to eq 1
        notice = SS::Notification.reorder(created: -1).first
        expect(notice.group_id).to eq site.id
        expect(notice.member_ids).to eq [ user1.id ]
        expect(notice.user_id).to eq gws_user.id
        expect(notice.subject).to eq I18n.t("gws_notification.gws/qna/post.subject", name: topic.name)
        expect(notice.text).to be_blank
        expect(notice.html).to be_blank
        expect(notice.format).to eq "text"
        expect(notice.seen).to be_blank
        expect(notice.state).to eq "public"
        expect(notice.send_date).to be_present
        expect(notice.url).to eq "/.g#{site.id}/qna/-/-/topics/#{topic.id}#post-#{comment.id}"
        expect(notice.reply_module).to be_blank
        expect(notice.reply_model).to be_blank
        expect(notice.reply_item_id).to be_blank

        expect(ActionMailer::Base.deliveries.length).to eq 1
        mail = ActionMailer::Base.deliveries.last
        expect(mail.from.first).to eq site.sender_address
        expect(mail.bcc.first).to eq user1.send_notice_mail_addresses.first
        expect(mail.subject).to eq notice.subject
        url = "#{site.canonical_scheme}://#{site.canonical_domain}/.g#{site.id}/memo/notices/#{notice.id}"
        expect(mail.decoded.to_s).to include(mail.subject, url)

        #
        # Create (another way)
        #
        within "aside.comment div.menu" do
          click_on I18n.t("gws/qna.links.comment")
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

        expect(Gws::Qna::Post.where(topic_id: topic.id).count).to eq 2
        comment2 = Gws::Qna::Post.where(topic_id: topic.id).order_by(created: -1).first
        expect(comment2.name).to eq name2
        expect(comment2.text).to eq text2

        expect(SS::Notification.count).to eq 2
        notice = SS::Notification.reorder(created: -1).first
        expect(notice.group_id).to eq site.id
        expect(notice.member_ids).to eq [ user1.id ]
        expect(notice.user_id).to eq gws_user.id
        expect(notice.subject).to eq I18n.t("gws_notification.gws/qna/post.subject", name: topic.name)
        expect(notice.text).to be_blank
        expect(notice.html).to be_blank
        expect(notice.format).to eq "text"
        expect(notice.seen).to be_blank
        expect(notice.state).to eq "public"
        expect(notice.send_date).to be_present
        expect(notice.url).to eq "/.g#{site.id}/qna/-/-/topics/#{topic.id}#post-#{comment2.id}"
        expect(notice.reply_module).to be_blank
        expect(notice.reply_model).to be_blank
        expect(notice.reply_item_id).to be_blank

        expect(ActionMailer::Base.deliveries.length).to eq 2
        mail = ActionMailer::Base.deliveries.last
        expect(mail.from.first).to eq site.sender_address
        expect(mail.bcc.first).to eq user1.send_notice_mail_addresses.first
        expect(mail.subject).to eq notice.subject
        url = "#{site.canonical_scheme}://#{site.canonical_domain}/.g#{site.id}/memo/notices/#{notice.id}"
        expect(mail.decoded.to_s).to include(mail.subject, url)

        #
        # Update
        #
        visit show_path
        within "#post-#{comment2.id}" do
          click_on I18n.t("ss.links.edit")
        end
        within "form#item-form" do
          fill_in "item[text]", with: text3
          click_button I18n.t('ss.buttons.save')
        end

        comment2.reload
        expect(comment2.name).to eq name2
        expect(comment2.text).to eq text3

        expect(SS::Notification.count).to eq 3
        notice = SS::Notification.reorder(created: -1).first
        expect(notice.group_id).to eq site.id
        expect(notice.member_ids).to eq [ user1.id ]
        expect(notice.user_id).to eq gws_user.id
        expect(notice.subject).to eq I18n.t("gws_notification.gws/qna/post.subject", name: topic.name)
        expect(notice.text).to be_blank
        expect(notice.html).to be_blank
        expect(notice.format).to eq "text"
        expect(notice.seen).to be_blank
        expect(notice.state).to eq "public"
        expect(notice.send_date).to be_present
        expect(notice.url).to eq "/.g#{site.id}/qna/-/-/topics/#{topic.id}#post-#{comment2.id}"
        expect(notice.reply_module).to be_blank
        expect(notice.reply_model).to be_blank
        expect(notice.reply_item_id).to be_blank

        expect(ActionMailer::Base.deliveries.length).to eq 3
        mail = ActionMailer::Base.deliveries.last
        expect(mail.from.first).to eq site.sender_address
        expect(mail.bcc.first).to eq user1.send_notice_mail_addresses.first
        expect(mail.subject).to eq notice.subject
        url = "#{site.canonical_scheme}://#{site.canonical_domain}/.g#{site.id}/memo/notices/#{notice.id}"
        expect(mail.decoded.to_s).to include(mail.subject, url)

        #
        # Delete
        #
        visit show_path
        within "#post-#{comment2.id}" do
          click_on I18n.t("ss.links.delete")
        end
        within "form" do
          click_button I18n.t('ss.buttons.delete')
        end

        expect { comment2.reload }.to raise_error Mongoid::Errors::DocumentNotFound

        expect(SS::Notification.count).to eq 4
        notice = SS::Notification.reorder(created: -1).first
        expect(notice.group_id).to eq site.id
        expect(notice.member_ids).to eq [ user1.id ]
        expect(notice.user_id).to eq gws_user.id
        expect(notice.subject).to eq I18n.t("gws_notification.gws/qna/post/destroy.subject", name: topic.name)
        expect(notice.text).to be_blank
        expect(notice.html).to be_blank
        expect(notice.format).to eq "text"
        expect(notice.seen).to be_blank
        expect(notice.state).to eq "public"
        expect(notice.send_date).to be_present
        expect(notice.url).to eq "/.g#{site.id}/qna/-/-/topics/#{topic.id}#post-#{comment2.id}"
        expect(notice.reply_module).to be_blank
        expect(notice.reply_model).to be_blank
        expect(notice.reply_item_id).to be_blank

        expect(ActionMailer::Base.deliveries.length).to eq 4
        mail = ActionMailer::Base.deliveries.last
        expect(mail.from.first).to eq site.sender_address
        expect(mail.bcc.first).to eq user1.send_notice_mail_addresses.first
        expect(mail.subject).to eq notice.subject
        url = "#{site.canonical_scheme}://#{site.canonical_domain}/.g#{site.id}/memo/notices/#{notice.id}"
        expect(mail.decoded.to_s).to include(mail.subject, url)
      end
    end
  end
end
