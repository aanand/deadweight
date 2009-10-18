class Deadweight
  class RakeTask
    def initialize output=STDOUT, &block
      desc "run deadweight"
      task :deadweight do
        dw = Deadweight.new(&block)
        dw.run
        dw.dump(output)
      end
    end
  end
end

