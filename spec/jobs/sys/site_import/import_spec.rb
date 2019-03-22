require 'spec_helper'

describe Sys::SiteImportJob, dbscope: :example, tmpdir: true do
  let(:destination_site) { create :cms_site_unique }

  def execute(site, file_path)
    task = OpenStruct.new(
      target_site_id: site.id,
      import_file: file_path
    )
    def task.log(msg)
      puts(msg)
    end

    job = ::Sys::SiteImportJob.new
    job.task = task
    job.perform
  end

  before do
    execute(destination_site, file_path)
  end

  context 'with pages' do
    let(:file_path) { "#{Rails.root}/spec/fixtures/sys/site-exports-1.zip" }

    it do
      expect(Cms::Group.unscoped).to be_present
      expect(Cms::User.unscoped).to be_present

      expect(Cms::Form.unscoped.site(destination_site)).to have(2).items
      Cms::Form.unscoped.site(destination_site).pluck(:id).sort.tap do |ids|
        Cms::Form.find(ids[0]).tap do |form|
          expect(form.state).to eq "public"
          expect(form.sub_type).to eq "static"
          expect(form.columns).to have(3).items

          form.columns.pluck(:id).map(&:to_s).sort.tap do |ids|
            Cms::Column::Base.find(ids[0]).tap do |column|
              expect(column).to be_a(Cms::Column::TextField)
              expect(column.order).to eq 10
            end
            Cms::Column::Base.find(ids[1]).tap do |column|
              expect(column).to be_a(Cms::Column::FileUpload)
              expect(column.order).to eq 20
            end
            Cms::Column::Base.find(ids[2]).tap do |column|
              expect(column).to be_a(Cms::Column::Free)
              expect(column.order).to eq 30
            end
          end
        end
        Cms::Form.find(ids[1]).tap do |form|
          expect(form.state).to eq "public"
          expect(form.sub_type).to eq "entry"
          expect(form.columns).to have(3).items

          form.columns.pluck(:id).map(&:to_s).sort.tap do |ids|
            Cms::Column::Base.find(ids[0]).tap do |column|
              expect(column).to be_a(Cms::Column::TextField)
              expect(column.order).to eq 10
            end
            Cms::Column::Base.find(ids[1]).tap do |column|
              expect(column).to be_a(Cms::Column::FileUpload)
              expect(column.order).to eq 20
            end
            Cms::Column::Base.find(ids[2]).tap do |column|
              expect(column).to be_a(Cms::Column::Free)
              expect(column.order).to eq 30
            end
          end
        end
      end

      expect(Cms::Column::Base.unscoped.site(destination_site)).to have(6).items
      expect(Cms::Page.unscoped.site(destination_site)).to have(3).items
      expect(Article::Page.unscoped.site(destination_site)).to have(3).items
      Article::Page.unscoped.site(destination_site).pluck(:id).sort.tap do |ids|
        Article::Page.find(ids[0]).tap do |page|
          expect(page.form).to be_blank
          expect(page.html).to be_present
          expect(page.files).to have(1).items
        end

        Article::Page.find(ids[1]).tap do |page|
          expect(page.html).to be_blank
          expect(page.form).to be_present
          expect(page.form.sub_type).to eq "static"
          expect(page.column_values).to have(3).items
          page.column_values.reorder(order: 1).to_a.tap do |column_values|
            column_values[0].tap do |column_value|
              expect(column_value).to be_a(Cms::Column::Value::TextField)
              expect(column_value.column).to be_present
              expect(page.form.columns.find(column_value.column_id)).to be_present
              expect(column_value.value).to be_present
            end

            column_values[1].tap do |column_value|
              expect(column_value).to be_a(Cms::Column::Value::FileUpload)
              expect(column_value.column).to be_present
              expect(page.form.columns.find(column_value.column_id)).to be_present
              expect(column_value.file).to be_present
            end

            column_values[2].tap do |column_value|
              expect(column_value).to be_a(Cms::Column::Value::Free)
              expect(column_value.column).to be_present
              expect(page.form.columns.find(column_value.column_id)).to be_present
              expect(column_value.value).to be_present
              expect(column_value.files).to have(1).items
            end
          end
        end

        Article::Page.find(ids[2]).tap do |page|
          expect(page.form).to be_present
          expect(page.html).to be_blank
          expect(page.form.sub_type).to eq "entry"
          expect(page.column_values).to have(6).items

          page.column_values.reorder(order: 1).to_a.tap do |column_values|
            column_values[0].tap do |column_value|
              expect(column_value).to be_a(Cms::Column::Value::TextField)
              expect(column_value.column).to be_present
              expect(page.form.columns.find(column_value.column_id)).to be_present
              expect(column_value.value).to be_present
            end

            column_values[1].tap do |column_value|
              expect(column_value).to be_a(Cms::Column::Value::TextField)
              expect(column_value.column).to be_present
              expect(page.form.columns.find(column_value.column_id)).to be_present
              expect(column_value.value).to be_present
            end

            column_values[2].tap do |column_value|
              expect(column_value).to be_a(Cms::Column::Value::FileUpload)
              expect(column_value.column).to be_present
              expect(page.form.columns.find(column_value.column_id)).to be_present
              expect(column_value.value).to be_present
              expect(column_value.file).to be_present
            end

            column_values[3].tap do |column_value|
              expect(column_value).to be_a(Cms::Column::Value::FileUpload)
              expect(column_value.column).to be_present
              expect(page.form.columns.find(column_value.column_id)).to be_present
              expect(column_value.value).to be_present
              expect(column_value.file).to be_present
            end

            column_values[4].tap do |column_value|
              expect(column_value).to be_a(Cms::Column::Value::Free)
              expect(column_value.column).to be_present
              expect(page.form.columns.find(column_value.column_id)).to be_present
              expect(column_value.value).to be_present
              expect(column_value.files).to have(1).items
            end

            column_values[5].tap do |column_value|
              expect(column_value).to be_a(Cms::Column::Value::Free)
              expect(column_value.column).to be_present
              expect(page.form.columns.find(column_value.column_id)).to be_present
              expect(column_value.value).to be_present
              expect(column_value.files).to have(1).items
            end
          end
        end
      end
    end
  end
end
