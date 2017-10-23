require 'spec_helper'

describe "gws_workflow_files", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:index_path) { gws_workflow_files_path(site, state: 'all') }
end
