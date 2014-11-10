# == Class ssl_certificate::params
#
# This class is meant to be called from ssl_certificate
# It sets variables according to platform
#
class ssl_certificate::params {
  case $::osfamily {
    'Debian': {
      $cert_dir = '/etc/ssl/certs'
      $key_dir = '/etc/ssl/private'
      $ca_dir = '/usr/share/ca-certificates'
    }
    default: {
      fail("${::operatingsystem} not supported")
    }
  }
}
