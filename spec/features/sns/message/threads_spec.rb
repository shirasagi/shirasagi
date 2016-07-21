require 'spec_helper'

describe "sns_message_threads", type: :feature, dbscope: :example do
  let(:group) { create :ss_group }
  let!(:user1) { create :ss_user, group_ids: [group.id] }
  let!(:user2) { create :ss_user2, group_ids: [group.id] }
  let!(:user3) { create :ss_user3, group_ids: [group.id] }
  let(:item) { create :sns_message_thread, member_ids: [user1.id, user2.id, user3.id] }
  let(:path) { sns_message_threads_path }

  it "without login" do
    visit path
    expect(current_path).to eq sns_login_path
  end

  context "with auth" do
    before { login_ss_user }

    it "#index" do
      visit path
      expect(status_code).to eq 200
      expect(current_path).to eq path
    end

    it "#new", js: true do
      visit "#{path}/new"
      first('.sns-message-thread-members .ajax-box').click
      wait_for_cbox
      first('a', text: user2.long_name).trigger('click')

      within "form#item-form" do
        fill_in "item[text]", with: "text"
        first('.save').click
      end
      expect(status_code).to eq 200
    end

    it "#show" do
      visit "#{path}/#{item.id}"
      expect(status_code).to eq 200
    end

    it "#edit" do
      visit "#{path}/#{item.id}/edit"
      within "form#item-form" do
        first('.save').click
      end
      expect(status_code).to eq 200
    end

    it "#delete" do
      visit "#{path}/#{item.id}/delete"
      within "form" do
        first('.delete').click
      end
      expect(status_code).to eq 200
      expect(current_path).to eq path
    end
  end
end
