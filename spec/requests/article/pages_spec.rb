require 'spec_helper'
require "csv"

describe "Article::PagesController", type: :request, dbscope: :example do
  let!(:group) { cms_group }
  let!(:site) { cms_site }
  let!(:node) { create(:article_node_page) }
  let(:auth_token_path) { sns_auth_token_path(format: :json) }
  let(:index_path) { article_pages_path(site.id, node, format: :json) }
  let!(:admin_user) { cms_user }

  let(:download_pages_path) { download_article_pages_path(site: site.id, cid: node.id) }

  context "admin user" do
    before do
      # get and save  auth token
      get auth_token_path
      @auth_token = JSON.parse(response.body)["auth_token"]

      # login
      params = { 'authenticity_token' => @auth_token, 'item[email]' => admin_user.email,
                 'item[password]' => admin_user.in_password }
      post sns_login_path(format: :json), params
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
        post index_path, params
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
      before do
        #create(:article_page, cur_site: site, cur_node: node, name: 'test1_article')
        create(:cms_node, cur_site: site, name: "くらしのガイド", filename: "filename")
        create(:cms_layout, cur_site: site, name: "記事レイアウト")
        create(:ss_group, name: "シラサギ市/企画政策部/政策課")
        create(:article_page, cur_site: site, cur_node: node,
               name: 'test1_article',
               filename: 'test1_filename.html',
               layout: 1,
               order: 0,
               keywords: 'test1_keywords',
               description: 'test1_description',
               summary_html: 'test1_summary_html',
               html: 'test1_html',
               category_ids: [2],
               parent_crumb_urls: 'test1_parent_crumb_urls',
               event_name: 'test1_event_name',
               event_dates: "2016/7/6",
               contact_state: 'show',
               contact_group: 2,
               contact_charge: 'test1_contact_charge',
               contact_tel: 'test1_contact_tel',
               contact_fax: 'test1_contact_fax',
               contact_email: 'test1_contact_email',
               released: "2016/7/6 0:0:0",
               release_date: "2016/7/6 1:1:1",
               close_date: "2016/7/6 2:2:2",
               group_ids: [2],
               permission_level: 1
        )
      end

      describe "GET /.s{site}/article{cid}/pages/download?ids[]=1" do
        it do
          params = { 'ids[]' => 1 }
          get download_pages_path, params
          expect(response.status).to eq 200

          expect(response.body).to include "test1_article"
          expect(response.body).to include "test1_filename.html"
          expect(response.body).to include "記事レイアウト".encode!("Windows-31J")
          expect(response.body).to include "記事レイアウト,0".encode!("Windows-31J")
          expect(response.body).to include "test1_keywords"
          expect(response.body).to include "test1_description"
          expect(response.body).to include "test1_summary_html"
          expect(response.body).to include "test1_html"
          expect(response.body).to include "くらしのガイド".encode!("Windows-31J")
          expect(response.body).to include "test1_parent_crumb_urls"
          expect(response.body).to include "test1_event_name"
          expect(response.body).to include "2016/07/06"
          expect(response.body).to include "表示".encode!("Windows-31J")
          expect(response.body).to include "表示,シラサギ市/企画政策部/政策課".encode!("Windows-31J")
          expect(response.body).to include "test1_contact_charge"
          expect(response.body).to include "test1_contact_tel"
          expect(response.body).to include "test1_contact_fax"
          expect(response.body).to include "test1_contact_email"
          expect(response.body).to include "2016-07-06T00:00:00+09:00"
          expect(response.body).to include "2016-07-06T01:01:01+09:00"
          expect(response.body).to include "2016-07-06T02:02:02+09:00"
          expect(response.body).to include "09:00,シラサギ市/企画政策部/政策課".encode!("Windows-31J")
          expect(response.body).to include "政策課,1".encode!("Windows-31J")
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
      post sns_login_path(format: :json), params
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
