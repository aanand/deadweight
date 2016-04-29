require 'rubygems'
require 'bundler'
Bundler.setup

require 'test/unit'
require 'shoulda'
require 'deadweight'

class Test::Unit::TestCase

  def info_yaml_for_test(*filenames)
    require 'yaml'
    filenames.flatten!
    result = Hash.new{|h, k| h[k] = []}
    filenames.each do |filename|
      yml = YAML.load_file("test/fixtures/#{filename.split(".").first}_infos.yml")
      result[:used_rules].push(*yml[:used_rules])
      result[:unused_rules].push(*yml[:unused_rules])
      result[:unsupported_rules].push(*yml[:unsupported_rules])
    end

    result[:unused_rules] -= result[:used_rules]
    result.default = nil
    result.values.flatten!
    result
  end

  def self.should_correctly_report_selectors(filename)
    should "report unused selectors" do
      assert_reports_unused_selectors(@result, filename)
    end

    should "not report used selectors" do
      assert_does_not_report_used_selectors(@result, filename)
    end
  end

  def assert_correct_selectors_in_output(output, filename)
    if output.is_a?(String)
      selectors = output.split("\n")
    else
      selectors = output
    end
    assert_reports_unused_selectors(selectors, filename)
    assert_does_not_report_used_selectors(selectors, filename)
  end

  def assert_reports_unused_selectors(output, filename)
    (info_yaml_for_test(filename)[:unused_rules] + info_yaml_for_test(filename)[:unsupported_rules]).flatten.each do |s|
      assert output.include?(s), "output is missing #{s.inspect}:\n#{output}"
    end
  end

  def assert_does_not_report_used_selectors(output, filename)
    info_yaml_for_test(filename)[:used_rules].each do |s|
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
