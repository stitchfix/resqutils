module WorkerHelper
  def worker(run_at = Time.now)
    double("resque worker", id: SecureRandom.uuid, job: { "queue" => "whatever",
                                                          "run_at" => run_at.to_s,
                                                          "payload" => { "class" => "Foo", "args" => [] } })
  end
end
