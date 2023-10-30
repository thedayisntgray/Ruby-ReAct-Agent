#!/usr/bin/env ruby
#frozen_string_literal: true

require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  ruby "3.1.1"
  gem "byebug"
  gem "dotenv"
  gem "ruby-openai"
  gem "wikipedia-client"
end

require "dotenv/load"
require "openai"
require "yaml"
require 'wikipedia'
require 'byebug'

class ReAct
  require 'dotenv/load'

  def initialize(agent_prompt: nil)
    @client = OpenAI::Client.new(access_token: ENV["OPEN_AI_KEY"])
    @messages = []

    @known_actions = [
      "wikipedia",
      "calculate"
    ]

    unless agent_prompt.nil?
      @messages << { "role" => "system", "content" => agent_prompt }
    end
  end

  def query(question, max_iterations)

    next_prompt = question
    max_iterations.times do |i|
      result = execute(next_prompt)
      print result
      actions = result.split("\n").map{ |a| /^Action: (\w+): (.*)$/.match(a)}.compact.first

      if actions
        tool = actions[1]
        action_input = actions[2]

        unless @known_actions.include?(tool)
          raise "Unknown Action: #{tool}"
        end
        puts " -- running #{tool} #{action_input}"
        observation = send(tool, action_input)
        puts "Observation: #{observation}"
        next_prompt = "Observation: #{observation}"

      else
        return
      end
    end
  end

  def calculate(expr)
    eval(expr)
  end
    

  def execute(question)
    @messages << { "role" => "user", "content" => question }
    response = @client.chat(
      parameters: {
        model: "gpt-3.5-turbo",
        messages: @messages
      }
    )

    result = response.dig("choices").first.dig("message").dig("content")
    @messages << { "role" => "assistant", "content" => result }
    result 
  end
end

  def main
    prompt = "You run in a loop of Thought, Action, PAUSE, Observation.
      At the end of the loop you output an Answer
      Use Thought to describe your thoughts about the question you have been asked.
      Use Action to run one of the actions available to you - then return PAUSE.
      Observation will be the result of running those actions.

      Your available actions are:

      calculate:
      e.g. calculate: 4 * 7 / 3
      Runs a calculation and returns the number - uses Ruby so be sure to use floating point syntax if necessary

      wikipedia: (NOT IMPLEMENTED YET)
      e.g. wikipedia: Django
      Returns a summary from searching Wikipedia

      simon_blog_search: (NOT IMPLEMENTED YET)
      e.g. simon_blog_search: Django
      Search Simon's blog for that term

      Always look things up on Wikipedia if you have the opportunity to do so.

      Example session:

      Question: What is the capital of France?
      Thought: I should look up France on Wikipedia
      Action: wikipedia: France
      PAUSE

      You will be called again with this:

      Observation: France is a country. The capital is Paris.

      You then output:

      Answer: The capital of France is Paris"

    while true
      print "input -> "
      input = gets.chomp
      agent = ReAct.new(agent_prompt: prompt)

      if input.downcase == "exit"
        break
      else
        response = agent.query(input, 5)
        puts response
      end
    end
  end

main if $PROGRAM_NAME == __FILE__
