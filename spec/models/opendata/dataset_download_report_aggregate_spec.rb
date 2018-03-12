require 'spec_helper'

describe Opendata::DatasetDownloadReport::Aggregate, dbscope: :example do

  def upload_file(file, content_type = nil)
    uploaded_file = Fs::UploadedFile.create_from_file(file, basename: "spec")
    uploaded_file.content_type = content_type || "application/octet-stream"
    uploaded_file
  end

  describe Opendata::DatasetDownloadReport::Aggregate::Base do
    let!(:site) { cms_site }
    let!(:user) { cms_user }
    let!(:node_search) { create(:opendata_node_search_dataset) }
    let(:today) { Time.zone.local('2018-1-1 10:00') }

    describe "#datasets" do
      subject do
        report = Opendata::DatasetDownloadReport.new(
          cur_site: site,
          cur_node: node,
          cur_user: user
        )
        described_class.new(report).datasets.to_a
      end
      let!(:node) { create(:opendata_node_dataset) }
      let!(:datasets) do
        [
          create_once(:opendata_dataset,
            filename: "#{node.filename}/#{unique_id}.html",
            site: site),
          create_once(:opendata_dataset,
            filename: "#{node.filename}/#{unique_id}.html",
            site: site)
        ]
      end

      let(:other_site_dataset) do
        # site
        site_params = {
          name: 'other_site',
          host: 'other_site',
          domains: 'other_site.localhost.jp'
        }
        other_site = create_once(:cms_site, site_params)
        # node
        other_node = create(:opendata_node_dataset, cur_site: other_site)
        other_node_search = create(:opendata_node_search_dataset, cur_site: other_site)
        # dataset
        dataset_params = {
          filename: "#{other_node.filename}/#{unique_id}.html",
          site: other_site
        }
        create_once(:opendata_dataset, dataset_params)
      end

      let!(:other_node_dataset) do
        # node
        other_node = create(:opendata_node_dataset, cur_site: site)
        # dataset
        dataset_params = {
          filename: "#{other_node.filename}/#{unique_id}.html",
          site: site
        }
        create_once(:opendata_dataset, dataset_params)
      end

      it do
        is_expected.to eq datasets
      end
    end
  end

  describe "#csv" do
    let!(:site) { cms_site }
    let!(:user) { cms_user }
    let!(:node_search) { create(:opendata_node_search_dataset) }
    let(:today) { Time.zone.local('2018-1-1 10:00') }

    # node
    let!(:node) do
      create(:opendata_node_dataset, name: 'dataset', filename: 'dataset')
    end

    # dataset
    let!(:dataset1) do
      create_once(:opendata_dataset,
        name: "dataset1",
        filename: "#{node.filename}/1.html",
        site: site)
    end
    let!(:dataset2) do
      create_once(:opendata_dataset,
        name: "dataset2",
        filename: "#{node.filename}/2.html",
        site: site)
    end

    # resources
    let!(:dataset1_resource_a) do
      file = Rails.root.join("spec", "fixtures", "opendata", "dataset_download_report", "resourceA.txt")
      resource = dataset1.resources.new(attributes_for(:opendata_resource))
      resource.in_file = upload_file(file, "text/plain")
      resource.license_id = license.id
      resource.save!
      resource.in_file.close
      resource
    end
    let!(:dataset1_resource_b) do
      file = Rails.root.join("spec", "fixtures", "opendata", "dataset_download_report", "resourceB.txt")
      resource = dataset1.resources.new(attributes_for(:opendata_resource))
      resource.in_file = upload_file(file, "text/plain")
      resource.license_id = license.id
      resource.save!
      resource.in_file.close
      resource
    end
    let!(:dataset2_resource_c) do
      file = Rails.root.join("spec", "fixtures", "opendata", "dataset_download_report", "resourceC.txt")
      resource = dataset2.resources.new(attributes_for(:opendata_resource))
      resource.in_file = upload_file(file, "text/plain")
      resource.license_id = license.id
      resource.save!
      resource.in_file.close
      resource
    end

    let(:license_logo_file) { upload_file(Rails.root.join("spec", "fixtures", "ss", "logo.png")) }
    let(:license) { create(:opendata_license, cur_site: site, in_file: license_logo_file) }

    describe Opendata::DatasetDownloadReport::Aggregate::Year do
      subject do
        report = Opendata::DatasetDownloadReport.new(
          cur_site: site,
          cur_node: node,
          cur_user: user,
          start_year: 2016,
          start_month: 1,
          end_year: 2018,
          end_month: 11
        )
        described_class.new(report).csv
      end

      let!(:download_histories) do
        resource_a_history_params = {
          dataset_id: dataset1.id,
          resource_id: dataset1_resource_a.id
        }
        resource_b_history_params = {
          dataset_id: dataset1.id,
          resource_id: dataset1_resource_b.id
        }
        create(:resource_download_history,
          resource_a_history_params.merge(downloaded: Time.zone.local(2015, 12, 31, 23, 59, 59)))
        create(:resource_download_history,
          resource_a_history_params.merge(downloaded: Time.zone.local(2016, 1, 1)))
        create(:resource_download_history,
          resource_b_history_params.merge(downloaded: Time.zone.local(2017, 1, 1)))
        create(:resource_download_history,
          resource_b_history_params.merge(downloaded: Time.zone.local(2017, 12, 31, 23, 59, 59)))
        create(:resource_download_history,
          resource_a_history_params.merge(downloaded: Time.zone.local(2018, 11, 30, 23, 59, 59)))
        create(:resource_download_history,
          resource_a_history_params.merge(downloaded: Time.zone.local(2018, 12, 1)))
      end

      it do
        file_path = "#{Rails.root}/spec/fixtures/opendata/dataset_download_report/year.csv"
        expected_csv = File.read(file_path)
        is_expected.to eq expected_csv
      end
    end

    describe Opendata::DatasetDownloadReport::Aggregate::Month do
      subject do
        report = Opendata::DatasetDownloadReport.new(
          cur_site: site,
          cur_node: node,
          cur_user: user,
          start_year: 2017,
          start_month: 12,
          end_year: 2018,
          end_month: 2
        )
        described_class.new(report).csv
      end

      let!(:download_histories) do
        resource_a_history_params = {
          dataset_id: dataset1.id,
          resource_id: dataset1_resource_a.id
        }
        resource_b_history_params = {
          dataset_id: dataset1.id,
          resource_id: dataset1_resource_b.id
        }
        create(:resource_download_history,
          resource_a_history_params.merge(downloaded: Time.zone.local(2017, 11, 30, 23, 59, 59)))
        create(:resource_download_history,
          resource_a_history_params.merge(downloaded: Time.zone.local(2017, 12, 1)))
        create(:resource_download_history,
          resource_b_history_params.merge(downloaded: Time.zone.local(2017, 12, 31, 23, 59, 59)))
        create(:resource_download_history,
          resource_b_history_params.merge(downloaded: Time.zone.local(2018, 1, 1)))
        create(:resource_download_history,
          resource_b_history_params.merge(downloaded: Time.zone.local(2018, 1, 31, 23, 59, 59)))
        create(:resource_download_history,
          resource_a_history_params.merge(downloaded: Time.zone.local(2018, 2, 28, 23, 59, 59)))
        create(:resource_download_history,
          resource_a_history_params.merge(downloaded: Time.zone.local(2018, 3, 1)))
      end

      it do
        file_path = "#{Rails.root}/spec/fixtures/opendata/dataset_download_report/month.csv"
        expected_csv = File.read(file_path)
        is_expected.to eq expected_csv
      end
    end

    describe Opendata::DatasetDownloadReport::Aggregate::Day do
      subject do
        report = Opendata::DatasetDownloadReport.new(
          cur_site: site,
          cur_node: node,
          cur_user: user,
          start_year: 2017,
          start_month: 12,
          end_year: 2018,
          end_month: 2
        )
        described_class.new(report).csv
      end

      let!(:download_histories) do
        resource_a_history_params = {
          dataset_id: dataset1.id,
          resource_id: dataset1_resource_a.id
        }
        resource_b_history_params = {
          dataset_id: dataset1.id,
          resource_id: dataset1_resource_b.id
        }
        create(:resource_download_history,
          resource_a_history_params.merge(downloaded: Time.zone.local(2017, 11, 30, 23, 59, 59)))
        create(:resource_download_history,
          resource_a_history_params.merge(downloaded: Time.zone.local(2017, 12, 1)))
        create(:resource_download_history,
          resource_a_history_params.merge(downloaded: Time.zone.local(2018, 1, 1)))
        create(:resource_download_history,
          resource_b_history_params.merge(downloaded: Time.zone.local(2018, 1, 1)))
        create(:resource_download_history,
          resource_b_history_params.merge(downloaded: Time.zone.local(2018, 1, 1)))
        create(:resource_download_history,
          resource_b_history_params.merge(downloaded: Time.zone.local(2018, 1, 31, 23, 59, 59)))
        create(:resource_download_history,
          resource_a_history_params.merge(downloaded: Time.zone.local(2018, 2, 28, 23, 59, 59)))
        create(:resource_download_history,
          resource_a_history_params.merge(downloaded: Time.zone.local(2018, 3, 1)))
      end

      it do
        file_path = "#{Rails.root}/spec/fixtures/opendata/dataset_download_report/day.csv"
        expected_csv = File.read(file_path)
        is_expected.to eq expected_csv
      end
    end
  end
end
