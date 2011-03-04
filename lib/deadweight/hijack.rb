class Deadweight
  module Hijack
    def self.redirect_output(log_file_prefix)
      original_stdout, original_stderr = STDOUT.clone, STDERR.clone

      STDOUT.reopen(File.open("#{log_file_prefix}stdout.log", 'w'))
      STDERR.reopen(File.open("#{log_file_prefix}stderr.log", 'w'))

      [original_stdout, original_stderr]
    end
  end
end

