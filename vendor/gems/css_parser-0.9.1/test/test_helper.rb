$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__), '../'))
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__), '../lib/'))
require 'rubygems'
require 'test/unit'
require 'css_parser'
require 'net/http'
require 'open-uri'
require 'WEBrick'
