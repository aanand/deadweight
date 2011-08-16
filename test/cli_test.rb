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

  should "accept a [-m | --media_root] argument and relative paths" do
    %w(-m --media_root).each do |arg|
      assert_correct_selectors_in_output(`#{COMMAND} #{arg} test/fixtures -s /style.css test/fixtures/index.html 2>/dev/null`)
    end
  end

  should "accept a [-m | --media_root] argument, along with a [-r | --root] argument and relative paths for each" do
    %w(-m --media_root).each do |media_arg|
      %w(-r --root).each do |root_arg|
        assert_correct_selectors_in_output(`#{COMMAND} #{root_arg} test/fixtures #{media_arg} test/fixtures -s /style.css /index.html 2>/dev/null`)
      end
    end
  end
end

