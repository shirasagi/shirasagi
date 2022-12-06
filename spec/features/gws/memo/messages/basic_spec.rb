require 'spec_helper'

describe 'gws_memo_messages', type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user1) { gws_user }
  let!(:user2) { create(:gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids) }
  let!(:memo) { create(:gws_memo_message, user: user2, site: site, request_mdn_ids: [user1.id]) }
  let!(:draft_memo) { create(:gws_memo_message, :with_draft, site: site, in_to_members: [user2.id.to_s]) }
  let!(:sent_memo) { create(:gws_memo_message, site: site, in_to_members: [user2.id.to_s]) }
  let!(:trash_memo) { create(:gws_memo_message, user: user2, site: site, in_path: { user1.id.to_s => 'INBOX.Trash' }) }
  let!(:folder) { create(:gws_memo_folder, user: user1, site: site) }
  let(:subject) { unique_id }
  let(:text) { Array.new(rand(2..3)) { unique_id }.join("\n") }

  context 'with auth' do
    before { login_gws_user }

    it '#index' do
      visit gws_memo_messages_path(site)
      wait_for_ajax

      within '.gws-memo-folder' do
        expect(page).to have_css('.title', text: I18n.t("gws/memo/folder.inbox"))
      end

      # popup
      within ".gws-memo-message" do
        expect(page).to have_css(".unseen", text: '2')
        first(".toggle-popup-notice").click

        within ".popup-notice" do
          expect(page).to have_content(memo.subject)
          click_on memo.subject
        end
      end
      within '.gws-memo .addon-head' do
        expect(page).to have_css('.subject', text: memo.subject)
      end
    end

    it '#show' do
      visit gws_memo_messages_path(site)
      within '.list-items' do
        expect(page).to have_no_css(".list-item.seen")
        expect(page).to have_css(".list-item.unseen")
        click_link memo.name
      end
      within '.gws-memo .addon-head' do
        expect(page).to have_content(memo.subject)
        expect(page).to have_no_content(draft_memo.subject)
      end
      click_link I18n.t('ss.links.back_to_index')
      within '.list-items' do
        expect(page).to have_css(".list-item.seen")
        expect(page).to have_no_css(".list-item.unseen")
      end
    end

    it '#new' do
      visit gws_memo_messages_path(site)
      click_on I18n.t('ss.links.new')

      within 'form#item-form' do
        click_on I18n.t("webmail.links.show_cc_bcc")
        within 'dl.see.to' do
          wait_cbox_open { click_on I18n.t('gws.organization_addresses') }
        end
      end
      wait_for_cbox do
        expect(page).to have_content(user2.name)
        wait_cbox_close { click_on user2.name }
      end
      within 'form#item-form' do
        within 'dl.see.to' do
          expect(page).to have_css(".index", text: user2.name)
        end
        click_on I18n.t('ss.buttons.draft_save')
      end
      message = I18n.t('errors.messages.blank')
      message = I18n.t("errors.format", attribute: Gws::Memo::Message.t(:subject), message: message)
      wait_for_error message

      within 'form#item-form' do
        fill_in 'item[subject]', with: subject
        fill_in 'item[text]', with: text
        accept_confirm do
          click_on I18n.t('gws/memo/message.commit_params_check')
        end
      end
      wait_for_notice I18n.t("ss.notice.sent")
    end

    it '#edit' do
      visit edit_gws_memo_message_path(site: site, folder: 'INBOX.Draft', id: draft_memo.id)
      within 'form#item-form' do
        fill_in 'item[subject]', with: ''
        click_on I18n.t('ss.buttons.draft_save')
      end
      message = I18n.t('errors.messages.blank')
      message = I18n.t("errors.format", attribute: Gws::Memo::Message.t(:subject), message: message)
      wait_for_error message

      within 'form#item-form' do
        fill_in 'item[subject]', with: subject

        accept_confirm do
          click_on I18n.t('gws/memo/message.commit_params_check')
        end
      end
      wait_for_notice I18n.t("ss.notice.sent")
    end

    it '#reply' do
      visit reply_gws_memo_message_path(site: site, folder: 'INBOX', id: memo.id)
      within 'form#item-form' do
        fill_in 'item[text]', with: text

        accept_confirm do
          click_on I18n.t('gws/memo/message.commit_params_check')
        end
      end
      wait_for_notice I18n.t("ss.notice.sent")
    end

    it '#reply_all' do
      visit reply_all_gws_memo_message_path(site: site, folder: 'INBOX', id: memo.id)
      within 'form#item-form' do
        fill_in 'item[text]', with: text

        accept_confirm do
          click_on I18n.t('gws/memo/message.commit_params_check')
        end
      end
      wait_for_notice I18n.t("ss.notice.sent")
    end

    it '#forward' do
      visit forward_gws_memo_message_path(site: site, folder: 'INBOX', id: memo.id)
      within 'form#item-form' do
        click_on I18n.t("webmail.links.show_cc_bcc")

        within 'dl.see.to' do
          wait_cbox_open do
            click_on I18n.t('gws.organization_addresses')
          end
        end
      end

      wait_for_cbox do
        expect(page).to have_content(user2.name)
        wait_cbox_close do
          click_on user2.name
        end
      end

      within 'form#item-form' do
        within 'dl.see.to' do
          expect(page).to have_css(".index", text: user2.name)
        end
        accept_confirm do
          click_on I18n.t('gws/memo/message.commit_params_check')
        end
      end
      wait_for_notice I18n.t("ss.notice.sent")
    end

    it '#ref' do
      visit ref_gws_memo_message_path(site: site, folder: 'INBOX', id: memo.id)
      within 'form#item-form' do
        click_on I18n.t("webmail.links.show_cc_bcc")

        within 'dl.see.to' do
          wait_cbox_open do
            click_on I18n.t('gws.organization_addresses')
          end
        end
      end

      wait_for_cbox do
        expect(page).to have_content(user2.name)
        wait_cbox_close do
          click_on user2.name
        end
      end

      within 'form#item-form' do
        within 'dl.see.to' do
          expect(page).to have_css(".index", text: user2.name)
        end
        fill_in 'item[text]', with: text

        accept_confirm do
          click_on I18n.t('gws/memo/message.commit_params_check')
        end
      end
      wait_for_notice I18n.t("ss.notice.sent")
    end

    it '#send_mdn' do
      visit gws_memo_messages_path(site)
      click_link memo.name
      click_button I18n.t('webmail.buttons.send_mdn')
      expect(page).to have_css('#notice', text: I18n.t("gws/memo/message.notice.send_mdn"))
    end

    it '#ignore_mdn' do
      visit gws_memo_messages_path(site)
      click_link memo.name
      click_button I18n.t('webmail.buttons.ignore_mdn')
      expect(page).to have_css('#notice', text: I18n.t("gws/memo/message.notice.ignore_mdn"))
    end

    it '#print' do
      visit print_gws_memo_message_path(site: site, folder: 'INBOX', id: memo.id)
      expect(page).to have_content(memo.subject)
    end

    it '#trash' do
      visit trash_gws_memo_message_path(site: site, folder: 'INBOX', id: memo.id)
      expect(page).to have_content(I18n.t("gws/memo/folder.inbox_trash"))
    end

    it '#trash_all' do
      visit gws_memo_messages_path(site)
      expect(page).to have_selector('li.list-item')

      find('.list-head label.check input').set(true)
      page.accept_confirm do
        find('.trash-all').click
      end
      wait_for_ajax
      expect(page).to have_no_selector('li.list-item')

      click_link I18n.t('gws/memo/folder.inbox_trash')
      expect(page).to have_selector('li.list-item')

      find('.list-head label.check input').set(true)
      page.accept_confirm do
        find('.destroy-all').click
      end
      wait_for_ajax
      expect(page).to have_no_selector('li.list-item')
    end

    it '#delete' do
      visit delete_gws_memo_message_path(site: site, folder: 'INBOX.Trash', id: trash_memo.id)
      within 'form' do
        click_button I18n.t('ss.buttons.delete')
      end
      expect(current_path).to eq gws_memo_messages_path(site, folder: 'INBOX.Trash')
    end

    it '#set_seen_all and #unset_seen_all' do
      visit gws_memo_messages_path(site)
      find('.list-head label.check input').set(true)
      page.accept_confirm do
        click_button I18n.t("gws/memo/message.links.etc")
        find('.set-seen-all').click
      end
      wait_for_ajax
      expect(page).to have_css(".list-item.seen")
      expect(page).to have_no_css(".list-item.unseen")

      find('.list-head label.check input').set(true)
      page.accept_confirm do
        click_button I18n.t("gws/memo/message.links.etc")
        find('.unset-seen-all').click
      end
      wait_for_ajax
      expect(page).to have_css(".list-item.unseen")
      expect(page).to have_no_css(".list-item.seen")
    end

    it '#set_star_all and #unset_star_all' do
      visit gws_memo_messages_path(site)
      find('.list-head label.check input').set(true)
      click_button I18n.t("gws/memo/message.links.etc")
      wait_for_ajax
      page.accept_confirm do
        click_link I18n.t("gws/memo/message.links.set_star")
      end
      wait_for_ajax
      expect(page).to have_css(".icon.icon-star.on")
      expect(page).to have_no_css(".icon.icon-star.off")

      find('.list-head label.check input').set(true)
      click_button I18n.t("gws/memo/message.links.etc")
      wait_for_ajax
      page.accept_confirm do
        click_link I18n.t("gws/memo/message.links.unset_star")
      end
      wait_for_ajax
      expect(page).to have_css(".icon.icon-star.off")
      expect(page).to have_no_css(".icon.icon-star.on")
    end

    it '#move_all' do
      visit gws_memo_messages_path(site)
      wait_for_ajax
      expect(page).to have_content(I18n.t("gws/memo/folder.inbox"))
      expect(page).to have_content(I18n.t("gws/memo/folder.inbox_trash"))
      find('.list-head label.check input').set(true)
      page.accept_confirm do
        within ".move-menu" do
          click_button I18n.t("ss.links.move")
          click_link folder.name
        end
      end
      wait_for_ajax
      expect(page).to have_content(I18n.t("gws/memo/folder.inbox"))
      expect(page).to have_content(I18n.t("gws/memo/folder.inbox_trash"))
    end

    it '#latest' do
      visit latest_gws_memo_messages_path(site, format: 'json')
      expect(page).to have_content(memo.subject)
    end
  end
end
