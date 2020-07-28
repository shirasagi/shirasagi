require 'spec_helper'

describe "gws_notices", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:folder) { create(:gws_notice_folder) }
  let(:index_path) { gws_notice_editables_path(site: site, folder_id: folder, category_id: '-') }

  before do
    ActionMailer::Base.deliveries = []

    site.canonical_scheme = %w(http https).sample
    site.canonical_domain = "#{unique_id}.example.jp"
    site.sender_name = unique_id
    site.sender_email = "#{site.sender_name}@example.jp"
    site.save!

    login_gws_user
  end

  after do
    ActionMailer::Base.deliveries = []
  end

  context 'with notification' do
    let(:name) { unique_id }
    let(:text) { unique_id }
    let!(:recipient1) { create(:gws_user, group_ids: gws_user.group_ids) }
    let!(:recipient2) { create(:gws_user, group_ids: gws_user.group_ids) }

    it do
      visit index_path
      click_on I18n.t('ss.links.new')

      within 'form#item-form' do
        fill_in 'item[name]', with: name
        fill_in 'item[text]', with: text

        within '#addon-gws-agents-addons-readable_setting' do
          click_on I18n.t('ss.apis.users.index')
        end
      end
      wait_for_cbox do
        expect(page).to have_content(recipient1.name)
        click_on recipient1.name
      end
      within 'form#item-form' do
        click_on I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      expect(Gws::Notice::Post.all.count).to eq 1
      Gws::Notice::Post.all.first.tap do |item|
        expect(item.name).to eq name
        expect(item.text).to eq text
        expect(item.notification_noticed).to be_nil
        expect(item.state).to eq 'public'
      end

      # send notification
      Gws::Notice::NotificationJob.bind(site_id: site).perform_now

      # job was succeeded
      expect(Gws::Job::Log.count).to eq 1
      Gws::Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      expect(Gws::Notice::Post.all.count).to eq 1
      Gws::Notice::Post.all.first.tap do |notice|
        # record notification_noticed
        expect(notice.notification_noticed).not_to be_nil

        expect(SS::Notification.count).to eq 1
        SS::Notification.first.tap do |message|
          expect(message.subject).to eq I18n.t('gws_notification.gws/notice/post.subject', name: notice.name)
          expect(message.url).to eq "/.g#{site.id}/notice/-/-/readables/#{notice.id}"
        end
      end
    end
  end
end
