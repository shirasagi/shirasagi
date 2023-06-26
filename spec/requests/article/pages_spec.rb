require 'spec_helper'
require "csv"

describe "Article::PagesController", type: :request, dbscope: :example do
  let!(:group) { cms_group }
  let!(:site) { cms_site }
  let!(:node) { create(:article_node_page) }
  let(:auth_token_path) { sns_auth_token_path(format: :json) }
  let(:index_path) { article_pages_path(site.id, node, format: :json) }
  let!(:admin_user) { cms_user }

  let(:download_pages_path) { download_all_article_pages_path(site: site.id, cid: node.id) }

  context "admin user" do
    before do
      # get and save  auth token
      get auth_token_path
      @auth_token = JSON.parse(response.body)["auth_token"]

      # login
      params = {
        'authenticity_token' => @auth_token,
        'item[email]' => admin_user.email,
        'item[password]' => admin_user.in_password
      }
      post sns_login_path(format: :json), params: params
    end

    describe "GET /pages.json" do
      let!(:page) { create(:article_page, cur_node: node) }

      it do
        get index_path
        expect(response.status).to eq 200
        list = JSON.parse(response.body)
        expect(list.length).to eq 1
        expect(list[0]["_id"]).to eq 1
        expect(list[0]["name"]).to eq page.name
        expect(list[0]["filename"]).to eq page.filename
      end
    end

    describe "POST /pages.json" do
      it do
        params = { 'authenticity_token' => @auth_token,
                   'item[name]' => '記事タイトル',
                   'item[basename]' => "filename#{rand(0xffffffff).to_s(36)}" }
        post index_path, params: params
        expect(response.status).to eq 201
        page = JSON.parse(response.body)
        expect(page["_id"]).to eq 1
        expect(page["name"]).to eq params['item[name]']
        expect(page["filename"]).to eq "#{node.filename}/#{params['item[basename]']}.html"
      end
    end

    describe "GET /page/:id/lock.json" do
      let!(:item) { create(:article_page, cur_node: node) }
      let!(:lock_path) { lock_article_page_path(site.id, node, item, format: :json) }

      context "with no lock" do
        it do
          get lock_path
          expect(response.status).to eq 200

          item.reload
          expect(item.lock_owner_id).to eq admin_user.id
        end
      end

      context "with not owned lock" do
        let(:group) { cms_group }
        let(:user1) { create(:cms_test_user, group: group) }

        before do
          item.acquire_lock(user: user1)
        end

        it do
          get lock_path
          expect(response.status).to eq 423

          item.reload
          expect(item.lock_owner_id).to eq user1.id
        end
      end
    end

    describe "DELETE /page/:id/lock.json" do
      let!(:item) { create(:article_page, cur_node: node) }
      let!(:lock_path) { lock_article_page_path(site.id, node, item, format: :json) }

      context "with owned lock" do
        before do
          item.acquire_lock(user: admin_user)
        end

        it do
          expect(item.lock_owner_id).to eq admin_user.id

          delete lock_path
          expect(response.status).to eq 204

          item.reload
          expect(item.lock_owner_id).to be_nil
        end
      end

      context "with not owned lock" do
        let(:group) { cms_group }
        let(:user1) { create(:cms_test_user, group: group) }

        before do
          item.acquire_lock(user: user1)
        end

        it do
          delete lock_path
          expect(response.status).to eq 423

          item.reload
          expect(item.lock_owner_id).to eq user1.id
        end
      end

      context "with owned lock and unlock twice" do
        before do
          item.acquire_lock(user: admin_user)
        end

        it do
          expect(item.lock_owner_id).to eq admin_user.id

          2.times do
            delete lock_path
            expect(response.status).to eq 204
          end

          item.reload
          expect(item.lock_owner_id).to be_nil
        end
      end
    end

    context "article download" do
      let!(:cate_node) { create(:category_node_page, cur_site: site, cur_node: node, name: "くらしのガイド") }
      let!(:layout) { create(:cms_layout, cur_site: site, name: "記事レイアウト", filename: "page.layout.html") }
      let!(:group) { create(:ss_group, name: "シラサギ市/企画政策部/政策課") }
      let(:released) { Time.zone.now }
      let(:release_date) { Time.zone.now.advance(hours: 1) }
      let(:close_date) { Time.zone.now.advance(hours: 2) }

      before do
        create(:article_page, cur_site: site, cur_node: node,
          name: 'test1_article',
          filename: 'test1_filename.html',
          layout: layout.id,
          order: 0,
          keywords: 'test1_keywords',
          description: 'test1_description',
          summary_html: 'test1_summary_html',
          html: 'test1_html',
          category_ids: [cate_node.id],
          parent_crumb_urls: 'test1_parent_crumb_urls',
          event_name: 'test1_event_name',
          event_recurrences: [{ kind: "date", start_at: "2016/07/06", frequency: "daily", until_on: "2016/07/06" }],
          contact_state: 'show',
          contact_group: group.id,
          contact_charge: 'test1_contact_charge',
          contact_tel: 'test1_contact_tel',
          contact_fax: 'test1_contact_fax',
          contact_email: 'test1_contact_email',
          contact_link_url: 'test1_contact_link_url',
          contact_link_name: 'test1_contact_link_name',
          released: released,
          release_date: release_date,
          close_date: close_date,
          group_ids: [group.id],
          permission_level: 1)
      end

      describe "POST /.s{site}/article{cid}/pages/download_all" do
        it do
          get auth_token_path
          @auth_token = JSON.parse(response.body)["auth_token"]

          params = {
            'authenticity_token' => @auth_token,
            'item[encoding]' => 'Shift_JIS'
          }
          post download_pages_path, params: params
          expect(response.status).to eq 200
          expect(response.headers["Cache-Control"]).to include "no-store"
          expect(response.headers["Transfer-Encoding"]).to eq "chunked"
          body = ::SS::ChunkReader.new(response.body).to_a.join
          body = body.encode("UTF-8", "SJIS")

          csv = ::CSV.parse(body, headers: true)
          expect(csv.length).to eq 1
          expect(csv.headers).to include(Cms::Page.t(:filename), Cms::Page.t(:name), Cms::Page.t(:layout_id))
          csv[0].tap do |row|
            expect(row[Cms::Page.t(:filename)]).to eq "test1_filename.html"
            expect(row[Cms::Page.t(:name)]).to eq "test1_article"
            expect(row[Cms::Page.t(:layout_id)]).to eq "記事レイアウト (#{layout.filename})"
            expect(row[Cms::Page.t(:keywords)]).to eq "test1_keywords"
            expect(row[Cms::Page.t(:description)]).to eq "test1_description"
            expect(row[Cms::Page.t(:summary_html)]).to eq "test1_summary_html"
            expect(row[Cms::Page.t(:html)]).to eq "test1_html"
            expect(row[Cms::Page.t(:category_ids)]).to eq "#{cate_node.name} (#{cate_node.filename})"
            expect(row[Cms::Page.t(:parent_crumb)]).to eq "test1_parent_crumb_urls"
            expect(row[Cms::Page.t(:event_name)]).to eq "test1_event_name"
            expect(row["#{Cms::Page.t(:event_recurrences)}_1_開始日"]).to eq "2016/07/06"
            expect(row["#{Cms::Page.t(:event_recurrences)}_1_終了日"]).to eq "2016/07/06"
            expect(row[Cms::Page.t(:contact_state)]).to eq I18n.t("ss.options.state.show")
            expect(row[Cms::Page.t(:contact_group)]).to eq group.name
            expect(row[Cms::Page.t(:contact_charge)]).to eq "test1_contact_charge"
            expect(row[Cms::Page.t(:contact_tel)]).to eq "test1_contact_tel"
            expect(row[Cms::Page.t(:contact_fax)]).to eq "test1_contact_fax"
            expect(row[Cms::Page.t(:contact_email)]).to eq "test1_contact_email"
            expect(row[Cms::Page.t(:contact_link_url)]).to eq "test1_contact_link_url"
            expect(row[Cms::Page.t(:contact_link_name)]).to eq "test1_contact_link_name"
            expect(row[Cms::Page.t(:released)]).to eq released.strftime("%Y/%m/%d %H:%M")
            expect(row[Cms::Page.t(:release_date)]).to eq release_date.strftime("%Y/%m/%d %H:%M")
            expect(row[Cms::Page.t(:close_date)]).to eq close_date.strftime("%Y/%m/%d %H:%M")
            expect(row[Cms::Page.t(:group_ids)]).to eq group.name
            unless SS.config.ss.disable_permission_level
              expect(row[Cms::Page.t(:permission_level)]).to eq 1
            end
          end
        end
      end
    end
  end

  context "user which does not have unlock privilege" do
    let!(:role) do
      Cms::Role.create!(
        name: "role_#{unique_id}",
        permissions: Cms::Role.permission_names.reject { |name| name.start_with?('unlock_') },
        site_id: site.id
      )
    end
    let!(:user) { create(:cms_test_user, group: group, role: role) }

    before do
      # get and save  auth token
      get auth_token_path
      @auth_token = JSON.parse(response.body)["auth_token"]

      # login
      params = { 'authenticity_token' => @auth_token, 'item[email]' => user.email, 'item[password]' => user.in_password }
      post sns_login_path(format: :json), params: params
    end

    describe "GET /page/:id/lock.json" do
      let!(:item) { create(:article_page, cur_node: node) }
      let!(:lock_path) { lock_article_page_path(site.id, node, item, format: :json) }

      context "with no lock" do
        it do
          get lock_path
          expect(response.status).to eq 200

          item.reload
          expect(item.lock_owner_id).to eq user.id
        end
      end

      context "with not owned lock" do
        let(:group) { cms_group }
        let(:user1) { create(:cms_test_user, group: group) }

        before do
          item.acquire_lock(user: user1)
        end

        it do
          get lock_path
          expect(response.status).to eq 423

          item.reload
          expect(item.lock_owner_id).to eq user1.id
        end
      end
    end

    describe "DELETE /page/:id/lock.json" do
      let!(:item) { create(:article_page, cur_node: node) }
      let!(:lock_path) { lock_article_page_path(site.id, node, item, format: :json) }

      context "with owned lock" do
        before do
          item.acquire_lock(user: user)
        end

        it do
          expect(item.lock_owner_id).to eq user.id

          delete lock_path
          expect(response.status).to eq 204

          item.reload
          expect(item.lock_owner_id).to be_nil
        end
      end

      context "with not owned lock" do
        let(:group) { cms_group }
        let(:user1) { create(:cms_test_user, group: group) }

        before do
          item.acquire_lock(user: user1)
        end

        it do
          delete lock_path
          # expected to get 403 because user does not have unlock privilege
          expect(response.status).to eq 403

          item.reload
          expect(item.lock_owner_id).to eq user1.id
        end
      end

      context "with owned lock and unlock twice" do
        before do
          item.acquire_lock(user: user)
        end

        it do
          expect(item.lock_owner_id).to eq user.id

          2.times do
            delete lock_path
            expect(response.status).to eq 204
          end

          item.reload
          expect(item.lock_owner_id).to be_nil
        end
      end
    end
  end
end
