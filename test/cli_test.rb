require 'test_helper'

class CliTest < Test::Unit::TestCase
  COMMAND = "ruby -rubygems -Ilib bin/deadweight -s test/fixtures/style.css test/fixtures/index.html 2>/dev/null"

  should "output unused selectors on STDOUT" do
    @result = `#{COMMAND}`.split("\n")

    assert_equal 1, @result.grep(/^#foo \.bar \.baz \{/).length
    assert_equal 0, @result.grep(/^#foo \{/).length
    assert_equal 0, @result.grep(/^#foo .bar \{/).length
  end

  should "accept CSS rules on STDIN" do
    @result = `echo ".something { display: block; }" | #{COMMAND}`.split("\n")

    assert_equal 1, @result.grep(/^\.something \{/).length
  end
end

