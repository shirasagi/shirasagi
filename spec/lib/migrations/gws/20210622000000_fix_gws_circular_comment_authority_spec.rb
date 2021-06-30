require 'spec_helper'
require Rails.root.join("lib/migrations/gws/20210622000000_fix_gws_circular_comment_authority.rb")

RSpec.describe SS::Migration20210622000000, dbscope: :example do
  let(:site) { gws_site }
  let(:user) { gws_user }

  let!(:post) { create(:gws_circular_post, :due_date, site: site, user: user, member_ids: [user.id]) }
  let!(:comment1) { create(:gws_circular_comment, site: site, post: post, user: user) }
  let!(:comment2) { create(:gws_circular_comment, site: site, post: post, user: user, browsing_authority: 'all') }
  let!(:comment3) do
    create(:gws_circular_comment, site: site, post: post, user: user, browsing_authority: 'author_or_commenter')
  end

  def browsing_authority(item)
    states = Gws::Circular::Comment.in(id: item.id).pluck(:browsing_authority)
    expect(states.length).to eq 1
    states.first
  end

  it do
    comment1.unset(:browsing_authority)
    comment1.reload

    expect(browsing_authority(post)).to eq nil
    expect(browsing_authority(comment1)).to eq nil
    expect(browsing_authority(comment2)).to eq 'all'
    expect(browsing_authority(comment3)).to eq 'author_or_commenter'

    described_class.new.change

    expect(browsing_authority(post)).to eq nil
    expect(browsing_authority(comment1)).to eq 'all'
    expect(browsing_authority(comment2)).to eq 'all'
    expect(browsing_authority(comment3)).to eq 'author_or_commenter'
  end
end
