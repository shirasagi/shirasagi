require 'spec_helper'

describe "webmail_gws_messages", type: :feature, dbscope: :example, imap: true do
  let(:user) { create :webmail_user }
  let(:item_title) { "rspec-#{unique_id}" }
  let(:index_path) { webmail_mails_path(account: 0) }
  let(:role) { create :gws_role_admin }

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

      # gws_message
      click_link item_title
      click_link I18n.t('webmail.links.forward_gws_message')

      first('.gws-addon-member .ajax-box').click
      wait_for_cbox

      click_on user.name
      click_button I18n.t('ss.buttons.send')
    end
  end
end
