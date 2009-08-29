#!/usr/local/bin/ruby
require 'rubygems'
require 'pp'
require 'modules'
require 'forwardable'

#
# ASN <-> nick resolver
#
class Resolver
  extend Attributes
  extend Forwardable
  include Runnable

  attributes :file
  attr_accessor :obj
  def_delegators :@obj, :[], :[]=

  def self.readonly
    class_def(:flush) do 
      raise RuntimeError, "Forbidden: Resolver marked as readonly."
    end
  end


  def initialize
    init_attributes
    @obj = Hash.new
  end

  def open
    begin
      @obj.replace(YAML.load_file(@file))
    rescue
    end
  end

  def flush
    File::open(@file, 'w') {|fd| YAML.dump(self, fd) }
  end

  def close
    flush
  end

  def run
    self.open
  end

  def shutdown
    close
  end
end
__END__