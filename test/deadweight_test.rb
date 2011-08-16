require File.expand_path(File.join(File.dirname(__FILE__), "test_helper"))

class DeadweightTest < Test::Unit::TestCase
  def setup
    @dw = Deadweight.new
    default_settings(@dw)
    @result = @dw.run
  end

  context "when initialized with a block" do
    setup do
      @dwb = Deadweight.new do |dw|
        default_settings(dw)
      end

      @result = @dwb.run
    end

    should "have the same attributes" do
      assert_equal(@dw.log_file,    @dwb.log_file)
      assert_equal(@dw.root,        @dwb.root)
      assert_equal(@dw.media_root,  @dwb.media_root)
      assert_equal(@dw.stylesheets, @dwb.stylesheets)
      assert_equal(@dw.pages,       @dwb.pages)
    end

    should_correctly_report_selectors
  end

  should_correctly_report_selectors

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

  should 'provide the results of its last run with #unused_selectors' do
    assert_equal @result, @dw.unused_selectors
  end

  should 'provide the parsed CSS rules with #parsed_rules' do
    assert_equal 'color: green;', @dw.parsed_rules['#foo']
  end
end
