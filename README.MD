# NF-e
Gem para envio de Nota Fiscal Eletrônica

## Instalação
    gem 'nfe', github: 'moobile/nfe'

Adicione suas configurações ao arquivo `config/initializers/nfe.rb`.

```ruby
NFe.configure do |config|
  config.cert_path    = "YOUR_CERT_PATH"
  config.key_path     = "YOUR_KEY_PATH"
  config.ca_path      = "YOUR_CA_PATH"
  config.pfx_path     = "YOUR_PFX_PATH"
  config.cert_passwd  = "YOUR_CERT_PASSWORD"

  config.ambiente = :homologacao # [:producao, :homologacao]
  config.versao   = "3.10"
  config.uf       = :RJ
end
```

## Extrair chave/certificado
`openssl pkcs12 -in certificado.pfx -out cliente.pem -clcerts -nokeys -nodes`

`openssl pkcs12 -in certificado.pfx -out chave.pem -nocerts -nodes`

`openssl pkcs12 -in certificado.pfx -out ca.pem -cacerts -nokeys -nodes`


## Exemplo de uso
    response = NFe::Service.status_servico
