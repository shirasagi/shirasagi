require 'spec_helper'

describe "gws_qna_topics", type: :feature, dbscope: :example do
  context "basic crud", js: true do
    let!(:site) { gws_site }
    let!(:user1) do
      create(
        :gws_user, notice_qna_email_user_setting: "notify", send_notice_mail_addresses: "#{unique_id}@example.jp",
        group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids
      )
    end
    let!(:category) { create :gws_qna_category, subscribed_member_ids: [ user1.id ] }
    let(:item) { create :gws_qna_topic, category_ids: [ category.id ] }
    let(:index_path) { gws_qna_topics_path site, '-', '-' }
    let(:new_path) { new_gws_qna_topic_path site, '-', '-' }
    let(:show_path) { gws_qna_topic_path site, '-', '-', item }
    let(:edit_path) { edit_gws_qna_topic_path site, '-', '-', item }
    let(:delete_path) { delete_gws_qna_topic_path site, '-', '-', item }

    before do
      site.canonical_scheme = %w(http https).sample
      site.canonical_domain = "#{unique_id}.example.jp"
      site.save!

      login_gws_user

      ActionMailer::Base.deliveries.clear
    end

    after { ActionMailer::Base.deliveries.clear }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      now = Time.zone.at(Time.zone.now.to_i)
      Timecop.freeze(now) do
        visit new_path
        click_on "カテゴリーを選択する"
        wait_for_cbox do
          click_on category.name
        end

        within "form#item-form" do
          fill_in "item[name]", with: "name"
          fill_in "item[text]", with: "text"
          click_button I18n.t('ss.buttons.save')
        end
        expect(current_path).not_to eq new_path

        item = Gws::Qna::Topic.site(site).first
        expect(item.name).to eq "name"
        expect(item.text).to eq "text"
        expect(item.state).to eq "public"
        expect(item.mode).to eq "thread"
        expect(item.descendants_updated).to eq now
        expect(item.descendants_files_count).to eq 0
        expect(item.category_ids).to eq [category.id]

        expect(SS::Notification.count).to eq 1
        notice = SS::Notification.first
        expect(notice.group_id).to eq site.id
        expect(notice.member_ids).to eq [ user1.id ]
        expect(notice.user_id).to eq gws_user.id
        expect(notice.subject).to eq I18n.t("gws_notification.gws/qna/topic.subject", name: item.name)
        expect(notice.text).to be_blank
        expect(notice.html).to be_blank
        expect(notice.format).to eq "text"
        expect(notice.seen).to be_blank
        expect(notice.state).to eq "public"
        expect(notice.send_date).to be_present
        expect(notice.url).to eq "/.g#{site.id}/qna/-/-/topics/#{item.id}"
        expect(notice.reply_module).to be_blank
        expect(notice.reply_model).to be_blank
        expect(notice.reply_item_id).to be_blank

        expect(ActionMailer::Base.deliveries.length).to eq 1
        mail = ActionMailer::Base.deliveries.first
        expect(mail.from.first).to eq site.sender_address
        expect(mail.bcc.first).to eq user1.send_notice_mail_addresses.first
        expect(mail.subject).to eq notice.subject
        url = "#{site.canonical_scheme}://#{site.canonical_domain}/.g#{site.id}/memo/notices/#{notice.id}"
        expect(mail.decoded.to_s).to include(mail.subject, url)
      end
    end

    it "#show" do
      visit show_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_button I18n.t('ss.buttons.save')
      end
      expect(current_path).not_to eq sns_login_path

      item.reload
      expect(item.name).to eq "modify"
      expect(item.category_ids).to include(category.id)

      expect(SS::Notification.count).to eq 1
      notice = SS::Notification.first
      expect(notice.group_id).to eq site.id
      expect(notice.member_ids).to eq [ user1.id ]
      expect(notice.user_id).to eq gws_user.id
      expect(notice.subject).to eq I18n.t("gws_notification.gws/qna/topic.subject", name: item.name)
      expect(notice.text).to be_blank
      expect(notice.html).to be_blank
      expect(notice.format).to eq "text"
      expect(notice.seen).to be_blank
      expect(notice.state).to eq "public"
      expect(notice.send_date).to be_present
      expect(notice.url).to eq "/.g#{site.id}/qna/-/-/topics/#{item.id}"
      expect(notice.reply_module).to be_blank
      expect(notice.reply_model).to be_blank
      expect(notice.reply_item_id).to be_blank
      expect(ActionMailer::Base.deliveries.length).to eq 1

      mail = ActionMailer::Base.deliveries.first
      expect(mail.from.first).to eq site.sender_address
      expect(mail.bcc.first).to eq user1.send_notice_mail_addresses.first
      expect(mail.subject).to eq notice.subject
      url = "#{site.canonical_scheme}://#{site.canonical_domain}/.g#{site.id}/memo/notices/#{notice.id}"
      expect(mail.decoded.to_s).to include(mail.subject, url)
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
      expect(current_path).to eq index_path

      expect { item.reload }.to raise_error Mongoid::Errors::DocumentNotFound

      expect(SS::Notification.count).to eq 1
      notice = SS::Notification.first
      expect(notice.group_id).to eq site.id
      expect(notice.member_ids).to eq [ user1.id ]
      expect(notice.user_id).to eq gws_user.id
      expect(notice.subject).to eq I18n.t("gws_notification.gws/qna/topic/destroy.subject", name: item.name)
      expect(notice.text).to be_blank
      expect(notice.html).to be_blank
      expect(notice.format).to eq "text"
      expect(notice.seen).to be_blank
      expect(notice.state).to eq "public"
      expect(notice.send_date).to be_present
      expect(notice.url).to be_blank
      expect(notice.reply_module).to be_blank
      expect(notice.reply_model).to be_blank
      expect(notice.reply_item_id).to be_blank

      mail = ActionMailer::Base.deliveries.first
      expect(mail.from.first).to eq site.sender_address
      expect(mail.bcc.first).to eq user1.send_notice_mail_addresses.first
      expect(mail.subject).to eq notice.subject
      url = "#{site.canonical_scheme}://#{site.canonical_domain}/.g#{site.id}/memo/notices/#{notice.id}"
      expect(mail.decoded.to_s).to include(mail.subject, url)
    end
  end
end
