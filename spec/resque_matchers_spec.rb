require 'spec_helper'
require 'rspec/version'

describe "Resque RSpec custom matchers" do
  include Resqutils::Spec::ResqueHelpers

  context "have_job_queued" do
    class BackgroundJob
      @queue = :low

      def self.perform
      end
    end

    class Service
      def expensive
        Resque.enqueue(BackgroundJob)
      end
    end

    before do
      clear_queue(BackgroundJob)
    end

    it "asserts Resque job has been queued" do
      Service.new.expensive

      if RSpec::Version::STRING.start_with?("2")
        "low".should have_job_queued(class: BackgroundJob, args: [])
      else
        expect("low").to have_job_queued(class: BackgroundJob, args: [])
      end
    end
  end
end
