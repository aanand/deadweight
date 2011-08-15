require File.expand_path(File.join(File.dirname(__FILE__), "test_helper"))

class CliTest < Test::Unit::TestCase
  COMMAND      = "ruby -rubygems -Ilib bin/deadweight"
  FULL_COMMAND = "#{COMMAND} -s test/fixtures/style.css test/fixtures/index.html 2>/dev/null"

  should "output unused selectors on STDOUT" do
    assert_correct_selectors_in_output(`#{FULL_COMMAND}`)
  end

  should "accept CSS rules on STDIN" do
    assert `echo ".something { display: block; }" | #{FULL_COMMAND}`.include?('.something')
  end

  should "accept a [-r | --root] argument and relative paths" do
    %w(-r --root).each do |arg|
      assert_correct_selectors_in_output(`#{COMMAND} #{arg} test/fixtures -s /style.css /index.html 2>/dev/null`)
    end
  end
end

