require 'spec_helper'
require 'rake'

describe Cms::ContentExportJob, dbscope: :example do
  let(:site) { cms_site }
  let(:job) { Cms::ContentExportJob.new }
  let(:zip) { job.instance_variable_get(:@output_zip) }

  before do
    task = OpenStruct.new(site_id: site.id)
    def task.log(msg)
      puts(msg)
    end
    job.task = task
    job.perform
  end

  context 'site export' do
    it { expect(File.exist?(zip)).to be_truthy }
  end

  after do
    FileUtils.rm(zip)
  end
end
