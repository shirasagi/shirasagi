require 'spec_helper'

describe 'gws_memo_list_messages', type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:quota_size) { rand(10) }
  let!(:sender) { create(:gws_user, cur_site: site, gws_role_ids: gws_user.gws_role_ids) }
  let!(:recipient) { create(:gws_user, cur_site: site, gws_role_ids: gws_user.gws_role_ids) }
  let!(:list) { create(:gws_memo_list, cur_site: site, member_ids: [sender.id, recipient.id]) }
  let(:subject) { "subject-#{unique_id}" }
  let(:text) { "text-#{unique_id}\r\ntext-#{unique_id}\r\ntext-#{unique_id}" }

  before do
    site.memo_quota = quota_size
    site.save!
  end

  context 'when total size is over quota' do
    before do
      msg = create(:gws_memo_message, cur_site: site, cur_user: gws_user, in_to_members: [recipient.id.to_s])
      msg.filtered[gws_user.id.to_s] = Time.zone.now
      msg.filtered[sender.id.to_s] = Time.zone.now
      msg.filtered[recipient.id.to_s] = Time.zone.now
      msg.save

      msg.set(size: quota_size * 1024 * 1024)
    end

    before { login_user sender }

    it do
      visit gws_memo_list_messages_path(site: site, list_id: list)
      click_on I18n.t('ss.links.new')

      within 'form#item-form' do
        fill_in 'item[subject]', with: subject
        fill_in 'item[text]', with: text

        click_on I18n.t('ss.buttons.draft_save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      visit gws_memo_list_messages_path(site: site, list_id: list)
      click_on subject
      click_on I18n.t('gws/memo.links.publish')
      within 'form#item-form' do
        expect(page).to have_content(I18n.t('gws/memo.notice.capacity_over_members'))
        expect(page).to have_content(recipient.long_name)

        click_on I18n.t('ss.buttons.send')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.sent'))

      expect(Gws::Memo::ListMessage.all.and_list_message.count).to eq 1
      Gws::Memo::ListMessage.all.and_list_message.first do |message|
        expect(message.subject).to eq subject
        expect(message.text).to eq text
        expect(message.member_ids).to eq [sender.id]
      end
    end
  end
end
