# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{deadweight}
  s.version = "0.0.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Aanand Prasad"]
  s.date = %q{2009-08-18}
  s.default_executable = %q{deadweight}
  s.email = %q{aanand.prasad@gmail.com}
  s.executables = %q{deadweight}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "deadweight.gemspec",
     "bin/deadweight",
     "lib/deadweight.rb",
     "lib/deadweight/cli.rb",
     "test/deadweight_test.rb",
     "test/fixtures/index.html",
     "test/fixtures/index2.html",
     "test/fixtures/style.css",
     "test/test_helper.rb"
  ]
  s.homepage = %q{http://github.com/aanand/deadweight}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.4}
  s.summary = %q{RCov for CSS}
  s.test_files = [
    "test/deadweight_test.rb",
     "test/test_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<css_parser>, [">= 0"])
      s.add_runtime_dependency(%q<hpricot>, [">= 0"])
    else
      s.add_dependency(%q<css_parser>, [">= 0"])
      s.add_dependency(%q<hpricot>, [">= 0"])
      s.add_dependency(%q<mechanize>, [">= 0"])
      s.add_dependency(%q<Shoulda>, [">= 0"])
    end
  else
    s.add_dependency(%q<css_parser>, [">= 0"])
    s.add_dependency(%q<hpricot>, [">= 0"])
    s.add_dependency(%q<mechanize>, [">= 0"])
    s.add_dependency(%q<Shoulda>, [">= 0"])
  end
end
