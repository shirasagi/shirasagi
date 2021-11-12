require 'spec_helper'

describe History::Trash, type: :model, dbscope: :example do
  let(:site) { cms_site }
  let(:user) { cms_user }
  let(:node) { create :article_node_page, cur_site: site }
  let(:file_path) { "#{Rails.root}/spec/fixtures/ss/logo.png" }

  describe "restore branch page from trash" do
    context "with basic page" do
      let!(:file1) { tmp_ss_file(site: site, user: user, contents: file_path, basename: "logo1.png") }
      let!(:file2) { tmp_ss_file(site: site, user: user, contents: file_path, basename: "logo2.png") }
      let!(:file3) { tmp_ss_file(site: site, user: user, contents: file_path, basename: "logo3.png") }
      let(:html) do
        <<~HTML.freeze
          <p>#{unique_id}</p>
          <p><a class="icon-png attachment" href="#{file1.url}">#{file1.humanized_name}</a></p>
          <p><a class="icon-png attachment" href="#{file2.url}">#{file2.humanized_name}</a></p>
        HTML
      end
      let!(:master) do
        create(
          :article_page, cur_site: site, cur_user: user, cur_node: node,
          thumb_id: file3.id, html: html, file_ids: [ file1.id, file2.id ]
        )
      end
      let(:branch) do
        copy = master.new_clone
        copy.master = master
        copy.save!
        copy.class.find(copy.id)
      end

      it do
        file1.reload
        expect(file1.owner_item_type).to eq master.class.name
        expect(file1.owner_item_id).to eq master.id
        file2.reload
        expect(file2.owner_item_type).to eq master.class.name
        expect(file2.owner_item_id).to eq master.id
        file3.reload
        expect(file3.owner_item_type).to eq master.class.name
        expect(file3.owner_item_id).to eq master.id

        expect(branch.master).to eq master
        expect(branch.master?).to be_falsey
        expect(branch.branch?).to be_truthy

        expect(branch.destroy).to be_truthy

        trashes = History::Trash.all.to_a
        expect(trashes.length).to eq 1
        trashes.first.tap do |trash|
          expect(trash.site_id).to eq site.id
          expect(trash.version).to eq SS.version
          expect(trash.ref_coll).to eq branch.collection_name.to_s
          expect(trash.ref_class).to eq branch.class.name
          expect(trash.data).to be_present
          expect(trash.data["_id"]).to eq branch.id
          expect(trash.state).to be_blank
          expect(trash.action).to eq "save"
        end

        result = trashes.first.restore!
        expect(result).to be_persisted
        expect(result).to eq branch

        expect { branch.reload }.not_to raise_error
        # 差し替えページをゴミ箱から復元すると、それは差し替えページではなくなり、通常のページとなる
        # このとき、ファイルは複製される
        expect(branch.master).to be_blank
        expect(branch.master?).to be_truthy
        expect(branch.branch?).to be_falsey
        expect(branch.thumb_id).not_to eq file3.id
        expect(branch.thumb.owner_item_type).to eq branch.class.name
        expect(branch.thumb.owner_item_id).to eq branch.id
        expect(branch.file_ids & [ file1.id, file2.id ]).to be_blank
        SS::File.each_file(branch.file_ids) do |branch_file|
          expect(branch_file.owner_item_type).to eq branch.class.name
          expect(branch_file.owner_item_id).to eq branch.id

          expect(branch.html).to include branch_file.url
        end
        expect(branch.html).not_to include file1.url
        expect(branch.html).not_to include file2.url

        # master のファイルの所有は master のまま変更なし
        file1.reload
        expect(file1.owner_item_type).to eq master.class.name
        expect(file1.owner_item_id).to eq master.id
        file2.reload
        expect(file2.owner_item_type).to eq master.class.name
        expect(file2.owner_item_id).to eq master.id
        file3.reload
        expect(file3.owner_item_type).to eq master.class.name
        expect(file3.owner_item_id).to eq master.id
      end
    end

    context "with form" do
      let!(:file1) { tmp_ss_file(site: site, user: user, contents: file_path, basename: "logo1.png") }
      let!(:file2) { tmp_ss_file(site: site, user: user, contents: file_path, basename: "logo2.png") }
      let!(:file3) { tmp_ss_file(site: site, user: user, contents: file_path, basename: "logo3.png") }
      let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'static') }
      let!(:column1) do
        create(:cms_column_file_upload, cur_site: site, cur_form: form, order: 1, file_type: "image")
      end
      let!(:column2) do
        create(:cms_column_free, cur_site: site, cur_form: form, order: 2)
      end
      let(:html) do
        <<~HTML.freeze
          <p>#{unique_id}</p>
          <p><a class="icon-png attachment" href="#{file2.url}">#{file2.humanized_name}</a></p>
          <p><a class="icon-png attachment" href="#{file3.url}">#{file3.humanized_name}</a></p>
        HTML
      end
      let!(:master) do
        node.st_form_ids = [ form.id ]
        node.save!

        item = build(:article_page, cur_site: site, cur_user: user, cur_node: node, form: form)
        item.column_values = [
          column1.value_type.new(column: column1, file_id: file1.id, file_label: file1.humanized_name),
          column2.value_type.new(column: column2, value: html, file_ids: [ file2.id, file3.id ])
        ]
        item.save!

        item
      end
      let(:branch) do
        copy = master.new_clone
        copy.master = master
        copy.save!
        copy
      end

      it do
        file1.reload
        expect(file1.owner_item_type).to eq master.class.name
        expect(file1.owner_item_id).to eq master.id
        file2.reload
        expect(file2.owner_item_type).to eq master.class.name
        expect(file2.owner_item_id).to eq master.id
        file3.reload
        expect(file3.owner_item_type).to eq master.class.name
        expect(file3.owner_item_id).to eq master.id

        expect(branch.master).to eq master
        expect(branch.master?).to be_falsey
        expect(branch.branch?).to be_truthy

        expect(branch.destroy).to be_truthy

        trashes = History::Trash.all.to_a
        expect(trashes.length).to eq 1
        trashes.first.tap do |trash|
          expect(trash.site_id).to eq site.id
          expect(trash.version).to eq SS.version
          expect(trash.ref_coll).to eq branch.collection_name.to_s
          expect(trash.ref_class).to eq branch.class.name
          expect(trash.data).to be_present
          expect(trash.data["_id"]).to eq branch.id
          expect(trash.state).to be_blank
          expect(trash.action).to eq "save"
        end

        result = trashes.first.restore!
        expect(result).to be_persisted
        expect(result).to eq branch

        expect { branch.reload }.not_to raise_error
        # 差し替えページをゴミ箱から復元すると、それは差し替えページではなくなり、通常のページとなる
        # このとき、ファイルは複製される
        expect(branch.master).to be_blank
        expect(branch.master?).to be_truthy
        expect(branch.branch?).to be_falsey
        expect(branch.column_values.length).to eq 2
        branch.column_values[0].tap do |branch_column_value1|
          expect(branch_column_value1.class).to be column1.value_type
          expect(branch_column_value1.file_id).not_to eq file1.id
          expect(branch_column_value1.file.owner_item_type).to eq branch.class.name
          expect(branch_column_value1.file.owner_item_id).to eq branch.id
        end
        branch.column_values[1].tap do |branch_column_value2|
          expect(branch_column_value2.class).to be column2.value_type
          expect(branch_column_value2.file_ids & [ file2.id, file3.id ]).to be_blank
          SS::File.each_file(branch_column_value2.file_ids) do |brach_column_file|
            expect(brach_column_file.owner_item_type).to eq branch.class.name
            expect(brach_column_file.owner_item_id).to eq branch.id

            expect(branch_column_value2.value).to include brach_column_file.url
          end
          expect(branch_column_value2.value).not_to include file2.url
          expect(branch_column_value2.value).not_to include file3.url
        end

        # master のファイルの所有は master のまま変更なし
        file1.reload
        expect(file1.owner_item_type).to eq master.class.name
        expect(file1.owner_item_id).to eq master.id
        file2.reload
        expect(file2.owner_item_type).to eq master.class.name
        expect(file2.owner_item_id).to eq master.id
        file3.reload
        expect(file3.owner_item_type).to eq master.class.name
        expect(file3.owner_item_id).to eq master.id
      end
    end
  end

  describe "restore branch page after master was destroyed" do
    context "with basic page" do
      let!(:file1) { tmp_ss_file(site: site, user: user, contents: file_path, basename: "logo1.png") }
      let!(:file2) { tmp_ss_file(site: site, user: user, contents: file_path, basename: "logo2.png") }
      let!(:file3) { tmp_ss_file(site: site, user: user, contents: file_path, basename: "logo3.png") }
      let(:html) do
        <<~HTML.freeze
          <p>#{unique_id}</p>
          <p><a class="icon-png attachment" href="#{file1.url}">#{file1.humanized_name}</a></p>
          <p><a class="icon-png attachment" href="#{file2.url}">#{file2.humanized_name}</a></p>
        HTML
      end
      let!(:master) do
        create(
          :article_page, cur_site: site, cur_user: user, cur_node: node,
          thumb_id: file3.id, html: html, file_ids: [ file1.id, file2.id ]
        )
      end
      let(:branch) do
        copy = master.new_clone
        copy.master = master
        copy.save!
        copy
      end

      it do
        branch.class.find(branch.id).tap { |clean_page| clean_page.destroy }
        expect(History::Trash.all.count).to eq 1

        master.class.find(master.id).tap { |clean_page| clean_page.destroy }
        expect(History::Trash.all.count).to eq 5

        trashes = History::Trash.all.to_a
        branch_trash = trashes.find { |trash| trash.ref_coll == branch.collection_name.to_s && trash.data["_id"] == branch.id }

        result = branch_trash.restore!
        expect(result).to be_persisted
        expect(result).to eq branch

        expect { branch.reload }.not_to raise_error
        # 差し替えページをゴミ箱から復元すると、それは差し替えページではなくなり、通常のページとなる
        # このとき、ファイルは複製される
        expect(branch.master).to be_blank
        expect(branch.master?).to be_truthy
        expect(branch.branch?).to be_falsey
        expect(branch.thumb_id).not_to eq file3
        expect(branch.thumb.owner_item_type).to eq branch.class.name
        expect(branch.thumb.owner_item_id).to eq branch.id
        expect(branch.file_ids).to have(2).items
        expect(branch.file_ids).to include(file1.id, file2.id)
        SS::File.each_file(branch.file_ids) do |branch_file|
          expect(branch_file.owner_item_type).to eq branch.class.name
          expect(branch_file.owner_item_id).to eq branch.id

          expect(branch.html).to include branch_file.url
        end

        expect(History::Trash.all.count).to eq 1
      end
    end
  end
end
