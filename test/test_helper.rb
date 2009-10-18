require 'rubygems'
require 'test/unit'
require 'shoulda'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'deadweight'

class Test::Unit::TestCase
  UNUSED_SELECTORS = ['#foo .bar .baz']
  USED_SELECTORS   = ['#foo', '#foo .bar']

  def self.should_correctly_report_selectors
    should "report unused selectors" do
      UNUSED_SELECTORS.each do |s|
        assert @result.include?(s)
      end
    end

    should "not report used selectors" do
      USED_SELECTORS.each do |s|
        assert !@result.include?(s)
      end
    end
  end

  def assert_correct_selectors_in_output(output)
    UNUSED_SELECTORS.each do |s|
      assert_equal 1, output.grep(%r{^#{Regexp.escape(s)} \{}).length
    end

    USED_SELECTORS.each do |s|
      assert_equal 0, output.grep(%r{^#{Regexp.escape(s)} \{}).length
    end
  end

  def default_settings(dw)
    dw.log_file = 'test.log'
    dw.root = File.dirname(__FILE__) + '/fixtures'
    dw.stylesheets << '/style.css'
    dw.pages << '/index.html'
  end
end
