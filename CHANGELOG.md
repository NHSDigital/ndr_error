## [Unreleased]
*no unreleased changes*

## 2.2.0 / 2020-02-26
### Added
* Add more flexible middleware `NdrError::Recorder` middleware

## 2.1.0 / 2019-10-08
### Added
* Add `NdrError.after_log { ... }` callback registration (#20)

## 2.0.3 / 2019-07-25
### Fixed
* Add `inverse_of` configuration to the associations

## 2.0.2 / 2019-05-16
### Fixed
* fix bug that causes crash on vague search. Resolves #10
* Support for Rails 6, Ruby 2.6, dropping support for older versions

## 2.0.1 / 2018-10-11
### Fixed
* fix bug with searching integer user column

## 2.0.0 / 2018-06-05
### Added
* log causal exceptions too, automatically (#16)
* introduce breadcrumbs to the UI

### Fixed
* tidy up controls for navigating between logs
* improve behaviour / UI when there are multiple logs. Resolves #14
* fix CSS float issue
