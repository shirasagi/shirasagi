require 'spec_helper'
require Rails.root.join("lib/migrations/cms/20260521000000_unify_multiple_files_upload.rb")

RSpec.describe SS::Migration20260521000000, dbscope: :example do
  let!(:site) { cms_site }
  let!(:node) { create :article_node_page, cur_site: site }
  let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'static') }

  let(:columns_collection) { Cms::Column::Base.collection }
  let(:pages_collection) { Cms::Page.collection }

  describe "#change" do
    context "with legacy MultipleImagesUpload column and value" do
      let!(:column_id) do
        id = BSON::ObjectId.new
        columns_collection.insert_one(
          _id: id,
          _type: "Cms::Column::MultipleImagesUpload",
          site_id: site.id,
          form_id: form.id,
          name: "image-col-#{unique_id}",
          order: 1,
          required: "optional"
        )
        id
      end

      let!(:page_id) do
        article_page = create(:article_page, cur_site: site, cur_node: node, form: form)
        cv_id = BSON::ObjectId.new
        pages_collection.update_one(
          { _id: article_page.id },
          {
            "$set" => {
              "column_values" => [
                {
                  "_id" => cv_id,
                  "_type" => "Cms::Column::Value::MultipleImagesUpload",
                  "column_id" => column_id,
                  "file_ids" => [ BSON::ObjectId.new.to_s ],
                  "file_labels" => { "abc" => "alt-text" },
                  "header" => "image header"
                }
              ]
            }
          }
        )
        article_page.id
      end

      before { described_class.new.change }

      it "rewrites column _type and sets file_type=image" do
        doc = columns_collection.find(_id: column_id).first
        expect(doc["_type"]).to eq "Cms::Column::MultipleFilesUpload"
        expect(doc["file_type"]).to eq "image"
      end

      it "rewrites embedded value _type" do
        doc = pages_collection.find(_id: page_id).first
        expect(doc["column_values"].first["_type"]).to eq "Cms::Column::Value::MultipleFilesUpload"
        expect(doc["column_values"].first["header"]).to eq "image header"
      end
    end

    context "with legacy MultipleAttachmentsUpload column and value" do
      let!(:column_id) do
        id = BSON::ObjectId.new
        columns_collection.insert_one(
          _id: id,
          _type: "Cms::Column::MultipleAttachmentsUpload",
          site_id: site.id,
          form_id: form.id,
          name: "attachment-col-#{unique_id}",
          order: 2,
          required: "optional"
        )
        id
      end

      let!(:page_id) do
        article_page = create(:article_page, cur_site: site, cur_node: node, form: form)
        cv_id = BSON::ObjectId.new
        pages_collection.update_one(
          { _id: article_page.id },
          {
            "$set" => {
              "column_values" => [
                {
                  "_id" => cv_id,
                  "_type" => "Cms::Column::Value::MultipleAttachmentsUpload",
                  "column_id" => column_id,
                  "file_ids" => [ BSON::ObjectId.new.to_s ],
                  "file_labels" => { "abc" => "link-text" },
                  "header" => "attachment header"
                }
              ]
            }
          }
        )
        article_page.id
      end

      before { described_class.new.change }

      it "rewrites column _type and sets file_type=attachment" do
        doc = columns_collection.find(_id: column_id).first
        expect(doc["_type"]).to eq "Cms::Column::MultipleFilesUpload"
        expect(doc["file_type"]).to eq "attachment"
      end

      it "rewrites embedded value _type" do
        doc = pages_collection.find(_id: page_id).first
        expect(doc["column_values"].first["_type"]).to eq "Cms::Column::Value::MultipleFilesUpload"
        expect(doc["column_values"].first["header"]).to eq "attachment header"
      end
    end

    context "with mixed legacy values and unrelated values in one page" do
      let!(:column_id) do
        id = BSON::ObjectId.new
        columns_collection.insert_one(
          _id: id,
          _type: "Cms::Column::MultipleImagesUpload",
          site_id: site.id,
          form_id: form.id,
          name: "mix-#{unique_id}",
          order: 3,
          required: "optional"
        )
        id
      end

      let!(:page_id) do
        article_page = create(:article_page, cur_site: site, cur_node: node, form: form)
        pages_collection.update_one(
          { _id: article_page.id },
          {
            "$set" => {
              "column_values" => [
                {
                  "_id" => BSON::ObjectId.new,
                  "_type" => "Cms::Column::Value::MultipleImagesUpload",
                  "column_id" => column_id
                },
                {
                  "_id" => BSON::ObjectId.new,
                  "_type" => "Cms::Column::Value::TextField",
                  "column_id" => column_id,
                  "value" => "keep me"
                }
              ]
            }
          }
        )
        article_page.id
      end

      before { described_class.new.change }

      it "only rewrites matching values and leaves others untouched" do
        doc = pages_collection.find(_id: page_id).first
        expect(doc["column_values"][0]["_type"]).to eq "Cms::Column::Value::MultipleFilesUpload"
        expect(doc["column_values"][1]["_type"]).to eq "Cms::Column::Value::TextField"
        expect(doc["column_values"][1]["value"]).to eq "keep me"
      end
    end
  end
end
