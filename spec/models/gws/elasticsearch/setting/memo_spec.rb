require 'spec_helper'

describe Gws::Elasticsearch::Setting::Memo, type: :model, dbscope: :example do
  let(:site) { gws_site }
  let(:user) { gws_user }
  subject { described_class.new(cur_site: site, cur_user: user) }

  describe '#search_types' do
    context "" do
      it do
        expect(subject.search_types).to eq [ :gws_memo_messages ]
      end
    end

    context "when menu is invisible" do
      before do
        site.menu_memo_state = "hide"
        site.save!
      end

      it do
        expect(subject.search_types).to eq []
      end
    end

    context "when user doesn't have permission 'edit_private_gws_memo_messages'" do
      before do
        gws_user.gws_roles.each do |role|
          role.permissions = role.permissions - %w(edit_private_gws_memo_messages)
          role.save!
        end
      end

      it do
        expect(subject.search_types).to eq []
      end
    end
  end
end
