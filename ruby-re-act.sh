#!/usr/bin/env ruby
#frozen_string_literal: true

require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  ruby "3.1.1"
  gem  "byebug"
  gem "dotenv"
  gem "ruby-openai"
end

require "dotenv/load"
require "openai"
require "yaml"
require 'byebug'

def main
  puts 'hello world'
end

main if $PROGRAM_NAME == __FILE__
