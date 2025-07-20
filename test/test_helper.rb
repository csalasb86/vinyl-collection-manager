ENV["RAILS_ENV"] ||= "test"

# Start SimpleCov before loading application code
require "simplecov"

SimpleCov.start "rails" do
  add_filter "/vendor/"
  add_filter "/test/"
  add_filter "/config/"
  add_filter "/db/"
  add_filter "/bin/"
  add_filter "/tmp/"

  # Set minimum coverage threshold
  minimum_coverage 80
  # Enable merging for parallel test runs
  SimpleCov.command_name "test:#{Process.pid}"
  SimpleCov.merge_timeout 3600
end

require_relative "../config/environment"
require "rails/test_help"
require "minitest/mock"

# Skip asset compilation issues in tests

module ActiveSupport
  class TestCase
    # Disable parallel tests for SimpleCov compatibility
    # parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
