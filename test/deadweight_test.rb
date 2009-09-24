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

  should 'strip pseudo classes from selectors' do
    # #oof:hover (#oof does not exist)
    assert @result.include?('#oof:hover'), @result.inspect

    # #foo:hover (#foo does exist)
    assert !@result.include?('#foo:hover')

    # #rab:hover::selection (#rab does not exist)
    assert @result.include?('#rab:hover::selection')
  end

  should "accept Procs as targets" do
    @dw.mechanize = true

    @dw.pages << proc {
      fetch('/index.html')
      agent.page.links.first.click
    }

    assert @dw.run.empty?
  end

  should "accept IO objects as targets" do
    @dw.pages << File.new(File.dirname(__FILE__) + '/fixtures/index2.html')

    assert @dw.run.empty?
  end

  should "allow individual CSS rules to be appended" do
    @dw.rules = ".something { display: block; }"

    assert @dw.run.include?(".something")
  end
end
