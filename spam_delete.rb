# coding: utf-8
require 'twitter'
require 'yaml'
require 'pry'

class SpamDelete
  def initialize
    @keys = Hash.new
    puts 'Please Enter Your KEYS.'
    print 'consumer_key: '
    @keys['key'] = gets.chomp
    print 'consumer_secret: '
    @keys['secret'] = gets.chomp
    print 'access_token: '
    @keys['token'] = gets.chomp
    print 'access_token_secret: '
    @keys['token_secret'] = gets.chomp
    puts 'Please Enter Target Message.'
    print 'text: '
    @target = gets.chomp

    connect_twitter
  end

  def connect_twitter
    @conn = Twitter::REST::Client.new do |config|
      config.consumer_key = @keys['key']
      config.consumer_secret = @keys['secret']
      config.access_token = @keys['token']
      config.access_token_secret = @keys['token_secret']
    end

    tweets = @conn.user_timeline(count: 200)
    tweets.each do |tweet|
      if tweet.text.include?(@target)
        @conn.destroy_status(tweet)
      end
    end
    puts 'Spam tweet removed in recent 200 tweets.'
  end
end

SpamDelete.new