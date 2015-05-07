$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'nfe/web_service'
require 'nfe/service'

module NFe
  class Configuration
    attr_accessor :versao, :uf, :ambiente, :cert_path, :key_path, :ca_path, :cert_passwd, :pfx_path

    def initialize
      @versao = "1.0"
    end

    def cUF
	  	CODIGOS_ESTADOS[@uf.upcase]
	  end

	  def tpAmb
	  	TIPOS_AMBIENTE[@ambiente.upcase]
	  end
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  CODIGOS_ESTADOS = {
		:RO => '11',
		:AC => '12',
		:AM => '13',
		:RR => '14',
		:PA => '15',
		:AP => '16',
		:TO => '17',
		:MA => '21',
		:PI => '22',
		:CE => '23',
		:RN => '24',
		:PB => '25',
		:PE => '26',
		:AL => '27',
		:SE => '28',
		:BA => '29',
		:MG => '31',
		:ES => '32',
		:RJ => '33',
		:SP => '35',
		:PR => '41',
		:SC => '42',
		:RS => '43',
		:MS => '50',
		:MT => '51',
		:GO => '52',
		:DF => '53',
	}.freeze

	TIPOS_AMBIENTE = {
    :PRODUCAO 		=> 1,
    :HOMOLOGACAO 	=> 2
  }.freeze

end