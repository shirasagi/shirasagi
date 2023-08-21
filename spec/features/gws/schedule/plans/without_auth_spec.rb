require 'spec_helper'

describe "gws_schedule_plans", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:index_path) { gws_schedule_plans_path site }
end
