Dependent Restrict
==================

[![Build Status](https://travis-ci.org/sealink/dependent_restrict.png?branch=master)](https://travis-ci.org/sealink/dependent_restrict)
[![Coverage Status](https://coveralls.io/repos/sealink/dependent_restrict/badge.png)](https://coveralls.io/r/sealink/dependent_restrict)
[![Dependency Status](https://gemnasium.com/sealink/dependent_restrict.png?travis)](https://gemnasium.com/sealink/dependent_restrict)
[![Code Climate](https://codeclimate.com/github/sealink/dependent_restrict.png)](https://codeclimate.com/github/sealink/dependent_restrict)

A gem for rails 2, 3 and 4 that retrofits and improves rails 4 functionality

Rails 4 offers 2 very useful dependent restrictions:
```ruby
dependent: :raise_with_exception
dependent: :raise_with_error
```

In rails 3 it was just:
```ruby
dependent: :raise # same sa raise_with_exception
```

In rails 2 these didn't exist, it was just
```ruby
dependent: destroy
```

Which is available in rails 2, 3 and 4

## Differences from standard rails 4

* Error includes detailed message which shows up to 5 of the records that are dependent
  This is useful for users to know which dependencies must be removed before they can
  remove the parent record
