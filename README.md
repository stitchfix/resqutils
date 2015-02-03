# resqutils - useful stuff when you have Resque in your app

This is a small library of useful modules and functions that can help dealing with Resque.

Currently:

* Spec helper `:some_queue.should have_job_queued(class: FooJob)`
* Methods to introspect queues, including the delayed queue, in your specs
* Simple `resque:work` task wrapper to better handle exceptions in the worker
* Marker interface to document jobs which should not be retried

Maybe will have more stuff1

## To use

Add to your `Gemfile`:

```ruby
gem 'resqutils'
```

## Spec Helpers

```ruby
# in spec_helper.rb
require 'resqutils/spec'

# In one of your spec files
describe SomeProcess do
  include Resqutils::Spec::ResqueHelpers

  # ...
end
```

`require`ing the `resqutils/spec` will also set up the `have_job_queued` matcher, which is likely what you'll want to use.

### Clearing Jobs

The most important part of using Resque in tests as making sure the queue has what you
think it has in it.  To that end, you'll likely need `clear_queue` in a `setup` or
`before` block.

```ruby
before do
  clear_queue(MyImportantJob) # clears whatever queue this job is configured to use
  clear_queue(:foobar)        # clear the "foobar" queue
end
```

### Checking that Jobs Were Queued

```ruby
# foo_service.rb
class FooService
  def doit(foo)
    Resque.enqueue(:foo,FooJob,foo)
    "bar"
  end
end

# foo_service_spec.rb
describe FooService do
  it "queues a job" do
    result = FooService.new.doit("blah")

    expect(result).to eq("bar")
    expect(:foo).to have_job_queued(class: FooJob, args: [ "blah" ])
  end
end
```

This also works with the delayed queue as provided by resque-scheduler:

```ruby
# foo_service.rb
class FooService
  def doit(foo)
    Resque.enqueue_in(5.minutes,:foo,FooJob,foo)
    "bar"
  end
end

# foo_service_spec.rb

describe FooService do
  it "queues a job" do
    result = FooService.new.doit("blah")

    expect(result).to eq("bar")
    # :delayed is special and triggers logic to look into the various scheduled queues
    expect(:delayed).to have_job_queued(class: FooJob, args: [ "blah" ])
  end
end
```

### Executing Jobs

In an integration test, you may wish to execute a job that's on the queue, which will both assert that it's there and perform whatever function it performs.


```ruby
# foo_service.rb
class FooService
  def doit(foo)
    Resque.enqueue(:foo,FooJob,foo)
    "bar"
  end
end

class FooJob
  def perform(some_value)
    Foo.create!(value: some_value)
  end
end

# the_foo_service_spec.rb
describe "the foo service" do
  include Resqutils::Spec::ResqueHelpers
  it "writes a Foo with the value" do
    result = FooService.new.doit("blah")

    process_resque_job(FooJob)

    expect(Foo.last.value).to eq("blah")
  end
end
```

The `ResqueHelpers` module has many more methods, if you need finer control over your tests with respect to resque.

### Exception Handling in your Worker

The built-in worker lets exceptions bubble up.
In a PaaS setup, or where your Redis is "over the internet", you'll get periodic connection issues from your worker.
These self-heal when your worker management system (e.g. monit) restarts the worker after it crashes.
Thus, these unhandled exceptions should just be ignored.

Since the built-in resque worker is a rake task, we provide a wrapper rake task to call it and log the exception:

```ruby
require 'resqutils/worker_task'
```

To run:

```
env TERM_CHILD=1 bundle exec rake environment resqutils:work QUEUE=file_uploads --trace
```

### Being clear about not retrying

Although you should design your jobs to automatically retry, some jobs simply should not be retried.
Instead of omitting the retry logic or dropping in a comment, you should use a marker interface to communicate intent via code:

```ruby
class DangerousJob
  include Resqutils::DoNotAutoRetry

  def perform
    # ...
  end
end
```

This is a more powerful statement that a comment, and communicates intent clearly.
