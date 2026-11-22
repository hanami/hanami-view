# frozen_string_literal: true

require "open3"

module Setup
  module_function

  def execute(cmd)
    puts "Running #{cmd}"

    status, _out, err = nil

    Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
      _pid = wait_thr.pid
      stdin.close
      _out = stdout.read
      err = stderr.read
      status = wait_thr.value
    end

    unless status.success?
      puts "Failed to run #{cmd}"
      puts err
      exit 1
    end
  end
end
