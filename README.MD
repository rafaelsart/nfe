# NF-e
Gem para envio de Nota Fiscal Eletrônica

## Instalação
    gem 'nfe', github: 'moobile/nfe'

Adicione suas configurações ao arquivo `config/initializers/nfe.rb`.

```ruby
NFe.configure do |config|
  config.cert_path 		= "YOUR_CERT_PATH"
  config.key_path 		= "YOUR_KEY_PATH"
  config.ca_path 		= "YOUR_CA_PATH"
  config.pfx_path 		= "YOUR_PFX_PATH"
  config.cert_passwd	= "YOUR_CERT_PASSWORD"

  config.ambiente = :homologacao # [:producao, :homologacao]
  config.versao = "3.10"
  config.uf = :RJ
end
```

## Exemplo de uso
    response = NFe::Service.status_servico
