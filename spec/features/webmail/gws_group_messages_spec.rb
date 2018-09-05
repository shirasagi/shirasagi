require 'spec_helper'

describe "webmail_gws_group_messages", type: :feature, dbscope: :example, imap: true do
  let(:group) { create :webmail_group }
  let(:site) { create :gws_group }
  let(:user) { create :webmail_user, group_ids: [site.id, group.id] }
  let(:role) { create :gws_role_admin, cur_site: site, cur_user: user }
  let(:item_title) { "rspec-#{unique_id}" }
  let(:index_path) { webmail_group_mails_path(group: group) }
  let(:messages_path) do
    groups = gws_user.root_groups.select do |group|
      Gws::Memo::Message.allowed?(:edit, gws_user.gws_user, site: group)
    end
    gws_memo_messages_path(site: groups.first.id)
  end

  context "with auth" do
    before do
      login_user(gws_user)
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

      find(".webmail-navi-mailboxes .mailboxes a.inbox-sent").click

      click_link item_title

      # gws_message
      click_link I18n.t('webmail.links.forward_gws_message')

      first('.gws-addon-memo-member .ajax-box').click
      wait_for_cbox

      click_on gws_user.name
      page.accept_alert do
        click_button I18n.t('ss.buttons.send')
      end

      expect(current_path).to eq messages_path
      click_link item_title
    end
  end
end
