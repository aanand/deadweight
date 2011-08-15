require File.expand_path(File.join(File.dirname(__FILE__), "test_helper"))
require 'rake'

class RakeTaskTest < Test::Unit::TestCase
  context "Deadweight::RakeTask.new" do
    setup do
      @io = StringIO.new("", "w")

      Deadweight::RakeTask.new(@io) do |d|
        default_settings(d)
      end

      @task_names = Rake::Task.tasks.map { |t| t.name }
      @task = Rake::Task.tasks.find { |t| t.name == 'deadweight' }
    end

    should "define a `deadweight` task that automatically runs" do
      assert @task, "no deadweight task found in: #{@task_names.inspect}"

      @task.execute
      @io.close

      assert_correct_selectors_in_output(@io.string)
    end
  end
end
