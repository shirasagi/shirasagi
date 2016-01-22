require 'spec_helper'

describe "webapi", dbscope: :example, type: :request do
  before do
    SS.config.replace_value_at(:env, :protect_csrf, false)
  end

  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:node) { create(:article_node_page) }
  let!(:page) { create(:article_page, node: node) }

  ## paths
  let!(:login_path) { sns_login_path(format: :json) }
  let!(:logout_path) { sns_logout_path(format: :json) }
  let!(:page_path) { article_page_path(site: site.id, cid: node.id, id: page.id, format: :json) }
  let!(:update_page_path) { article_page_path(site: site.id, cid: node.id, id: page.id, format: :json) }
  let!(:destroy_page_path) { article_page_path(site: site.id, cid: node.id, id: page.id, format: :json) }

  ## request params
  let!(:correct_login_params) do
    {
      :item => {
        :email => user.email,
        :password => SS::Crypt.encrypt("pass", type: "AES-256-CBC"),
        :encryption_type => "AES-256-CBC"
      }
    }
  end

  context "with login" do
    before do
      post login_path, correct_login_params
      SS.config.replace_value_at(:env, :json_datetime_format, "%Y/%m/%d %H:%M:%S")
    end

    describe "GET /.s{site}/article{cid}/pages/{id}.json" do
      it "200" do
        format = SS.config.env.json_datetime_format

        get page_path
        expect(response.status).to eq 200
        json = JSON.parse(response.body)
        expect(json["_id"]).to eq page.id
        expect(json["name"]).to eq page.name
        expect(json["filename"]).to eq page.filename
        expect(json["depth"]).to eq page.depth
        expect(json["layout_id"]).to eq page.layout_id
        expect(json["body_layout_id"]).to eq page.body_layout_id
        expect(json["body_parts"]).to eq page.body_parts
        expect(json["order"]).to eq page.order
        expect(json["state"]).to eq page.state

        release_date = page.release_date.strftime(format) rescue nil
        expect(json["release_date"]).to eq release_date

        close_date = page.close_date.strftime(format) rescue nil
        expect(json["close_date"]).to eq close_date

        created = page.created.strftime(format) rescue nil
        expect(json["created"]).to eq created

        updated = page.updated.strftime(format) rescue nil
        expect(json["updated"]).to eq updated
      end
    end

    describe "POST /.s{site}/article{cid}/pages/{id}.json" do
      it "204" do
        format = SS.config.env.json_datetime_format
        params = {
          item: {
            name: "更新タイトル",
            body_parts: %w( <div>part0</div> <div>part1</div> <div>part2</div> ),
            layout_id: 1,
            body_layout_id: 1,
            release_date: "2015/11/13 11:00:00",
            close_date: "2015/11/13 12:00:00"
          }
        }

        put update_page_path, params
        expect(response.status).to eq 204
        updated_page = Cms::Page.find(page.id)

        expect(updated_page.name).to eq params[:item][:name]
        expect(updated_page.body_parts).to eq params[:item][:body_parts]
        expect(updated_page.layout_id).to eq params[:item][:layout_id]
        expect("ready").to eq updated_page.state

        release_date = updated_page.release_date.strftime(format) rescue nil
        expect(release_date).to eq params[:item][:release_date]

        close_date = updated_page.close_date.strftime(format) rescue nil
        expect(close_date).to eq params[:item][:close_date]
      end

      it "204" do
        params = { item: { state: "closed" } }
        put update_page_path, params
        expect(response.status).to eq 204
        updated_page = Cms::Page.find(page.id)
        expect(updated_page.state).to eq params[:item][:state]

        params = { item: { state: "public" } }
        put update_page_path, params
        expect(response.status).to eq 204
        updated_page = Cms::Page.find(page.id)
        expect(updated_page.state).to eq params[:item][:state]
      end

      it "400" do
        params = {}
        put update_page_path, params
        expect(response.status).to eq 400
      end

      it "422" do
        params = {
          item: {
            release_date: "2015/11/13 12:00:00",
            close_date: "2015/11/13 11:00:00"
          }
        }
        put update_page_path, params
        expect(response.status).to eq 422
      end
    end

    describe "DELETE /.s{site}/article{cid}/pages/{id}.json" do
      it "204" do
        delete destroy_page_path
        expect(response.status).to eq 204

        expect(Cms::Page.where(id: page.id).first).to eq nil
      end
    end
  end
end
