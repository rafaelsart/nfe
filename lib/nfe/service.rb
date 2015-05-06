
module NFe
	class Service
		METHODS = {
      nfe_status_servico_nf2: "NfeStatusServico2",
      nfe_autorizacao_lote: "NfeAutorizacao",
    }

    def initialize(wsdl)
    	@nfe_service = NFe::WebService.new wsdl
    end

    def status_servico(data)
      request(:nfe_status_servico_nf2, data)
    end

    def autorizacao(data)
    	data = sign(data)
      request(:nfe_autorizacao_lote, data)
    end


    private

    def request(operation, message)
      @nfe_service.call operation, header(operation), message
    rescue Savon::Error
    end

    def header(operation)
      {
        "nfeCabecMsg" => {
          :@xmlns => "http://www.portalfiscal.inf.br/nfe/wsdl/#{METHODS[operation]}",
          "cUF" => "33",
          "versaoDados" => "3.10"
        }, 
      }
  	end

  	def certificado
    	OpenSSL::PKCS12.new(File.read(NFe.configuration.pfx_path), NFe.configuration.cert_passwd)
    end

  	def sign(xml)
	    xml = Nokogiri::XML(xml.to_s, &:noblanks)

	    # 1. Digest Hash for all XML
	    xml_canon = xml.xpath("//xmlns:infNFe", "xmlns" => "http://www.portalfiscal.inf.br/nfe").first.canonicalize(Nokogiri::XML::XML_C14N_EXCLUSIVE_1_0)
	    xml_digest = Base64.encode64(OpenSSL::Digest::SHA1.digest(xml_canon)).strip

	    # 2. Add Signature Node
	    signature = Nokogiri::XML::Node.new('Signature', xml)
	    signature.default_namespace = 'http://www.w3.org/2000/09/xmldsig#'
	    xml.xpath("//xmlns:NFe", "xmlns" => "http://www.portalfiscal.inf.br/nfe").first.add_child(signature)

	    # 3. Add Elements to Signature Node
	    
	    # 3.1 Create Signature Info
	    signature_info = Nokogiri::XML::Node.new('SignedInfo', xml)

	    # 3.2 Add CanonicalizationMethod
	    child_node = Nokogiri::XML::Node.new('CanonicalizationMethod', xml)
	    child_node['Algorithm'] = 'http://www.w3.org/TR/2001/REC-xml-c14n-20010315'
	    signature_info.add_child child_node

	    # 3.3 Add SignatureMethod
	    child_node = Nokogiri::XML::Node.new('SignatureMethod', xml)
	    child_node['Algorithm'] = 'http://www.w3.org/2000/09/xmldsig#rsa-sha1'
	    signature_info.add_child child_node

	    # 3.4 Create Reference
	    reference = Nokogiri::XML::Node.new('Reference', xml)
	    reference['URI'] = '#NFe33150421301901000193550010000016471028037023'

	    # 3.5 Add Transforms
	    transforms = Nokogiri::XML::Node.new('Transforms', xml)

	    child_node  = Nokogiri::XML::Node.new('Transform', xml)
	    child_node['Algorithm'] = 'http://www.w3.org/2000/09/xmldsig#enveloped-signature'
	    transforms.add_child child_node

	    child_node  = Nokogiri::XML::Node.new('Transform', xml)
	    child_node['Algorithm'] = 'http://www.w3.org/TR/2001/REC-xml-c14n-20010315'
	    transforms.add_child child_node

	    reference.add_child transforms

	    # 3.6 Add Digest
	    child_node  = Nokogiri::XML::Node.new('DigestMethod', xml)
	    child_node['Algorithm'] = 'http://www.w3.org/2000/09/xmldsig#sha1'
	    reference.add_child child_node
	    
	    # 3.6 Add DigestValue
	    child_node  = Nokogiri::XML::Node.new('DigestValue', xml)
	    child_node.content = xml_digest
	    reference.add_child child_node

	    # 3.7 Add Reference and Signature Info
	    signature_info.add_child reference
	    signature.add_child signature_info

	    # 4 Sign Signature
	    sign_canon = signature_info.canonicalize(Nokogiri::XML::XML_C14N_EXCLUSIVE_1_0)
	    signature_hash = certificado.key.sign(OpenSSL::Digest::SHA1.new, sign_canon)
	    signature_value = Base64.encode64( signature_hash ).gsub("\n", '')

	    # 4.1 Add SignatureValue
	    child_node = Nokogiri::XML::Node.new('SignatureValue', xml)
	    child_node.content = signature_value
	    signature.add_child child_node

	    # 5 Create KeyInfo
	    key_info = Nokogiri::XML::Node.new('KeyInfo', xml)
	    
	    # 5.1 Add X509 Data and Certificate
	    x509_data = Nokogiri::XML::Node.new('X509Data', xml)
	    x509_certificate = Nokogiri::XML::Node.new('X509Certificate', xml)
	    x509_certificate.content = certificado.certificate.to_s.gsub(/\-\-\-\-\-[A-Z]+ CERTIFICATE\-\-\-\-\-/, "").gsub(/\n/,"")

	    x509_data.add_child x509_certificate
	    key_info.add_child x509_data

	    # 5.2 Add KeyInfo
	    signature.add_child key_info

	    # 6 Add Signature
	    xml.xpath("//xmlns:NFe", "xmlns" => "http://www.portalfiscal.inf.br/nfe").first.add_child signature

	    # Return XML
	    xml.canonicalize(Nokogiri::XML::XML_C14N_EXCLUSIVE_1_0)
	  end

	end
end