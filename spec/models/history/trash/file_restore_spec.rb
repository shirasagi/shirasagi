require 'spec_helper'

describe History::Trash, type: :model, dbscope: :example do
  let(:site) { cms_site }
  let(:user) { cms_user }
  let(:node) { create :article_node_page, cur_site: site }
  let(:file_path) { "#{Rails.root}/spec/fixtures/ss/logo.png" }
  let!(:file1) { tmp_ss_file(site: site, user: user, contents: file_path, basename: "logo1.png") }
  let!(:file2) { tmp_ss_file(site: site, user: user, contents: file_path, basename: "logo2.png") }
  let(:html) do
    [
      "<p>#{unique_id}</p>",
      "<p><a class=\"icon-png attachment\" href=\"#{file2.url}\">#{file2.humanized_name}</a></p>",
    ].join("\r\n\r\n")
  end
  let!(:item) do
    create(
      :article_page, cur_user: user, cur_site: site, cur_node: node,
      thumb_id: file1.id, html: html, file_ids: [ file2.id ]
    )
  end

  context "when file is given" do
    before do
      item.thumb_id = nil
      item.save!
      expect { file1.reload }.to raise_error Mongoid::Errors::DocumentNotFound

      trashes = History::Trash.all.to_a
      expect(trashes.length).to eq 1
      History::Trash.all.first.tap do |trash|
        expect(trash.site_id).to eq site.id
        expect(trash.version).to eq SS.version
        expect(trash.ref_coll).to eq file1.collection_name.to_s
        expect(trash.ref_class).to eq file1.class.name
        expect(trash.data).to be_present
        expect(trash.data["_id"]).to eq file1.id
        expect(trash.state).to be_blank
        expect(trash.action).to eq "save"
      end
      expect(File.exist?("#{described_class.root}/#{file1.path.sub(/.*\/(ss_files\/)/, '\\1')}")).to be_truthy
    end

    describe "#file_restore!" do
      it do
        trashes = History::Trash.all.to_a
        result = trashes.first.file_restore!(cur_group: user.groups.first, cur_user: user)
        expect(result).to be_persisted
        expect(result).to be_a(Cms::File)
        # result is newly created
        expect(result.id).not_to eq file1.id
        expect(result.state).to eq "closed"
        expect(result.name).to eq file1.name
        expect(result.filename).to eq file1.filename
        expect(result.size).to eq file1.size
        expect(result.content_type).to eq file1.content_type
        expect(result.owner_item).to be_nil
        expect(result.group_ids).to eq [ user.groups.first.id ]

        expect { file1.reload }.to raise_error Mongoid::Errors::DocumentNotFound
        expect(History::Trash.all.count).to eq 0
      end
    end
  end
end
