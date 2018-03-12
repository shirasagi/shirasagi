require 'spec_helper'

RSpec.describe Gws::Memo::Notifier, type: :model do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:group) { gws_user.groups.first }
  let(:to_user) { create(:gws_user) }
  let(:file) { create(:gws_workflow_file, cur_site: site, cur_user: user, workflow_user_id: user.id) }

  describe '.deliver_workflow_request!' do
    before do
      Gws::Memo::Notifier.deliver_workflow_request!(
        cur_site: site, cur_group: group, cur_user: user,
        to_users: Gws::User.where(id: to_user.id), item: file,
        url: "http://example.jp/#{unique_id}", comment: unique_id
      )
    end

    it do
      expect(Gws::Memo::Notice.count).to eq 1
    end
  end
end
