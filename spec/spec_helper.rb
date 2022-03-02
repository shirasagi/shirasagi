# Don't run always Coverage analysis
# ref. http://docs.travis-ci.com/user/environment-variables/#Default-Environment-Variables
require 'dotenv'
Dotenv.load

ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../config/environment", __dir__)

require 'webdrivers'
# Webdrivers.logger.level = :DEBUG
require 'rails-controller-testing'
require 'rspec/rails'
# require 'rspec/autorun'
require 'rspec/collection_matchers'
require 'rspec/its'
require 'capybara/rspec'
require 'capybara/rails'
require 'factory_bot'
require 'timecop'
require 'support/ss/capybara_support'

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.check_pending! if defined?(ActiveRecord::Migration)

def ci?
  ENV["CI"] == "true"
end

def travis?
  ci? && ENV["TRAVIS"] == "true"
end

def analyze_coverage?
  ci? || ENV["ANALYZE_COVERAGE"] != "disabled"
end

if analyze_coverage?
  require 'simplecov'
  require 'simplecov-csv'
  require 'simplecov-html'

  formatters = [
    SimpleCov::Formatter::CSVFormatter,
    SimpleCov::Formatter::HTMLFormatter
  ]
  if ci?
    require 'simplecov-lcov'

    # coveralls requires consolidated file "lcov.info"
    SimpleCov::Formatter::LcovFormatter.config do |config|
      config.report_with_single_file = true
      config.lcov_file_name = "lcov.info"
    end

    formatters << SimpleCov::Formatter::LcovFormatter
  end

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(formatters)
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
  # config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  # config.use_transactional_fixtures = true

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
  Kernel.srand config.seed

  config.include Rails.application.routes.url_helpers
  config.include Capybara::DSL
  config.include ActiveJob::TestHelper
  config.include ActiveSupport::Testing::TimeHelpers
  config.include FactoryBot::Syntax::Methods

  config.add_setting :default_dbscope, default: :context

  driver = ENV['driver'].presence || 'auto'
  if !SS::CapybaraSupport.activate_driver(driver, config)
    config.filter_run_excluding(js: true)
  end

  # fragile specs are ignored when rspec is executing in Travis CI.
  if ci?
    config.filter_run_excluding(fragile: true)
  end

  config.before(:suite) do
    # load all models
    ::Rails.application.eager_load!
    # `rake db:drop`
    ::Mongoid::Clients.default.database.drop
    # clear logfile
    File.write(Rails.logger.instance_variable_get(:@logdev).filename, '')
  end

  config.before(:context) do
    FactoryBot.reload
    Capybara.app_host = nil
  end

  config.before(:example, type: :feature) do |example|
    page.reset!
    # puts '# ' + example.metadata[:full_description]
  end

  config.after(:example, type: :feature) do
    page.reset!
  end

  config.after(:suite) do
    file = Rails.logger.instance_variable_get(:@logdev).filename
    logs = File.read(file).split(/\R/).select { |s| s.index('FATAL --') && /FATAL -- : +\w./.match?(s) }
    puts '', '-' * 50, '[test.log]', '', logs.join("\n"), '-' * 50 if logs.present?
  end

  Capybara.configure do |config|
    config.ignore_hidden_elements = false
    config.default_max_wait_time = (ENV["CAPYBARA_MAX_WAIT_TIME"] || 10).to_i

    # to test michecker, it is needed to bind globally to access server within docker container.
    config.server_host = "0.0.0.0"
  end

  if ci? || ENV["rspec_retry"].present?
    require 'rspec/retry'

    config.verbose_retry = true
    config.display_try_failure_messages = true
    config.around :each, :js do |example|
      example.run_with_retry retry: 3
    end

    # callback to be run between retries
    config.retry_callback = proc do |ex|
      # run some additional clean up task - can be filtered by example metadata
      if ex.metadata[:js]
        Capybara.reset!
      end
    end

    puts "[RSpec] enabled rspec retry"
  end
end

ALPHABETS = ("a".."z").to_a.freeze

def unique_id(size = 5)
  s = ALPHABETS.sample + Random.bytes(size).unpack1("H*")
  s.downcase!
  s
end

def unique_tel
  "99-#{Array.new(4) { rand(0..9 ) }.join}-#{Array.new(4) { rand(0..9 ) }.join}"
end

def unique_domain
  "#{unique_id}.example.jp"
end

def unique_url
  "#{%w(http https).sample}://#{unique_domain}/#{unique_id}/"
end

def unique_email
  "#{unique_id}@example.jp"
end

def ss_japanese_text(length: 10, separator: '')
  @japanese_chars ||= begin
    hiragana = ('あ'..'ん').to_a
    katakana = ('ア'..'ン').to_a
    sjis_1st_level_start = "亜".encode("cp932")
    sjis_1st_level_end = "腕".encode("cp932")
    sjis_1st_level = (sjis_1st_level_start..sjis_1st_level_end).to_a
    sjis_1st_level.map! { |k| k.encode("UTF-8", invalid: :replace, undef: :replace, replace: '') }
    sjis_1st_level.reject! { |k| k.blank? }

    hiragana + katakana + sjis_1st_level
  end

  @japanese_chars.sample(length).join(separator)
end

def with_env(hash)
  save = {}
  hash.each do |k, v|
    save[k] = ENV[k] if ENV.key?(k)
    ENV[k] = v
  end

  ret = yield

  hash.each do |k, _|
    if save.key?(k)
      ENV[k] = save[k]
    else
      ENV.delete(k)
    end
  end

  ret
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
