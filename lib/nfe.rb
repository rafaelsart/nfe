$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'nfe/web_service'
require 'nfe/service'

module NFe
  class Configuration
    attr_accessor :versao, :uf, :cert_path, :key_path, :ca_path, :cert_passwd, :pfx_path
 
    def initialize
      @versao = "1.0"
    end
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end
end