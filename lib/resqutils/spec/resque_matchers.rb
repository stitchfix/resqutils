# Defines the match +have_job_queued+ which can be asserted on a queue name
# to check that a particular job is queued.
#
# Example
#
#     :purchasing.should have_job_queued(class: SubscriptionChargeJob
#                                        args: [ 12345, "99.87" ] )
RSpec::Matchers.define :have_job_queued do |expected_job_hash|
  include Resqutils::Spec::ResqueHelpers

  match do |queue_name|
    jobs_matching(queue_name,expected_job_hash).first.size == 1
  end

  failure_message do |queue_name|
    matching_jobs,all_jobs = jobs_matching(queue_name,expected_job_hash)
    if matching_jobs.empty?
      "No jobs in #{queue_name} matched #{expected_job_hash.inspect} (Found these jobs: #{all_jobs.map(&:inspect).join(',')})"
    elsif matching_jobs.size > 1
      "Mutiple jobs on #{queue_name} matched - try clearing queues before each test"
    end
  end

  failure_message_when_negated do |queue_name|
    "Found job #{expected_job_hash.inspect} in the queue"
  end
end
