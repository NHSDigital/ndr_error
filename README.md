# NdrError [![Build Status](https://travis-ci.org/PublicHealthEngland/ndr_error.svg?branch=master)](https://travis-ci.org/PublicHealthEngland/ndr_error)

This is the Public Health England (PHE) National Disease Registers (NDR) Error ruby gem. It is a 
Rails engine that provides error logging, viewing, and grouping capabilities.

Exceptions are logged as `NdrError::Log` records, which can be associated by instances
`NdrError::Fingerprint`. Grouping is done by fuzzy matching of exception description and backtrace.
The grouping used can be customised by the host application (see below).

## Installation / Setup

Add this line to your application's Gemfile:

```ruby
gem 'ndr_error', git: 'https://github.com/PublicHealthEngland/ndr_error.git'
```

And then execute:

    $ bundle

### Schema setup

`NdrError` bundles two migrations, for adding `ERROR_LOG` and `ERROR_FINGERPRINT` tables. These
can be cloned from the engine into the host application's `db/migrate` folder with:

    $ bundle exec rake ndr_error:install:migrations

The `ERROR_LOG` table created does not contain a column for user context, but it does require one.
Not adding it by default allows the host application to choose a sensible name to fit in with it's
schema. Once a column has been added, `NdrError` can be informed with `user_column=` (see below).

### Error interception

There are a variety of methods for trapping exceptions in a Rails app; therefore, `NdrError` does
not automatically configurate itself to operate in any particular way. That said, it does bundle
a Rack application that can be used as part of the Rails exception-handling middleware.

In the host application's `application.rb`, the following configuration can be added:

```ruby
# Configure the ActionDispatch::ShowExceptions middleware to use NdrError's exception logger:
config.exceptions_app = lambda do |env|
  rack_app = NdrError::Middleware::PublicExceptions.new(Rails.public_path)
  rack_app.call(env)
end
```

## Configuration

`NdrError` is generally pre-configured with sensible defaults, but with some notable exceptions
that require manual setup.

Configuration | Description
--- | ---
`user_column` | The `ERROR_LOG` table doesn't have a user-identifying column by default. `NdrError` expects you to add one; use this variable to inform it of the column name you chose. Regardless of the column name, the attribute is aliased to `user_id`.
`log_parameters` | A callable object that should return a hash specifying (at minimum) the `user_id`. This is invoked when an exception is being logged, to tag it with some context.

Other configuration:

Configuration | Default | Description
--- | --- | ---
`exception_app_callback` | `-> { true }` | A callback that is fired when an exception is being logged. Can be used for e.g. sending email notifications. Returning false will abort the logging.
`check_current_user_authentication` | `-> { true }` | A callable object that should return whether or not the current user should be able to view logged exceptions.
`check_current_user_permissions` | `-> { true }` | A callable object that should return whether or not the current user should be able to tag / delete logged exceptions.
`filtered_parameters` | derived from host app | The context logging tries to capture request parameters. Use this to list sensitive parameters which should not be logged.
`hostname_identifier` | `-> { 'unknown host' }` | A callable object that returns the hostname of the machine on which Rails is running.
`database_identifier` | `-> { 'unknown database' }` | A callable object that returns an identifier of the current database.
`database_time_checker` | `-> { nil }` | A callable object, which can return the current database time; if so, DB-webapp clock drift can be calculated.
`fingerprint_threshold` | `100` | The number of full logs of a given fingerprint that should be retained, before only a counter is incremented.
`log_grace_period` | `90.days` | The soft-delete window, after which the `ERROR_LOG` table is periodically purged.
`compress_backtrace` | `true` | As much of the exception backtrace as possible is logged. By default, it is compressed to be make efficient use of the available space. However, if human-readability is desired, this can be disabled.
`description_fuzzers` | ... | An array of objects which are called in order with the exception's description, in order to "fuzz" it for fingerprinting. By default, object details are stripped (e.g. hexidecimal identifiers).
`ticket_url_format` | nil | Authorised users can tag fingerprints with a (ticket) url; if present, this configuration a regular expression to validate the format of any given URLs.

For example, in a host application initializer:

```ruby
# Configure user:
NdrError.user_column    = :person_id
NdrError.log_parameters = lambda do 
  { user_id: Person.currently_authenticated.id || 'N/A' }
end

# Remove SQL from Oracle exceptions:
NdrError.description_fuzzers.unshift(lambda { |description|
  description.gsub(/(OCIError: ORA-[0-9]*:)(.*)/m, '\1')
})  
```

## Contributing

1. Fork it ( https://github.com/PublicHealthEngland/ndr_error/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

### RuboCop
This project is configured to use RuboCop. Please ensure any contributions meet style guides,
wherever possible. You can run RuboCop with:

    $ rubocop .

### Coverage
Test coverage is measured by `simplecov` as part of the test suite. Its output can be viewed with:

    $ open coverage/index.html

Please note that this project is released with a Contributor Code of Conduct. By participating
in this project you agree to abide by its terms.
