require 'rubygems'
require 'bundler'
Bundler.setup

require 'test/unit'
require 'shoulda'
require 'deadweight'

class Test::Unit::TestCase
  UNUSED_SELECTORS = ['#foo .bar .baz']
  USED_SELECTORS   = ['#foo', '#foo .bar']
  ERROR_SELECTORS  = ['* :click']

  def self.should_correctly_report_selectors
    should "report unused selectors" do
      assert_reports_unused_selectors(@result)
    end

    should "not report used selectors" do
      assert_does_not_report_used_selectors(@result)
    end

    should "report errored selectors" do
      assert_reports_error_selectors(@result)
    end
  end

  def assert_correct_selectors_in_output(output)
    selectors = output.split("\n")
    assert_reports_unused_selectors(selectors)
    assert_does_not_report_used_selectors(selectors)
  end

  def assert_reports_unused_selectors(output)
    UNUSED_SELECTORS.each do |s|
      assert output.include?(s), "output is missing #{s.inspect}:\n#{output}"
    end
  end

  def assert_reports_error_selectors(output)
    ERROR_SELECTORS.each do |s|
      assert output.include?(s), "output is missing #{s.inspect}:\n#{output}"
    end
  end

  def assert_does_not_report_used_selectors(output)
    USED_SELECTORS.each do |s|
      assert !output.include?(s), "output should not contain #{s.inspect}:\n#{output}"
    end
  end

  def default_settings(dw)
    dw.log_file = 'test.log'
    dw.root = File.dirname(__FILE__) + '/fixtures'
    dw.stylesheets << '/style.css'
    dw.pages << '/index.html'
  end
end
