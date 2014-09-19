require 'resque/tasks'

# This task wraps the built-in resque:work task to rescue and log
# errors that happen on connect.  The built-in task will allow 
# the exception to bubble up, which will certainly alert your 
# exception handler.  This is largely useless for two reasons:
#
# * Your worker monitoring tool will simply restart the worker and 99% of the time
#   have no problem reconnecting, thus you don't need this alert
# * That 1% of the time when there's a legit problem, you have two ways to find out about
#   it: your workering monitoring/management tool and your backed-up queues.  Both of
#   those are preferable to an unhandled exception that's usually not actionable.
#
# To use this, simply require this file in a place where Rake will pick it up, either in your 
# Rakefile or (for Rails) in a file like +lib/tasks/resque.rake+
namespace :resqutils do
  desc 'Resque worker task that logs Redis errors instead of raising them'
  task :work do
    begin
      Rake::Task['resque:work'].invoke
    rescue Redis::BaseError => ex
      puts "Unhandled Redis Error from Resque Worker: #{ex.message}"
    end
  end
end
