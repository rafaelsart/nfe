
module NFe
	class Service
		METHODS = {
      nfe_status_servico_nf2: "NfeStatusServico2",
      nfe_autorizacao_lote: "NfeAutorizacao",
    }

    def self.status_servico
    	data = {
	      consStatServ: {
	        :@xmlns => "http://www.portalfiscal.inf.br/nfe",
	        :@versao => NFe.configuration.versao,
	        tpAmb: NFe.configuration.tpAmb,
	        cUF: NFe.configuration.cUF,
	        xServ: "STATUS",
	      },
	    }
      self.request(:nfe_status_servico_nf2, data)
    end

    def self.autorizacao(data)
    	message = sign_nfe(data)
    	request(:nfe_autorizacao_lote, message)
    end


    private

    def self.request(operation, message)
    	nfe_service = NFe::WebService.new NFe.configuration.wdsl_url(operation)
      nfe_service.call operation, header(operation), message
    rescue Savon::Error
    end

    def self.header(operation)
      {
        "nfeCabecMsg" => {
          :@xmlns => "http://www.portalfiscal.inf.br/nfe/wsdl/#{METHODS[operation]}",
          "cUF" => NFe.configuration.cUF,
          "versaoDados" => NFe.configuration.versao
        }, 
      }
  	end

  	def self.certificado
    	OpenSSL::PKCS12.new(File.read(NFe.configuration.pfx_path), NFe.configuration.cert_passwd)
    end

  	def self.sign_nfe(xml)
	    xml = Nokogiri::XML(xml.to_s, &:noblanks)
	    chave_acesso = xml.css("infNFe").first["Id"]
	    xml_canon = xml.xpath("//xmlns:infNFe", "xmlns" => "http://www.portalfiscal.inf.br/nfe").first.canonicalize(Nokogiri::XML::XML_C14N_EXCLUSIVE_1_0)
	    xml_digest = Base64.encode64(OpenSSL::Digest::SHA1.digest(xml_canon)).strip
	    signature = Nokogiri::XML::Node.new('Signature', xml)
	    signature.default_namespace = 'http://www.w3.org/2000/09/xmldsig#'
	    xml.xpath("//xmlns:NFe", "xmlns" => "http://www.portalfiscal.inf.br/nfe").first.add_child(signature)
	    signature_info = Nokogiri::XML::Node.new('SignedInfo', xml)
	    child_node = Nokogiri::XML::Node.new('CanonicalizationMethod', xml)
	    child_node['Algorithm'] = 'http://www.w3.org/TR/2001/REC-xml-c14n-20010315'
	    signature_info.add_child child_node
	    child_node = Nokogiri::XML::Node.new('SignatureMethod', xml)
	    child_node['Algorithm'] = 'http://www.w3.org/2000/09/xmldsig#rsa-sha1'
	    signature_info.add_child child_node
	    reference = Nokogiri::XML::Node.new('Reference', xml)
	    reference['URI'] = chave_acesso
	    transforms = Nokogiri::XML::Node.new('Transforms', xml)
	    child_node  = Nokogiri::XML::Node.new('Transform', xml)
	    child_node['Algorithm'] = 'http://www.w3.org/2000/09/xmldsig#enveloped-signature'
	    transforms.add_child child_node
	    child_node  = Nokogiri::XML::Node.new('Transform', xml)
	    child_node['Algorithm'] = 'http://www.w3.org/TR/2001/REC-xml-c14n-20010315'
	    transforms.add_child child_node
	    reference.add_child transforms
	    child_node  = Nokogiri::XML::Node.new('DigestMethod', xml)
	    child_node['Algorithm'] = 'http://www.w3.org/2000/09/xmldsig#sha1'
	    reference.add_child child_node
	    child_node  = Nokogiri::XML::Node.new('DigestValue', xml)
	    child_node.content = xml_digest
	    reference.add_child child_node
	    signature_info.add_child reference
	    signature.add_child signature_info
	    sign_canon = signature_info.canonicalize(Nokogiri::XML::XML_C14N_EXCLUSIVE_1_0)
	    signature_hash = certificado.key.sign(OpenSSL::Digest::SHA1.new, sign_canon)
	    signature_value = Base64.encode64( signature_hash ).gsub("\n", '')
	    child_node = Nokogiri::XML::Node.new('SignatureValue', xml)
	    child_node.content = signature_value
	    signature.add_child child_node
	    key_info = Nokogiri::XML::Node.new('KeyInfo', xml)
	    x509_data = Nokogiri::XML::Node.new('X509Data', xml)
	    x509_certificate = Nokogiri::XML::Node.new('X509Certificate', xml)
	    x509_certificate.content = certificado.certificate.to_s.gsub(/\-\-\-\-\-[A-Z]+ CERTIFICATE\-\-\-\-\-/, "").gsub(/\n/,"")
	    x509_data.add_child x509_certificate
	    key_info.add_child x509_data
	    signature.add_child key_info
	    xml.xpath("//xmlns:NFe", "xmlns" => "http://www.portalfiscal.inf.br/nfe").first.add_child signature
	    xml.canonicalize(Nokogiri::XML::XML_C14N_EXCLUSIVE_1_0)
	  end

	end
end