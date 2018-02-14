require 'spec_helper'

describe 'gws_memo_messages', type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:subject) { "subject-#{unique_id}" }
  let(:text) { "text-#{unique_id}\r\ntext-#{unique_id}\r\ntext-#{unique_id}" }

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
            click_on I18n.t('modules.gws/shared_address')
          end
        end

        wait_for_ajax

        within '#cboxLoadedContent' do
          click_on I18n.t('mongoid.models.gws/shared_address/group')
          click_on group.name
        end

        within 'form#item-form' do
          fill_in 'item[subject]', with: subject
          fill_in 'item[text]', with: text

          page.accept_confirm do
            click_on I18n.t('ss.buttons.send')
          end
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.sent'))

        expect(Gws::Memo::Message.all.count).to eq 1
        Gws::Memo::Message.all.first.tap do |message|
          expect(message.subject).to eq subject
          expect(message.text).to eq text
          expect(message.path).to include({ gws_user.id.to_s => 'INBOX' })
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
            click_on I18n.t('mongoid.models.webmail/address')
          end
        end

        wait_for_ajax

        within '#cboxLoadedContent' do
          click_on I18n.t('mongoid.models.webmail/address_group')
          click_on group.name
        end

        within 'form#item-form' do
          fill_in 'item[subject]', with: subject
          fill_in 'item[text]', with: text

          page.accept_confirm do
            click_on I18n.t('ss.buttons.send')
          end
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.sent'))

        expect(Gws::Memo::Message.all.count).to eq 1
        Gws::Memo::Message.all.first.tap do |message|
          expect(message.subject).to eq subject
          expect(message.text).to eq text
          expect(message.path).to include({ gws_user.id.to_s => 'INBOX' })
          expect(message.to_member_name).to eq group.name
          expect(message.from_member_name).to eq gws_user.long_name
          expect(message.to_webmail_address_group_ids).to eq [ group.id ]
          expect(message.member_ids).to eq [ address1.member_id ]
        end
      end
    end
  end
end
