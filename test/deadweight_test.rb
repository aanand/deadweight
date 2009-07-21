require 'test_helper'

class DeadweightTest < Test::Unit::TestCase
  def setup
    @dw = Deadweight.new
    @dw.log_file = 'test.log'
    @dw.root = File.dirname(__FILE__) + '/fixtures'
    @dw.stylesheets << '/style.css'
    @dw.pages << '/index.html'

    @result = @dw.run
  end

  should "report unused selectors" do
    assert @result.include?('#foo .bar .baz')
  end

  should "not report used selectors" do
    assert !@result.include?('#foo')
    assert !@result.include?('#foo .bar')
  end

  should "accept Procs as targets" do
    @dw.mechanize = true

    @dw.pages << proc {
      fetch('/index.html')
      agent.page.links.first.click
    }

    assert @dw.run.empty?
  end
end
