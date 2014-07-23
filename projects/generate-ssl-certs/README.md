Project Name: generate-ssl-cert
Description: Generate Self-Signed SSL Certificates or a Certificate Signing Request
Author: Gareth Coffey

Environments:
 -Currently setup to run on the local machine

Variables: 

 -Host & Group Variables

  app_name  : Defines the application the cert is for e.g. nginx, chef or csr
  ssl_gen_cn  : This should be the CN value to appear in the certificate subject e.g. CN=*.api.bskyb.com
  ssl_key_name  : The private key will be saved with this filename e.g. api.bskyb.key
  ssl_csr_name  : The CSR will be saved with this filename e.g. api.bskyb.csr
  ssl_cert_name : The CRT will be saved with this filename e.g. api.bskyb.crt

 -Per Application Variables e.g. nginx_vars.yml

  generate_cert  : If set to true, certificate tasks will be run e.g. generate_cert: true
  self_signed  : If set to true, a self-signed certificate will be created, if false, a CSR will be generated e.g. self_signed: false
  ssl_cert_dir  : Specify the directory to store generated certificates and requests e.g. /etc/openssl/certs
  ssl_key_dir  : Specify the directory to store generated private keys e.g. /etc/openssl/keys
 
 -Default Variables For All

  ssl_gen_subj  : The standard subject line to use when creating a self-signed cert or CSR, ssl_gen_cn is appended at the end
  ssl_key_bits  : The size of the private key to be generated e.g. 2048
  ssl_key_type  : The type of private key to generate when creating a self-signed cert e.g. rsa
  ssl_key_gentype  : The type of private key to generate when creating a CSR e.g. genrsa
  ssl_key_crypt  : Not currently used, but would be used to define the cypher to use e.g. -des3
