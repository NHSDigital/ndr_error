## [Unreleased]
* no unreleased changes

## 2.4.2 / 2025-03-23
* fix link with icon button style

## 2.4.1 / 2025-02-03
### Fixed
* fix bootstrap 5 data attribute with BS namespace

## 2.4.0 / 2025-01-31
### Changed
* New views with bootstrap 5 styles
* Switch to bootstrap-icons as glyphicon no longer available in bootstrap 5

## 2.3.2 / 2024-11-21
### Fixed
* Support Ruby 3.2 and 3.3, Rails 7.1 and 7.2. Drop support for Ruby 2.7, Rails 6.0

## 2.3.1 / 2022-12-02
### Fixed
* Drop support for Ruby 2.6
* Support Ruby 3.1, Rails 7.0
* Replace Public Health England naming with NHS Digital

## 2.3.0 / 2022-01-14
### Fixed
* Allow basic loading into a host app that doesn't use `sprockets`.
* Drop support for Rails 5, Ruby 2.5
* Support Ruby 3.0

## 2.2.1 / 2020-02-26
### Fixed
* Allow basic loading into a host app that doesn't use `sprockets`.

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
