module Resqutils
  module Spec
  end
end

# Mix this into your tests to get helpful methods to manipulate a live resque queue.
module Resqutils::Spec::ResqueHelpers
  # Process the resque job on the queue that matches the given criteria.  Useful to simulate
  # a resque worker processing something inside an integration test.  Also handles the delayed queue.
  #
  # expected_class:: Class that should be on the job queue
  # queue:: if present, the queue name (as a String or Symbol).  If omitted, expected_class's @queue ivar
  #         will be queries to get the queue name. +:delayed+ is a special queue
  #         that represents the delayed queue provided by +resque-scheduler+.

  # block:: if provided, will be given the popped job right before it is processed.
  def process_resque_job(expected_class, queue=nil, &block)
    block ||= ->(payload) {}
    queue ||= expected_class.instance_variable_get("@queue")
    job = if queue == :delayed
            delayed_jobs.select { |job|
              job["class"] == expected_class.name
            }.first
          else
            job = Resque.pop(queue)
          end
    raise "No jobs on #{queue}" if job.nil?
    klass = job["class"].constantize
    klass.should == expected_class
    block.call(job)
    klass.perform(*job["args"])
  end

  # Process several jobs that have the same class and queue. 
  #
  # number:: number of jobs expected
  # expected_class:: Class of the job you want to process
  # queue:: if present, the queue name (as a String or Symbol).  If omitted, expected_class's @queue ivar
  #         will be queries to get the queue name. +:delayed+ is a special queue
  #         that represents the delayed queue provided by +resque-scheduler+.

  # block:: if provided, will be given each popped job right before it is processed.
  def process_multiple_resque_jobs(number, expected_class, queue=nil, &block)
    number.times do
      process_resque_job(expected_class, queue, &block)
    end
  end

  # Get the size of the given queue.  This mostly prevents your test from having
  # direct coupling to resque's (crappy) internal API.
  #
  # queue:: name of the queue, as a Symbol or String
  def queue_size(queue)
    Resque.size(queue)
  end

  # Clear the queue.  Useful in before blocks to make sure there's nothing hanging around in your queue from
  # a previous test run.
  #
  # queue_name:: If a Class, the ivar @queue is used to determine which queue to clear.  Otherwise, assumes
  #              it's a string or symbol and will clear that queue.  +:delayed+ is a special queue
  #              that represents the delayed queue provided by +resque-scheduler+.
  def clear_queue(queue_name)
    if queue_name.kind_of?(Class)
      queue_name = queue_name.instance_variable_get("@queue")
    end
    if queue_name == :delayed
      Resque.reset_delayed_queue
    else
      Resque.redis.del("queue:#{queue_name}")
      Resque.redis.del("resque:queue:#{queue_name}")
    end
  end

  # Get jobs from +queue_name+ that match the given hash.  This returns
  # both the jobs that matched and *all* jobs from the queue, so you can create a useful
  # error message in your tests.
  #
  # queue_name:: A String or Symbol representing the name of the queue, where +:delayed+ is special and will
  #              cause the code to look in the delayed queue as provided by resque-scheduler.
  # expected_job_hash:: Criteria for matching, typically a two-element hash containing the class and args
  #                     of the job you are looking for.
  #
  # Returns an array of size 2, where the first element is an Array of jobs matching the given criteria, and
  # the second element is an Array of all jobs.
  #
  # Example
  #
  # Consider the queue "foo" has these jobs in it:
  #
  # * { "class" => "WarmCaches", "args" => [ 1234 ] }
  # * { "class" => "WarmCaches", "args" => [ 4567 ] }
  # * { "class" => "IndexPurchases", "args" => [ 1234 ] }
  #
  #     jobs_matching(:foo, class: WarmCaches, args: [ 1234 ])     # => matching jobs is the first job above
  #     jobs_matching(:foo, class: IndexPurchases, args: [ 1234 ]) # => matching jobs is the third job above
  #     jobs_matching(:foo, class: IndexPurchases, args: [ 9999 ]) # => matching jobs is nothing
  #
  def jobs_matching(queue_name,expected_job_hash)
    jobs = if queue_name == :delayed
             delayed_jobs
           else
             (0...Resque.size(queue_name)).map { |index|
               [Resque.peek(queue_name,index),index]
             }
           end
    matching_jobs = jobs.select { |(job,index)|
      raise "No job at index #{index}" if job.nil?
      expected_job_hash.all? do |k,v|
        k = k.to_s
        v = v.to_s if v.kind_of?(Class)
        raise "Job #{job} at index #{index} was missing key #{k}" if job[k].nil?
        if k == 'scheduler_timestamp'
          ((v.to_i - 60000)..(v.to_i + 60000)).cover?(job[k])
        else
          job[k] == v
        end
      end
    }.map(&:first)
    [matching_jobs,jobs]
  end

  # Return all jobs in a delayed queue, with each job augmented with the key +scheduler_timestamp+ to represent
  # what time the job was schedule to run for.
  def delayed_jobs
    # The double-checks here are so that we won't blow up if the config stops using redis-namespace
    timestamps = (Array(Resque.redis.zrange("resque:delayed_queue_schedule",0,-1)) + 
                  Array(Resque.redis.zrange("delayed_queue_schedule",0,-1)))
    raise "Nothing on delayed schedule" if timestamps.empty?

    timestamps.map { |timestamp|
      [
        Array(Resque.redis.lrange("resque:delayed:#{timestamp}",0,-1)) + Array(Resque.redis.lrange("delayed:#{timestamp}",0,-1)),
        timestamp,
      ]
    }.map { |(job_strings,timestamp)|
      job_strings.map { |job_string|
        JSON.parse(job_string).merge('scheduler_timestamp' => timestamp.to_i)
      }
    }.flatten
  end
end
