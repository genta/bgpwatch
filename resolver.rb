require 'delegate'

# still broken

#
# ASN <-> nick resolver
#
class Resolver < SimpleDelegator
  extend Attributes
  include Runnable
  attributes :file

  def initailize
    init_attributes
    super(Hash.new)
  end

  def open
    x = YAML.load_file(@file)
    pp [:self_is, self, :and_file_is, @file]
    pp [:x, x, :x_class, x.class]
    pp self.methods
    self.replace(YAML.load_file(@file))
  end

  def flush
    YAML.dump(self, File::open('/tmp/myresolver.db', 'w'))
  end

  def close
    flush
  end

  def run
    pp [:run_i_am, self]
    open
    puts 'resolver openned'
    pp self
    pp @file
    pp self[64512]
  end

  def shutdown
    close
  end
end
