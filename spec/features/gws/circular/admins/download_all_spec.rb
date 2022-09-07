require 'spec_helper'

describe "gws_circular_admins", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:now) { Time.zone.now.beginning_of_minute }
  let!(:user1) { create(:gws_user, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids) }
  let!(:cate1) { create(:gws_circular_category) }
  let!(:cate2) { create(:gws_circular_category) }
  let!(:post1) do
    create(
      :gws_circular_post, due_date: now + 1.day, category_ids: [ cate1.id ], member_ids: [ gws_user.id, user1.id ],
      state: "public"
    )
  end
  let!(:post1_comment1) { create(:gws_circular_comment, post: post1) }

  let!(:post2) do
    create(
      :gws_circular_post, due_date: now + 2.days, category_ids: [ cate2.id ], member_ids: [ gws_user.id, user1.id ],
      state: "public"
    )
  end
  let!(:post2_comment1) { create(:gws_circular_comment, post: post2) }

  let!(:post3) do
    create(
      :gws_circular_post, due_date: now + 3.days, category_ids: [ cate1.id ], member_ids: [ gws_user.id, user1.id ],
      state: "draft"
    )
  end
  let!(:post3_comment1) { create(:gws_circular_comment, post: post3) }

  describe "dwnload all" do
    before { login_gws_user }

    it do
      visit gws_circular_admins_path(site)

      within first(".list-item") do
        first("input[type='checkbox']").click
      end
      within ".list-head" do
        page.accept_confirm do
          click_on I18n.t("gws/circular.post.download")
        end
      end

      wait_for_download

      I18n.with_locale(I18n.default_locale) do
        csv = ::CSV.read(downloads.first, headers: true, encoding: 'SJIS:UTF-8')
        expect(csv.length).to eq 1
        expect(csv[0][I18n.t("gws/circular.csv")[0]]).to eq post3.id.to_s
        expect(csv[0][I18n.t("gws/circular.csv")[1]]).to eq post3.name
        expect(csv[0][I18n.t("gws/circular.csv")[2]]).to eq post3_comment1.id.to_s
        expect(csv[0][I18n.t("gws/circular.csv")[3]]).to eq I18n.t('gws/circular.post.unseen')
      end
    end
  end
end
