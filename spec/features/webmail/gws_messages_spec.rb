require 'spec_helper'

describe "webmail_gws_messages", type: :feature, dbscope: :example, imap: true do
  let(:site) { create :gws_group }
  let(:user) { create :webmail_user, group_ids: [site.id] }
  let(:role) { create :gws_role_admin, cur_site: site, cur_user: user }
  let(:item_title) { "rspec-#{unique_id}" }
  let(:messages_path) { gws_memo_messages_path(site: site.id) }

  shared_examples "webmail gws messages flow" do
    context "with auth" do
      before { login_user(user) }
      before do
        gws_user = Gws::User.find(user.id)
        gws_user.add_to_set(gws_role_ids: role.id)
      end

      it "#show", js: true do
        # new/create
        visit index_path
        click_link I18n.t('ss.links.new')
        within "form#item-form" do
          fill_in "to", with: user.email + "\n"
          fill_in "item[subject]", with: item_title
          fill_in "item[text]", with: "message\n" * 2
        end
        click_button I18n.t('ss.buttons.send')
        sleep 1
        expect(current_path).to eq index_path

        if Webmail::Mailer.delivery_method == :test
          pending "delivery_method is :test"
        end

        # reload mails
        first(".webmail-navi-mailboxes .reload").click

        click_link item_title

        # gws_message
        click_link I18n.t('webmail.links.forward_gws_message')

        first('.gws-addon-memo-member .ajax-box').click
        wait_for_cbox

        click_on user.name
        page.accept_alert do
          click_button I18n.t('ss.buttons.send')
        end

        expect(current_path).to eq messages_path
        click_link item_title
      end
    end
  end

  describe "webmail_mode is account" do
    let(:index_path) { webmail_mails_path(account: 0) }

    it_behaves_like 'webmail gws messages flow'
  end

  describe "webmail_mode is group" do
    let(:group) { create :webmail_group }
    let(:index_path) { webmail_mails_path(account: group.id, webmail_mode: :group) }

    it_behaves_like 'webmail gws messages flow'
  end
end
