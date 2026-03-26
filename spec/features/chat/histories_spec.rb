require 'spec_helper'

describe "chat_histories", type: :feature, js: true do
  let!(:site) { cms_site }
  let!(:user) { cms_user }

  context "IDOR vulnerability" do
    let!(:chat_bot_node1) { create :chat_node_bot, cur_site: site, state: "public", group_ids: user.group_ids }
    let!(:chat_bot_node2) { create :chat_node_bot, cur_site: site, state: "public", group_ids: user.group_ids }
    let!(:chat_history1) do
      Chat::History.create!(
        cur_site: site, node: chat_bot_node1, text: "text-#{unique_id}", click_suggest: "text-#{unique_id}",
        request_id: SecureRandom.uuid)
    end
    let!(:chat_history2) do
      Chat::History.create!(
        cur_site: site, node: chat_bot_node2, text: "text-#{unique_id}", click_suggest: "text-#{unique_id}",
        request_id: SecureRandom.uuid)
    end

    it do
      login_user user, to: chat_histories_path(site: site, cid: chat_bot_node1)
      expect(page).to have_css(".list-item[data-id='#{chat_history1.id}']", text: chat_history1.text)
      expect(page).to have_no_css(".list-item[data-id='#{chat_history2.id}']")

      visit chat_histories_path(site: site, cid: chat_bot_node2)
      expect(page).to have_css(".list-item[data-id='#{chat_history2.id}']", text: chat_history2.text)
      expect(page).to have_no_css(".list-item[data-id='#{chat_history1.id}']")

      # アクセスできないはずの chat_bot_node1 上で chat_history2 を表示してみる
      visit chat_history_path(site: site, cid: chat_bot_node1, id: chat_history2)
      expect(page).to have_title(/404 Not Found/)

      visit delete_chat_history_path(site: site, cid: chat_bot_node1, id: chat_history2)
      expect(page).to have_title(/404 Not Found/)

      # アクセスできないはずの chat_bot_node2 上で chat_history1 を表示してみる
      visit chat_history_path(site: site, cid: chat_bot_node2, id: chat_history1)
      expect(page).to have_title(/404 Not Found/)

      visit delete_chat_history_path(site: site, cid: chat_bot_node2, id: chat_history1)
      expect(page).to have_title(/404 Not Found/)
    end
  end
end
