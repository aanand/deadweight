Deadweight
==========

Deadweight is a CSS coverage tool. Given a set of stylesheets and a set of URLs, it determines which selectors are actually used and reports which can be "safely" deleted.

Screencast!
-----------

Ryan Bates has worked his magic once again. [Head over here for an excellent introduction to Deadweight](http://railscasts.com/episodes/180-finding-unused-css).

How to Install It
-----------------

    $ gem install deadweight

How to Use It
-------------

There are multiple ways to use Deadweight. It's designed to be completely agnostic of whatever framework (or indeed language) your website is built on, but optimised for Ruby and Rails.

### Run it From the Command Line ###

    $ deadweight -s styles.css -s ie.css index.html about.html
    $ deadweight -s http://www.tigerbloodwins.com/index.css http://www.tigerbloodwins.com/
    $ deadweight --root http://kottke.org/ -s '/templates/2009/css.php?p=mac' / /everfresh /about

### Integrate it With Your Integration Tests ###

Deadweight can hijack your Rails integration tests (both the spartan Test::Unit type and the refreshing Cucumber variety), capturing every page that is returned by your app during testing and saving you the trouble of manually specifying a ton of URLs and login processses.

First, put this in your `Gemfile`:

    group :test do
      gem 'colored'
      gem 'deadweight', :require => 'deadweight/hijack/rails'
    end

Then, run your integration tests with the environment variable `DEADWEIGHT` set to `true`:

    rake test DEADWEIGHT=true
    rake cucumber DEADWEIGHT=true

Let me know how it goes. It's not terribly customisable at the moment (you can't specify what exact stylesheets to look at, or what selectors to ignore). I'm looking for your feedback on how you'd like to be able to do that.

### Rake Task ###

    # lib/tasks/deadweight.rake
  
    require 'deadweight'
  
    Deadweight::RakeTask.new do |dw|
      dw.stylesheets = ["/stylesheets/style.css"]
      dw.pages = ["/", "/page/1", "/about"]
    end

Running `rake deadweight` will output all unused rules, one per line. Note that it looks at `http://localhost:3000` by default, so you'll need to have `script/server` (or whatever your server command looks like) running.

### Call it Directly from Ruby ###

    require 'deadweight'
  
    dw = Deadweight.new
    dw.stylesheets = ["/stylesheets/style.css"]
    dw.pages = ["/", "/page/1", "/about"]
    puts dw.run

### Pipe In CSS Rules from STDIN ###

    $ cat styles.css | deadweight index.html

### Use it as an HTTP Proxy ###

    $ deadweight -l deadweight.log -s styles.css -w http://github.com/ -P

Setting the Root URL
--------------------

By default, Deadweight uses `http://localhost:3000` as the base URL for all paths. To change it, set `root`:

    dw.root = "http://staging.example.com"      # staging server
    dw.root = "http://example.com/staging-area" # urls can have paths in
    dw.root = "/path/to/some/html"              # local paths work too

What About Stuff Added by Javascript?
-------------------------------------

Deadweight is completely dumb about any classes, IDs or tags that are only added by your Javascript layer, but you can filter them out by setting `ignore_selectors`:

    dw.ignore_selectors = /hover|lightbox|superimposed_kittens/

The command-line tool also has basic support for [Lyndon](http://github.com/defunkt/lyndon) with the `-L` flag, which simply pipes all HTML through the `lyndon` executable.

You Can Use Mechanize for Complex Stuff
---------------------------------------

Set `mechanize` to `true` and add a Proc to `pages` (rather than a String), and Deadweight will execute it using [Mechanize](http://mechanize.rubyforge.org/mechanize):

    dw.mechanize = true

    # go through the login form to get to a protected URL
    dw.pages << proc {
      fetch('/login')
      form = agent.page.forms.first
      form.username = 'username'
      form.password = 'password'
      agent.submit(form)
      fetch('/secret-page')
    }

    # use HTTP basic auth
    dw.pages << proc {
      agent.auth('username', 'password')
      fetch('/other-secret-page')
    }

The `agent` method returns the Mechanize instance. The `fetch` method is a wrapper around `agent.get` that will abort in the event of an HTTP error status.

If You Install `colored`, It'll Look Nicer
-------------------------------------------------

    gem install colored

Copyright
---------

Copyright (c) 2009 Aanand Prasad. See LICENSE for details.
