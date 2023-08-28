require 'spec_helper'

describe "gws_circular_posts", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:now) { Time.zone.now.beginning_of_minute }
  let!(:user1) { create(:gws_user, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids) }
  let!(:cate1) { create(:gws_circular_category) }
  let!(:cate2) { create(:gws_circular_category) }
  let!(:post1) do
    travel_to(now - 2.days) do
      create(
        :gws_circular_post, due_date: now + 1.day, category_ids: [ cate1.id ], member_ids: [ gws_user.id, user1.id ],
        state: "public"
      )
    end
  end
  let!(:post2) do
    travel_to(now - 1.day) do
      create(
        :gws_circular_post, due_date: now + 2.days, category_ids: [ cate2.id ], member_ids: [ gws_user.id, user1.id ],
        state: "public"
      )
    end
  end
  let!(:post3) do
    travel_to(now - 3.days) do
      create(
        :gws_circular_post, due_date: now + 3.days, category_ids: [ cate1.id ], member_ids: [ gws_user.id, user1.id ],
        state: "public"
      )
    end
  end

  before do
    travel_to(now - 1.hour) do
      post1.update!(name: "name-#{unique_id}")
      post1.set_seen!(gws_user)
    end

    travel_to(now - 3.hours) do
      post2.update!(name: "name-#{unique_id}")
    end

    travel_to(now - 2.hours) do
      post3.update!(name: "name-#{unique_id}")
    end
  end

  describe "list search" do
    before { login_gws_user }

    context "with sort" do
      context "with due_date_desc" do
        it do
          visit gws_circular_main_path(site: site)
          within ".list-items" do
            expect(page).to have_css(".list-item .title", text: post1.name)
            expect(page).to have_css(".list-item .title", text: post2.name)
            expect(page).to have_css(".list-item .title", text: post3.name)
          end

          within ".list-head form.search" do
            select I18n.t("gws/circular.options.sort.due_date_desc"), from: "s[sort]"
            click_on I18n.t('ss.buttons.search')
          end
          within ".list-items" do
            within first(".list-item") do
              expect(page).to have_css(".title", text: post3.name)
            end
          end
        end
      end

      context "with due_date_asc" do
        it do
          visit gws_circular_main_path(site: site)
          within ".list-items" do
            expect(page).to have_css(".list-item .title", text: post1.name)
            expect(page).to have_css(".list-item .title", text: post2.name)
            expect(page).to have_css(".list-item .title", text: post3.name)
          end

          within ".list-head form.search" do
            select I18n.t("gws/circular.options.sort.due_date_asc"), from: "s[sort]"
            click_on I18n.t('ss.buttons.search')
          end
          within ".list-items" do
            within first(".list-item") do
              expect(page).to have_css(".title", text: post1.name)
            end
          end
        end
      end

      context "with updated_desc" do
        it do
          visit gws_circular_main_path(site: site)
          within ".list-items" do
            expect(page).to have_css(".list-item .title", text: post1.name)
            expect(page).to have_css(".list-item .title", text: post2.name)
            expect(page).to have_css(".list-item .title", text: post3.name)
          end

          within ".list-head form.search" do
            select I18n.t("gws/circular.options.sort.updated_desc"), from: "s[sort]"
            click_on I18n.t('ss.buttons.search')
          end
          within ".list-items" do
            within first(".list-item") do
              expect(page).to have_css(".title", text: post1.name)
            end
          end
        end
      end

      context "with updated_asc" do
        it do
          visit gws_circular_main_path(site: site)
          within ".list-items" do
            expect(page).to have_css(".list-item .title", text: post1.name)
            expect(page).to have_css(".list-item .title", text: post2.name)
            expect(page).to have_css(".list-item .title", text: post3.name)
          end

          within ".list-head form.search" do
            select I18n.t("gws/circular.options.sort.updated_asc"), from: "s[sort]"
            click_on I18n.t('ss.buttons.search')
          end
          within ".list-items" do
            within first(".list-item") do
              expect(page).to have_css(".title", text: post2.name)
            end
          end
        end
      end

      context "with created_desc" do
        it do
          visit gws_circular_main_path(site: site)
          within ".list-items" do
            expect(page).to have_css(".list-item .title", text: post1.name)
            expect(page).to have_css(".list-item .title", text: post2.name)
            expect(page).to have_css(".list-item .title", text: post3.name)
          end

          within ".list-head form.search" do
            select I18n.t("gws/circular.options.sort.created_desc"), from: "s[sort]"
            click_on I18n.t('ss.buttons.search')
          end
          within ".list-items" do
            within first(".list-item") do
              expect(page).to have_css(".title", text: post2.name)
            end
          end
        end
      end

      context "with created_asc" do
        it do
          visit gws_circular_main_path(site: site)
          within ".list-items" do
            expect(page).to have_css(".list-item .title", text: post1.name)
            expect(page).to have_css(".list-item .title", text: post2.name)
            expect(page).to have_css(".list-item .title", text: post3.name)
          end

          within ".list-head form.search" do
            select I18n.t("gws/circular.options.sort.created_asc"), from: "s[sort]"
            click_on I18n.t('ss.buttons.search')
          end
          within ".list-items" do
            within first(".list-item") do
              expect(page).to have_css(".title", text: post3.name)
            end
          end
        end
      end
    end

    context "with keyword" do
      it do
        visit gws_circular_main_path(site: site)
        within ".list-items" do
          expect(page).to have_css(".list-item .title", text: post1.name)
          expect(page).to have_css(".list-item .title", text: post2.name)
          expect(page).to have_css(".list-item .title", text: post3.name)
        end

        within ".list-head form.search" do
          fill_in "s[keyword]", with: post1.name
          click_on I18n.t('ss.buttons.search')
        end
        within ".list-items" do
          expect(page).to have_css(".list-item .title", text: post1.name)
          expect(page).to have_no_css(".list-item .title", text: post2.name)
          expect(page).to have_no_css(".list-item .title", text: post3.name)
        end

        within ".list-head form.search" do
          fill_in "s[keyword]", with: unique_id
          click_on I18n.t('ss.buttons.search')
        end
        within ".list-items" do
          expect(page).to have_no_css(".list-item .title", text: post1.name)
          expect(page).to have_no_css(".list-item .title", text: post2.name)
          expect(page).to have_no_css(".list-item .title", text: post3.name)
        end
      end
    end

    context "with article_state" do
      it do
        visit gws_circular_main_path(site: site)
        within ".list-items" do
          expect(page).to have_css(".list-item .title", text: post1.name)
          expect(page).to have_css(".list-item .title", text: post2.name)
          expect(page).to have_css(".list-item .title", text: post3.name)
        end

        within ".list-head form.search" do
          select I18n.t("gws/circular.options.article_state.both"), from: "s[article_state]"
          click_on I18n.t('ss.buttons.search')
        end
        within ".list-items" do
          expect(page).to have_css(".list-item .title", text: post1.name)
          expect(page).to have_css(".list-item .title", text: post2.name)
          expect(page).to have_css(".list-item .title", text: post3.name)
        end

        within ".list-head form.search" do
          select I18n.t("gws/circular.options.article_state.unseen"), from: "s[article_state]"
          click_on I18n.t('ss.buttons.search')
        end
        within ".list-items" do
          expect(page).to have_no_css(".list-item .title", text: post1.name)
          expect(page).to have_css(".list-item .title", text: post2.name)
          expect(page).to have_css(".list-item .title", text: post3.name)
        end
      end
    end
  end
end
