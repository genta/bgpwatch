#!/usr/local/bin/ruby
require 'rubygems'
require 'metaid'

#
# Attribute module. The source of the meta-programming.
#
module Attributes
  def attributes(*params)
    return @attributes if params.empty?

    params.each do |attr_name|
      attr_accessor attr_name
      meta_def(attr_name) do |value|
        traversally_new = lambda {|item|
          if item.is_a?(Array) then
            return item.map {|val| traversally_new.call(val) }
          else
            return item.is_a?(Class) ? item.new : item
          end
        }
        value = traversally_new.call(value)

        @attributes ||= {}
        @attributes[attr_name] = value
      end
    end

    class_def(:initialize) do
      init_attributes
    end
    class_def(:init_attributes) do
      self.class.attributes.each do |key, value|
        instance_variable_set("@#{key}", value)
        value.owner = self if value.respond_to?(:owner=)
      end
    end
  end
end

module Runnable
  def run
    run_attributes
  end

  def shutdown
    shutdown_attributes
  end

  private

  def send_attributes(*message)
    method, *args = message
    self.class.attributes.each do |name, obj|
      if obj.is_a?(Array) then
        obj.each {|o| o.send(*message) if o.respond_to? method }
      else
        obj.send(*message) if obj.respond_to? method
      end
    end
  end

  def run_attributes
    return unless self.class.respond_to? :attributes
    send_attributes(:run)
  end

  def shutdown_attributes
    return unless self.class.respond_to? :attributes
    send_attributes(:shutdown)
  end
end
