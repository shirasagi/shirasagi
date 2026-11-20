require 'spec_helper'

describe Article::Page::ExportJob, dbscope: :example do
  let(:now) { Time.zone.now.change(usec: 0) }
  let(:today) { Time.zone.today }
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:form) { create :cms_form, cur_site: site, state: 'public', sub_type: 'static' }
  let!(:node) { create :article_node_page, cur_site: site, st_form_ids: [ form.id ] }
  let!(:task) do
    task = Cms::FileGenTask.new(cur_site: site, cur_user: user)
    task.name = "article_pages_download_#{user.id}"
    task.file_basename = "article_pages"
    task.file_format = "csv"
    task.params = { "encoding" => "UTF-8", "form_id" => form.id.to_s, "truncate" => "yes" }
    task.save!
    task
  end

  describe "#perform" do
    context "order" do
      let!(:column1) do
        create(:cms_column_text_field, cur_site: site, cur_form: form, required: "optional", input_type: 'text')
      end
      let(:column1_alignment1) { %w(flow left center right).sample }
      let(:column1_value1) { unique_id }
      let(:column1_alignment2) { %w(flow left center right).sample }
      let(:column1_value2) { unique_id }
      let!(:page1) do
        Timecop.freeze(now - 5.hours) do
          create(
            :article_page, cur_site: site, cur_node: node, form: form,
            column_values: [
              column1.value_type.new(
                column: column1, name: column1.name, alignment: column1_alignment1, value: column1_value1)
            ]
          )
        end
      end
      let!(:page2) do
        Timecop.freeze(now - 4.hours) do
          create(
            :article_page, cur_site: site, cur_node: node, form: form,
            column_values: [
              column1.value_type.new(
                column: column1, name: column1.name, alignment: column1_alignment2, value: column1_value2)
            ]
          )
        end
      end

      it do
        job = described_class.bind(site_id: site, user_id: user, node_id: node, task_id: task)
        expect { ss_perform_now(job) }.to output.to_stdout

        expect(Job::Log.count).to eq 1
        Job::Log.all.each do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        task.reload
        expect(task.job_id).to be_present
        expect(File.size(task.generated_file_path)).to be > 0

        SS::Csv.open(task.generated_file_path) do |csv|
          csv_table = csv.read
          expect(csv_table.length).to eq 2
          # 本文は出力されない
          expect(csv_table.headers).not_to include(Article::Page.t(:html))

          # updated_desc order
          csv_table[0].tap do |csv_row|
            expect(csv_row[Article::Page.t(:filename)]).to eq page2.basename
            expect(csv_row[Article::Page.t(:name)]).to eq page2.name
            [ form.name, column1.name, column1.value_type.t(:alignment) ].join("/").tap do |header|
              expect(csv_row[header]).to eq I18n.t(column1_alignment2, scope: "cms.options.alignment")
            end
            [ form.name, column1.name, column1.value_type.t(:value) ].join("/").tap do |header|
              expect(csv_row[header]).to eq column1_value2
            end
          end
          csv_table[1].tap do |csv_row|
            expect(csv_row[Article::Page.t(:filename)]).to eq page1.basename
            expect(csv_row[Article::Page.t(:name)]).to eq page1.name
            [ form.name, column1.name, column1.value_type.t(:alignment) ].join("/").tap do |header|
              expect(csv_row[header]).to eq I18n.t(column1_alignment1, scope: "cms.options.alignment")
            end
            [ form.name, column1.name, column1.value_type.t(:value) ].join("/").tap do |header|
              expect(csv_row[header]).to eq column1_value1
            end
          end
        end
      end
    end
  end
end
