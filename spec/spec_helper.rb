# Don't run always Coverage analysis
# ref. http://docs.travis-ci.com/user/environment-variables/#Default-Environment-Variables
require 'dotenv'
Dotenv.load
def analyze_coverage?
  (ENV["CI"] == "true" && ENV["TRAVIS"] == "true") || ENV["ANALYZE_COVERAGE"] != "disabled"
end
if analyze_coverage?
  require 'simplecov'
  require 'coveralls'
  Coveralls.wear!
end

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require File.expand_path(__FILE__, "../../app/helpers")
require 'rspec/rails'
#require 'rspec/autorun'
require 'capybara/rspec'
require 'capybara/rails'

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.check_pending! if defined?(ActiveRecord::Migration)

if analyze_coverage?
  SimpleCov.formatters = [
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
  ]
  SimpleCov.start do
    add_filter 'spec/'
    add_filter 'vendor/bundle'
  end
end

if Module.const_defined?(:WebMock)
  require "webmock/rspec"
  WebMock.allow_net_connect!
end

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
#  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
#  config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  #config.order = "random"
  config.order = "order"

  config.include Rails.application.routes.url_helpers
  config.include Capybara::DSL
  config.include ActiveJob::TestHelper
  config.include ActiveSupport::Testing::TimeHelpers

  config.include FactoryGirl::Syntax::Methods
  config.before(:all) do
    FactoryGirl.reload
    Capybara.app_host = nil
  end

  if system("which phantomjs > /dev/null 2>&1")
    begin
      # found phantomjs, register poltergeist as a Capybara driver.
      require 'capybara/poltergeist'
      Capybara.register_driver :poltergeist do |app|
        Capybara::Poltergeist::Driver.new(app, :inspector => true)
      end
      Capybara.javascript_driver = :poltergeist
      Capybara.default_max_wait_time = 10
    rescue LoadError
      config.filter_run_excluding(js: true)
    end
  else
    config.filter_run_excluding(js: true)
  end

  # ref.
  #   http://kakakakakku.hatenablog.com/entry/2015/05/14/124653
  #   http://qiita.com/upinetree/items/4d4022c90ce32b68c38d
  Capybara.configure do |config|
    config.ignore_hidden_elements = false
  end

  config.before(:suite) do
    # load all models
    ::Rails.application.eager_load!
    # `rake db:drop`
    ::Mongoid::Clients.default.database.drop
  end

  config.add_setting :default_dbscope, default: :context
end

def unique_id
  Time.zone.now.to_f.to_s.delete('.').to_i.to_s(36)
end

# ref.
#   https://www.relishapp.com/rspec/rspec-expectations/v/2-5/docs/built-in-matchers/be-within-matcher
#   http://qiita.com/kozy4324/items/9a6530736be7e92954bc
RSpec::Matchers.define :eq_as_time do |expected_time|
  match do |actual_time|
    expect(actual_time.to_f).to be_within(0.001).of(expected_time.to_f)
  end
end
# TODO: Should this code be written here? Another more correctly place?

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }
