require File.dirname(__FILE__) + '/test_helper'

# Test cases for reading and generating CSS shorthand properties
class RuleSetCreatingShorthandTests < Test::Unit::TestCase
  include CssParser

  def setup
    @cp = CssParser::Parser.new
  end

# ==== Dimensions shorthand
  def test_combining_dimensions_into_shorthand
    properties = {'margin-right' => 'auto', 'margin-bottom' => '0px', 'margin-left' => 'auto', 'margin-top' => '0px', 
                  'padding-right' => '1.25em', 'padding-bottom' => '11%', 'padding-left' => '3pc', 'padding-top' => '11.25ex'}
    
    combined = create_shorthand(properties)
    
    assert_equal('0px auto;', combined['margin'])
    assert_equal('11.25ex 1.25em 11% 3pc;', combined['padding'])

    # after creating shorthand, all long-hand properties should be deleted
    assert_properties_are_deleted(combined, properties)

    # should not combine if any properties are missing
    properties.delete('margin-right')
    properties.delete('padding-right')

    combined = create_shorthand(properties)

    assert_equal '', combined['margin']
    assert_equal '', combined['padding']
  end

# ==== Font shorthand
  def test_combining_font_into_shorthand
    # should combine if all font properties are present
    properties = {"font-weight" => "300", "font-size" => "12pt", 
                   "font-family" => "sans-serif", "line-height" => "18px",
                   "font-style" => "oblique", "font-variant" => "small-caps"}
    
    combined = create_shorthand(properties)
    assert_equal('oblique small-caps 300 12pt/18px sans-serif;', combined['font'])

    # after creating shorthand, all long-hand properties should be deleted
    assert_properties_are_deleted(combined, properties)

    # should not combine if any properties are missing
    properties.delete('font-weight')
    combined = create_shorthand(properties)
    assert_equal '', combined['font']
  end

# ==== Background shorthand
  def test_combining_background_into_shorthand
    properties = {'background-image' => 'url(\'chess.png\')', 'background-color' => 'gray', 
                  'background-position' => 'center -10.2%', 'background-attachment' => 'fixed',
                  'background-repeat' => 'no-repeat'}
    
    combined = create_shorthand(properties)
    
    assert_equal('gray url(\'chess.png\') no-repeat center -10.2% fixed;', combined['background'])
    
    # after creating shorthand, all long-hand properties should be deleted
    assert_properties_are_deleted(combined, properties)
  end

  def test_property_values_in_url
    rs = RuleSet.new('#header', "background:url(http://example.com/1528/www/top-logo.jpg) no-repeat top right; padding: 79px 0 10px 0;  text-align:left;")
    rs.expand_shorthand!
    assert_equal('top right;', rs['background-position'])
    rs.create_shorthand!
    assert_equal('url(http://example.com/1528/www/top-logo.jpg) no-repeat top right;', rs['background'])
end

protected
  def assert_properties_are_deleted(ruleset, properties)
    properties.each do |property, value|
      assert_equal '', ruleset[property]
    end
  end

  def create_shorthand(properties)
    ruleset = RuleSet.new(nil, nil)
    properties.each do |property, value|
      ruleset[property] = value
    end
    ruleset.create_shorthand!
    ruleset
  end
end
