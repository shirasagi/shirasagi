require 'spec_helper'

describe Gws::User, dbscope: :example do
  let!(:site) { create :gws_group }

  describe ".order_by_title" do
    context "usual case" do
      let!(:title1) { create :gws_user_title, cur_site: site, order: 10 }
      let!(:title2) { create :gws_user_title, cur_site: site, order: 20 }
      let!(:title3) { create :gws_user_title, cur_site: site, order: 30 }

      let!(:user1) { create :gws_user, cur_site: site, in_title_id: title1.id, group_ids: [ site.id ] }
      let!(:user2) { create :gws_user, cur_site: site, in_title_id: title2.id, group_ids: [ site.id ] }
      let!(:user3) { create :gws_user, cur_site: site, in_title_id: title3.id, group_ids: [ site.id ] }
      let!(:user4) { create :gws_user, cur_site: site, in_title_id: nil, group_ids: [ site.id ] }

      it do
        expect(user1.title_orders).to include(site.id.to_s => title1.order)
        expect(user2.title_orders).to include(site.id.to_s => title2.order)
        expect(user3.title_orders).to include(site.id.to_s => title3.order)
        expect(user4.title_orders).to be_blank

        ordered_users = Gws::User.all.site(site).active.order_by_title(site).only(:id).to_a
        expect(ordered_users.length).to eq 4
        expect(ordered_users[0]).to eq user3
        expect(ordered_users[1]).to eq user2
        expect(ordered_users[2]).to eq user1
        expect(ordered_users[3]).to eq user4
      end
    end

    context "title_orders, organization_uid and uid are all blank and apply pagination" do
      # このテストは1ページに表示する項目数が多ければ多いほど良いが、10 に留めておく。
      let(:max_items_per_page) { 10 }

      before do
        names = Array.new(max_items_per_page * 2) { unique_id }
        names.shuffle!

        (max_items_per_page * 2).times do |i|
          user = create(
            :gws_user, name: names[i], email: "#{names[i]}@example.jp", uid: nil, organization_uid: nil, in_title_id: nil,
            group_ids: [ site.id ])
          expect(user.title_orders).to be_blank
        end
      end

      it do
        criteria = Gws::User.all.site(site).active.order_by_title(site).only(:id)
        first_page = criteria.page(nil).per(max_items_per_page)
        second_page = criteria.page(2).per(max_items_per_page)

        first_ordered_users = first_page.to_a
        second_ordered_users = second_page.to_a

        first_page_ids = first_ordered_users.map(&:id)
        second_page_ids = second_ordered_users.map(&:id)
        expect(first_page_ids & second_page_ids).to be_empty
        expect(first_page_ids | second_page_ids).to have(max_items_per_page * 2).items
      end
    end
  end
end
