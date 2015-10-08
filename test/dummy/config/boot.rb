require 'rubygems'

# Use the specified gemfile, defaulting to ndr_error's Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../../../Gemfile', __FILE__)
require 'bundler'
Bundler.setup

$LOAD_PATH.unshift File.expand_path('../../../../lib', __FILE__)
