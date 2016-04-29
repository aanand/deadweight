# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name     = "deadweight"
  s.version  = "0.2.2"
  s.authors  = ["Aanand Prasad"]
  s.email    = "aanand.prasad@gmail.com"
  s.homepage = "http://github.com/aanand/deadweight"
  s.summary  = "A coverage tool for finding unused CSS"
  s.license  = 'MIT'

  s.add_dependency 'nokogiri'
  s.add_dependency 'bisect'
  s.add_dependency 'css_parser', '~> 1.3.5'

  s.add_development_dependency "shoulda"
  s.add_development_dependency "mechanize", "~> 2.5.1"
  s.add_development_dependency "rake"
  s.add_development_dependency "nokogiri", '~> 1.6.6.2'

  s.files        = `git ls-files LICENSE README.md bin lib vendor`.split
  s.require_path = 'lib'
  s.executables  = Dir.glob("bin/*").map(&File.method(:basename))
end

