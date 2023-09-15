require 'spec_helper'

describe 'gws_memo_messages', type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:subject) { "subject-#{unique_id}" }
  let(:text) { Array.new(3) { "text-#{unique_id}" } }

  context 'sending messages by using group' do
    before { login_gws_user }

    context 'with gws/shared_address/group' do
      let!(:group) { create(:gws_shared_address_group, cur_site: site, cur_user: user) }
      let!(:address1) do
        create(:gws_shared_address_address, cur_site: site, cur_user: user, address_group_id: group.id, member_id: user.id)
      end

      it do
        visit gws_memo_messages_path(site)
        click_on I18n.t('ss.links.new')

        within 'form#item-form' do
          within 'dl.see.to' do
            wait_cbox_open { click_on I18n.t('modules.gws/shared_address') }
          end
        end

        wait_for_cbox do
          expect(page).to have_content(group.name)
          click_on I18n.t('mongoid.models.gws/shared_address/group')
          wait_cbox_close { click_on group.name }
        end

        within 'form#item-form' do
          expect(page).to have_content(group.name)

          fill_in 'item[subject]', with: subject
          fill_in 'item[text]', with: text.join("\n")

          page.accept_confirm do
            click_on I18n.t('ss.buttons.send')
          end
        end
        wait_for_notice I18n.t('ss.notice.sent')

        expect(Gws::Memo::Message.all.count).to eq 1
        Gws::Memo::Message.all.first.tap do |message|
          expect(message.subject).to eq subject
          expect(message.text).to eq text.join("\r\n")
          expect(message.user_settings).to include({ 'user_id' => gws_user.id, 'path' => 'INBOX' })
          expect(message.to_member_name).to eq group.name
          expect(message.from_member_name).to eq gws_user.long_name
          expect(message.to_shared_address_group_ids).to eq [ group.id ]
          expect(message.member_ids).to eq [ address1.member_id ]
        end
      end
    end

    context 'with webmail/address_group' do
      let!(:group) { create(:webmail_address_group, cur_user: user) }
      let!(:address1) do
        create(:webmail_address, cur_user: user, address_group_id: group.id, member_id: user.id)
      end

      it do
        visit gws_memo_messages_path(site)
        click_on I18n.t('ss.links.new')

        within 'form#item-form' do
          within 'dl.see.to' do
            wait_cbox_open { click_on I18n.t('mongoid.models.webmail/address') }
          end
        end

        wait_for_cbox do
          expect(page).to have_content(group.name)
          click_on I18n.t('mongoid.models.webmail/address_group')
          wait_cbox_close { click_on group.name }
        end

        within 'form#item-form' do
          fill_in 'item[subject]', with: subject
          fill_in 'item[text]', with: text.join("\n")

          page.accept_confirm do
            click_on I18n.t('ss.buttons.send')
          end
        end
        wait_for_notice I18n.t('ss.notice.sent')

        expect(Gws::Memo::Message.all.count).to eq 1
        Gws::Memo::Message.all.first.tap do |message|
          expect(message.subject).to eq subject
          expect(message.text).to eq text.join("\r\n")
          expect(message.user_settings).to include({ 'user_id' => gws_user.id, 'path' => 'INBOX' })
          expect(message.to_member_name).to eq group.name
          expect(message.from_member_name).to eq gws_user.long_name
          expect(message.to_webmail_address_group_ids).to eq [ group.id ]
          expect(message.member_ids).to eq [ address1.member_id ]
        end
      end
    end
  end
end
