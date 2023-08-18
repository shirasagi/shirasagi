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

  context "when page is given" do
    let(:basename) { "name-#{unique_id}.html" }

    before do
      expect(item.destroy).to be_truthy
      expect { item.reload }.to raise_error Mongoid::Errors::DocumentNotFound
      expect { file1.reload }.to raise_error Mongoid::Errors::DocumentNotFound
      expect { file2.reload }.to raise_error Mongoid::Errors::DocumentNotFound

      trashes = History::Trash.all.to_a
      expect(trashes.length).to eq 3
      History::Trash.all.first.tap do |trash|
        expect(trash.site_id).to eq site.id
        expect(trash.version).to eq SS.version
        expect(trash.ref_coll).to eq item.collection_name.to_s
        expect(trash.ref_class).to eq item.class.name
        expect(trash.data).to be_present
        expect(trash.data["_id"]).to eq item.id
        expect(trash.state).to be_blank
        expect(trash.action).to eq "save"
      end
      expect(File.exist?("#{described_class.root}/#{file1.path.sub(/.*\/(ss_files\/)/, '\\1')}")).to be_truthy
      expect(File.exist?("#{described_class.root}/#{file2.path.sub(/.*\/(ss_files\/)/, '\\1')}")).to be_truthy
    end

    describe "#restore" do
      it do
        trashes = History::Trash.all.to_a
        result = trashes.first.restore(basename: basename)
        expect(result).to be_new_record
        expect(result.filename).to be_nil

        expect { file1.reload }.to raise_error Mongoid::Errors::DocumentNotFound
        expect { file2.reload }.to raise_error Mongoid::Errors::DocumentNotFound
        expect(History::Trash.all.count).to eq 3
      end
    end

    describe "#restore!" do
      it do
        trashes = History::Trash.all.to_a
        result = trashes.first.restore!(basename: basename)
        expect(result).to be_persisted
        expect(result.filename).to eq "#{node.filename}/#{basename}"

        expect { file1.reload }.not_to raise_error
        expect { file2.reload }.not_to raise_error
        expect(History::Trash.all.count).to eq 0
      end
    end
  end

  context "when node is given" do
    let(:basename) { "name-#{unique_id}" }

    before do
      expect(node.destroy).to be_truthy
      expect { node.reload }.to raise_error Mongoid::Errors::DocumentNotFound
      expect { item.reload }.to raise_error Mongoid::Errors::DocumentNotFound
      expect { file1.reload }.to raise_error Mongoid::Errors::DocumentNotFound
      expect { file2.reload }.to raise_error Mongoid::Errors::DocumentNotFound

      trashes = History::Trash.all.to_a
      expect(trashes.length).to eq 4
      History::Trash.all.to_a.tap do |trashes|
        trashes[0].tap do |trash|
          expect(trash.site_id).to eq site.id
          expect(trash.version).to eq SS.version
          expect(trash.ref_coll).to eq node.collection_name.to_s
          expect(trash.ref_class).to eq node.class.name
          expect(trash.data).to be_present
          expect(trash.data["_id"]).to eq node.id
          expect(trash.data["site_id"]).to eq site.id
          expect(trash.data["filename"]).to eq node.filename
          expect(trash.state).to be_blank
          expect(trash.action).to eq "save"
        end
        trashes[1].tap do |trash|
          expect(trash.site_id).to eq site.id
          expect(trash.version).to eq SS.version
          expect(trash.ref_coll).to eq item.collection_name.to_s
          expect(trash.ref_class).to eq item.class.name
          expect(trash.data).to be_present
          expect(trash.data["_id"]).to eq item.id
          expect(trash.data["site_id"]).to eq site.id
          expect(trash.data["filename"]).to eq item.filename
          expect(trash.state).to be_blank
          expect(trash.action).to eq "save"
        end
        trashes[2].tap do |trash|
          expect(trash.site_id).to eq site.id
          expect(trash.version).to eq SS.version
          expect(trash.ref_coll).to eq file1.collection_name.to_s
          expect(trash.ref_class).to eq file1.class.name
          expect(trash.data).to be_present
          expect(trash.data["_id"]).to eq file1.id
          expect(trash.data["site_id"]).to eq site.id
          expect(trash.data["filename"]).to eq file1.filename
          expect(trash.state).to be_blank
          expect(trash.action).to eq "save"
        end
        trashes[3].tap do |trash|
          expect(trash.site_id).to eq site.id
          expect(trash.version).to eq SS.version
          expect(trash.ref_coll).to eq file2.collection_name.to_s
          expect(trash.ref_class).to eq file2.class.name
          expect(trash.data).to be_present
          expect(trash.data["_id"]).to eq file2.id
          expect(trash.data["site_id"]).to eq site.id
          expect(trash.data["filename"]).to eq file2.filename
          expect(trash.state).to be_blank
          expect(trash.action).to eq "save"
        end
      end
      expect(File.size(file1.path.sub("#{file1.class.root}/", "#{described_class.root}/"))).to be > 0
      expect(File.size(file2.path.sub("#{file2.class.root}/", "#{described_class.root}/"))).to be > 0
    end

    context "when children: 'restore' is given" do
      describe "#restore" do
        it do
          trashes = History::Trash.all.to_a
          node_trash = trashes.find { |trash| trash.ref_class == node.class.name }
          result = node_trash.restore(basename: basename, children: "restore")
          expect(result).to be_new_record
          expect(result.filename).to be_nil

          expect { node.reload }.to raise_error Mongoid::Errors::DocumentNotFound
          expect { item.reload }.to raise_error Mongoid::Errors::DocumentNotFound
          expect { file1.reload }.to raise_error Mongoid::Errors::DocumentNotFound
          expect { file2.reload }.to raise_error Mongoid::Errors::DocumentNotFound
          expect(History::Trash.all.count).to eq 4
        end
      end

      describe "#restore!" do
        it do
          trashes = History::Trash.all.to_a
          node_trash = trashes.find { |trash| trash.ref_class == node.class.name }
          # https://github.com/shirasagi/shirasagi/issues/4217 に示す問題があるので、
          # 名前を変更して配下のコンテンツを「復元にする」でフォルダーをゴミ箱から復元できない
          # result = trashes.first.restore!(basename: basename, children: "restore")
          # trashes.first.children.restore!(basename: basename, children: "restore")
          result = node_trash.restore!(children: "restore")
          node_trash.children.restore!(children: "restore")
          expect(result).to be_persisted
          # expect(result.filename).to eq basename

          expect { node.reload }.not_to raise_error
          expect { item.reload }.not_to raise_error
          expect { file1.reload }.not_to raise_error
          expect { file2.reload }.not_to raise_error
          expect(History::Trash.all.count).to eq 0
        end
      end
    end

    context "when children: 'unrestore' is given" do
      describe "#restore" do
        it do
          trashes = History::Trash.all.to_a
          result = trashes.first.restore(basename: basename, children: "unrestore")
          expect(result).to be_new_record
          expect(result.filename).to be_nil

          expect { node.reload }.to raise_error Mongoid::Errors::DocumentNotFound
          expect { item.reload }.to raise_error Mongoid::Errors::DocumentNotFound
          expect { file1.reload }.to raise_error Mongoid::Errors::DocumentNotFound
          expect { file2.reload }.to raise_error Mongoid::Errors::DocumentNotFound
          expect(History::Trash.all.count).to eq 4
        end
      end

      describe "#restore!" do
        it do
          trashes = History::Trash.all.to_a
          result = trashes.first.restore!(basename: basename, children: "unrestore")
          expect(result).to be_persisted
          expect(result.filename).to eq basename

          expect { node.reload }.not_to raise_error
          expect { item.reload }.to raise_error Mongoid::Errors::DocumentNotFound
          expect { file1.reload }.to raise_error Mongoid::Errors::DocumentNotFound
          expect { file2.reload }.to raise_error Mongoid::Errors::DocumentNotFound
          expect(History::Trash.all.count).to eq 3
        end
      end
    end
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

    describe "#restore" do
      it do
        trashes = History::Trash.all.to_a
        result = trashes.first.restore(file_restore: true)
        # expect(result).to be_new_record
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
        expect(result.group_ids).to be_blank

        expect { file1.reload }.to raise_error Mongoid::Errors::DocumentNotFound
        expect(History::Trash.all.count).to eq 0
      end
    end

    describe "#restore!" do
      it do
        trashes = History::Trash.all.to_a
        expect do
          trashes.first.restore!(file_restore: true, cur_group: user.groups.first, cur_user: user)
        end.to raise_error Errno::ENOENT
      end
    end
  end
end
