require 'spec_helper'

describe 'gws/memo/notices', type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let!(:sender) { create(:gws_user, cur_site: site, group_ids: user.group_ids, gws_role_ids: user.gws_role_ids) }
  let!(:other) { create(:gws_user, cur_site: site, group_ids: user.group_ids, gws_role_ids: user.gws_role_ids) }
  let!(:item) do
    SS::Notification.create!(
      cur_group: site, cur_user: sender,
      subject: "subject-#{unique_id}", format: "text", text: "text-#{unique_id}",
      member_ids: [user.id], state: "public"
    )
  end

  context "when the notification is sent by another user" do
    before { login_gws_user }

    it do
      visit gws_memo_notice_path(site: site, id: item.id)
      expect(status_code).to eq 200
      expect(page).to have_content(item.subject)
    end
  end

  context "when the user is not a member" do
    before { login_user other }

    it do
      visit gws_memo_notice_path(site: site, id: item.id)
      expect(status_code).to eq 404
    end
  end
end
