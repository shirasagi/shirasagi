require 'spec_helper'

describe Gws::Circular::SetCommentAuthorityJob, dbscope: :example do
  let(:site) { gws_site }
  let(:post) { create(:gws_circular_post, :gws_circular_posts) }
  let(:comment1) { build(:gws_circular_comment, site: site, post: post, browsing_authority: nil) }
  let(:comment2) { build(:gws_circular_comment, site: site, post: post, browsing_authority: nil) }
  let!(:comment3) { create(:gws_circular_comment, site: site, post: post, browsing_authority: 'all') }
  let!(:comment4) { create(:gws_circular_comment, site: site, post: post, browsing_authority: 'author_or_commenter') }

  describe '#perform' do
    let(:generated_log) { Job::Log.first.logs }

    before do
      comment1.save(validate: false)
      comment2.save(validate: false)
    end

    it do
      expect do
        described_class.bind(site_id: site).perform_now
      end.to change { Gws::Circular::Comment.where(browsing_authority: nil).count }.to(0)
        .and change { comment1.reload.browsing_authority }.from(nil).to('all')
        .and change { comment2.reload.browsing_authority }.from(nil).to('all')
      expect(comment3.reload.browsing_authority).to eq 'all'
      expect(comment4.reload.browsing_authority).to eq 'author_or_commenter'

      expect(Job::Log.count).to eq 1
      expect(generated_log.first).to include("INFO -- : Started Job")
      expect(generated_log.last).to include("INFO -- : Completed Job")
    end
  end
end
