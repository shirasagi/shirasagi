class Sys::CopyJob
  include Job::Worker

  def call(params)
    copy = Sys::Copy.new
    copy.run_copy(params)
  end
end
