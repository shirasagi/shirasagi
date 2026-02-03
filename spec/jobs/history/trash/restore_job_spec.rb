require 'spec_helper'

describe History::Trash::RestoreJob, dbscope: :example do
  let!(:site) { cms_site }
  let!(:admin) { cms_user }

  context "when a page is restored" do
    let!(:node) { create :article_node_page, cur_site: site }
    let(:page0) do
      item = build(
        :article_page, cur_site: site, cur_node: node, basename: "basename-#{unique_id}",
        name: "name-#{unique_id}", index_name: "index-name-#{unique_id}", state: "public")
      item.validate!
      item
    end
    let!(:page_in_trash) do
      History::Trash.create!(
        cur_site: site, version: SS.version, ref_coll: page0.class.collection_name.to_s,
        ref_class: page0.class.name, data: page0.attributes, action: "save", state: nil)
    end

    context "restored as-is" do
      it do
        expect do
          job = described_class.bind(site_id: site, user_id: admin)
          restore_params = {}
          file_params = nil
          ss_perform_now(job, page_in_trash.id.to_s, restore_params: restore_params, file_params: file_params)
        end.to output.to_stdout

        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
          expect(log.logs).not_to include(/Error -- :/)
        end

        expect(Article::Page.all.count).to eq 1
        Article::Page.all.first.tap do |item|
          expect(item.site_id).to eq site.id
          expect(item.name).to eq page0.name
          expect(item.index_name).to eq page0.index_name
          expect(item.filename).to eq page0.filename
          expect(item.state).to eq "closed"
        end
      end
    end

    context "restored with different name and index_name" do
      let(:name) { "name-#{unique_id}" }
      let(:index_name) { "index-name-#{unique_id}" }

      it do
        expect do
          job = described_class.bind(site_id: site, user_id: admin)
          restore_params = { name: name, index_name: index_name }
          file_params = nil
          ss_perform_now(job, page_in_trash.id.to_s, restore_params: restore_params, file_params: file_params)
        end.to output.to_stdout

        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
          expect(log.logs).not_to include(/Error -- :/)
        end

        expect(Article::Page.all.count).to eq 1
        Article::Page.all.first.tap do |item|
          expect(item.site_id).to eq site.id
          expect(item.name).not_to eq page0.name
          expect(item.name).to eq name
          expect(item.index_name).not_to eq page0.index_name
          expect(item.index_name).to eq index_name
          expect(item.filename).to eq page0.filename
          expect(item.state).to eq "closed"
        end
      end
    end

    context "restored with different basename" do
      let(:basename) { "basename-#{unique_id}" }

      it do
        expect do
          job = described_class.bind(site_id: site, user_id: admin)
          restore_params = { basename: basename }
          file_params = nil
          ss_perform_now(job, page_in_trash.id.to_s, restore_params: restore_params, file_params: file_params)
        end.to output.to_stdout

        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
          expect(log.logs).not_to include(/Error -- :/)
        end

        expect(Article::Page.all.count).to eq 1
        Article::Page.all.first.tap do |item|
          expect(item.site_id).to eq site.id
          expect(item.name).to eq page0.name
          expect(item.index_name).to eq page0.index_name
          expect(item.filename).not_to eq page0.filename
          expect(item.filename).to eq "#{node.filename}/#{basename}.html"
          expect(item.state).to eq "closed"
        end
      end
    end
  end
end
