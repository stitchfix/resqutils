module Resqutils
  # Marker module to explicitly indicate that a job should not retried.  Useful when your app makes
  # heavy use of retries as a means to make it very clear a certain job should not be retried.
  module DoNotAutoRetry
  end
end
