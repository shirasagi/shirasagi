require 'spec_helper'

describe 'gws_circular_comment_authority', type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:post) { create(:gws_circular_post, :due_date, site: site, user: user1, member_ids: [user1.id, user2.id, user3.id]) }
  let!(:comment1) { create(:gws_circular_comment, site: site, post: post, user: user2, browsing_authority: 'all') }
  let!(:comment2) do
    create(:gws_circular_comment, site: site, post: post, user: user2, browsing_authority: 'author_or_commenter')
  end
  let(:user1) { create(:gws_user, :gws_user_base) }
  let(:user2) { create(:gws_user, :gws_user_base) }
  let(:user3) { create(:gws_user, :gws_user_base) }
  let(:circular_show_path) { gws_circular_post_path site, post }

  context 'circular author' do
    before do
      login_user user1
      visit circular_show_path
    end

    it do
      within 'div.comments' do
        expect(all('aside.comment').count).to eq 2
        expect(page).to have_content comment1.name
        expect(page).to have_content comment2.name
      end
    end
  end

  context 'commenter' do
    before do
      login_user user2
      visit circular_show_path
    end

    it do
      within 'div.comments' do
        expect(all('aside.comment').count).to eq 2
        expect(page).to have_content comment1.name
        expect(page).to have_content comment2.name
      end
    end
  end

  context 'not circular author and not commenter' do
    before do
      login_user user3
      visit circular_show_path
    end

    it do
      within 'div.comments' do
        expect(all('aside.comment').count).to eq 1
        expect(page).to have_content comment1.name
        expect(page).to have_no_content comment2.name
      end
    end
  end
end
