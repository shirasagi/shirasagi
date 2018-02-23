require 'spec_helper'

describe Gws::NoticeNotificationJob, dbscope: :example do
  let(:site) { gws_site }
  let(:scheme) { %w(http https).sample }
  let(:domain) { "#{unique_id}.example.jp" }
  let(:sender) { gws_user }
  let(:recipient1) { create(:gws_user) }
  let(:recipient2) { create(:gws_user) }

  before do
    ActionMailer::Base.deliveries = []
  end

  after do
    ActionMailer::Base.deliveries = []
  end

  before do
    site.canonical_scheme = scheme
    site.canonical_domain = domain
    site.sender_name = unique_id
    site.sender_email = "#{site.sender_name}@example.jp"
    site.save!
  end

  context 'text notice' do
    let!(:notice) do
      create(
        :gws_notice, cur_site: site, cur_user: sender, message_notification: 'enabled', email_notification: 'enabled',
        readable_member_ids: [recipient1.id, recipient2.id], state: 'public'
      )
    end

    it do
      described_class.bind(site_id: site.id).perform_now

      expect(Gws::Job::Log.count).to eq 1
      Gws::Job::Log.first.tap do |log|
        expect(log.logs).to include(include('INFO -- : Started Job'))
        expect(log.logs).to include(include('INFO -- : Completed Job'))
      end

      expect(Gws::Memo::Notice.count).to eq 1
      Gws::Memo::Notice.first.tap do |message|
        expect(message.subject).to eq I18n.t('gws_notification.gws/notice.subject', name: notice.name)
        expect(message.text).to include(notice.name)
        expect(message.text).to include("#{scheme}://#{domain}/.g#{site.id}/gws/public_notices/#{notice.id}")
      end

      expect(ActionMailer::Base.deliveries.length).to eq 2
      ActionMailer::Base.deliveries.first.tap do |notify_mail|
        expect(notify_mail.from.first).to eq site.sender_email
        expect(notify_mail.to.first).to eq recipient1.email
        expect(notify_mail.subject).to eq I18n.t('gws_notification.gws/notice.subject', name: notice.name)
        expect(notify_mail.body.multipart?).to be_falsey
        expect(notify_mail.body.raw_source).to include(notice.name)
        expect(notify_mail.body.raw_source).to include("#{scheme}://#{domain}/.g#{site.id}/gws/public_notices/#{notice.id}")
      end
    end
  end

  context 'markdown notice' do
    let!(:notice) do
      create(
        :gws_notice, cur_site: site, cur_user: sender, message_notification: 'enabled', email_notification: 'enabled',
        readable_member_ids: [recipient1.id, recipient2.id], state: 'public',
        text: "# #{unique_id}\n#{unique_id}\n\n* #{unique_id}", text_type: 'markdown'
      )
    end

    it do
      described_class.bind(site_id: site.id).perform_now

      expect(Gws::Job::Log.count).to eq 1
      Gws::Job::Log.first.tap do |log|
        expect(log.logs).to include(include('INFO -- : Started Job'))
        expect(log.logs).to include(include('INFO -- : Completed Job'))
      end

      expect(Gws::Memo::Notice.count).to eq 1
      Gws::Memo::Notice.first.tap do |message|
        expect(message.subject).to eq I18n.t('gws_notification.gws/notice.subject', name: notice.name)
        expect(message.text).to include(notice.name)
        expect(message.text).to include("#{scheme}://#{domain}/.g#{site.id}/gws/public_notices/#{notice.id}")
      end

      expect(ActionMailer::Base.deliveries.length).to eq 2
      ActionMailer::Base.deliveries.first.tap do |notify_mail|
        expect(notify_mail.from.first).to eq site.sender_email
        expect(notify_mail.to.first).to eq recipient1.email
        expect(notify_mail.subject).to eq I18n.t('gws_notification.gws/notice.subject', name: notice.name)
        expect(notify_mail.body.multipart?).to be_falsey
        expect(notify_mail.body.raw_source).to include(notice.name)
        expect(notify_mail.body.raw_source).to include("#{scheme}://#{domain}/.g#{site.id}/gws/public_notices/#{notice.id}")
      end
    end
  end

  context 'non-public notice' do
    let!(:notice) do
      create(
        :gws_notice, cur_site: site, cur_user: sender, message_notification: 'enabled', email_notification: 'enabled',
        readable_member_ids: [recipient1.id, recipient2.id], state: 'closed'
      )
    end

    it do
      described_class.bind(site_id: site.id).perform_now

      expect(Gws::Job::Log.count).to eq 1
      Gws::Job::Log.first.tap do |log|
        expect(log.logs).to include(include('INFO -- : Started Job'))
        expect(log.logs).to include(include('INFO -- : Completed Job'))
      end

      # no notifications were send
      expect(Gws::Memo::Message.count).to eq 0
      expect(ActionMailer::Base.deliveries.length).to eq 0
    end
  end
end
