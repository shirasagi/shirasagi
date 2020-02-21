require 'spec_helper'

describe "gws_user_profiles", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:states) { Gws::UserPresence.new.state_options.map(&:reverse).to_h }
  let(:presence) do
    item = Gws::UserPresence.new(cur_user: user, cur_site: site)
    item.presence_state = 'available'
    item.presence_plan = unique_id
    item.presence_memo = unique_id
    item.save ? item : nil
  end

  context "with auth" do
    before { login_gws_user }

    it "#show" do
      expect(presence.present?).to be_truthy

      visit gws_user_profile_path(site: site)
      within '.main-box' do
        expect(page).to have_content(user.name)
      end

      visit gws_user_profile_path(site: site, format: :json)
      json = JSON.parse(page.body)

      expect(json['user']['_id']).to eq user.id
      expect(json['user']['presence_state']).to eq 'available'
      expect(json['user']['presence_state_label']).to eq states['available'] # 在席
      expect(json['user']['presence_state_style']).to eq 'active'
      expect(json['user']['presence_plan'].present?).to be_truthy
      expect(json['user']['presence_memo'].present?).to be_truthy
      expect(json['group']['_id'].present?).to be_truthy
      expect(json['imap_setting']['address'].present?).to be_truthy
    end
  end
end
