require 'spec_helper'
require 'timecop'

describe Gws::Circular::DeleteJob, dbscope: :example do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:started) { Time.zone.now }

  describe '.perform_later' do
    before do
      1.upto(12*3) do |i|
        Timecop.travel(started.ago(i.month)) do
          create(:gws_circular_post, :member_ids, :due_date)
        end
      end
    end

    context 'default removed two years ago' do
      before do
        described_class.bind(site_id: site.id).perform_now
      end

      it do
        expect(Gws::Circular::Post.count).to eq 23
      end
    end

    context 'delete one year ago' do
      before do
        site.circular_delete_threshold = 1
        site.save!
        described_class.bind(site_id: site.id).perform_now
      end

      it do
        expect(Gws::Circular::Post.count).to eq 11
      end
    end
  end
end
