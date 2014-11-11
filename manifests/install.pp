# == Define: ssl_certificate::install
#
# Puppet define to install SSL certificates and keys.
#
# === Parameters
#
# [*cert_dir*]
#   Directory where CA certificate will be installed.
#   Default based on OS-family.
#
# [*cert_file*]
#   Filename of certificate to install.
#   Defaults to define name with ".crt" extension.
#
# [*key_dir*]
#   Directory where CA certificate will be installed.
#   Default based on OS-family.
#
# [*key_file*]
#   Filename of key to install.
#   Defaults to define name with ".key" extension.
#
# [*intermediate_dir*]
#   Directory where CA certificate will be installed.
#   Default based on OS-family.
#
# [*intermediate_file*]
#   Filename of intermediate certificate to install.
#   Defaults to define name with ".intermediate.crt" extension.
#
# [*ca_dir*]
#   Directory where CA certificate will be installed.
#   Default based on OS-family.
#
# [*ca_file*]
#   Filename of CA certificate to install.
#   Defaults to define name with ".ca.crt" extension.
#
# [*install_cert*]
#   Whether to install the certificate.
#   Defaults to 'true'
#
# [*install_key*]
#   Defaults to 'true'
#
# [*install_intermediate*]
#   Defaults to 'false'
#
# [*install_ca*]
#   Defaults to 'false'
#
define ssl_certificate::install (
  $cert_file            = "${name}.crt",
  $key_file             = "${name}.key",
  $intermediate_file    = "${name}.intermediate.crt",
  $ca_file              = "${name}.ca.crt",
  $cert_dir             = undef,
  $key_dir              = undef,
  $intermediate_dir     = undef,
  $ca_dir               = undef,
  $install_cert         = true,
  $install_key          = true,
  $install_intermediate = false,
  $install_ca           = false,
) {

  require ssl_certificate::config
  include ssl_certificate::params

  validate_bool($install_cert, $install_key, $install_ca, $install_intermediate)

  # validate paths if defined.
  if $cert_dir { validate_absolute_path($cert_dir) }
  if $key_dir { validate_absolute_path($key_dir) }
  if $intermediate_dir { validate_absolute_path($intermediate_dir) }
  if $ca_dir { validate_absolute_path($ca_dir) }

  # set directories that certificates will be installed to.
  $real_cert_dir = $cert_dir ? {
    undef   => $ssl_certificate::params::cert_dir,
    default => $cert_dir
  }

  $real_key_dir = $key_dir ? {
    undef   => $ssl_certificate::params::key_dir,
    default => $key_dir
  }

  $real_intermediate_dir = $intermediate_dir ? {
    undef   => $ssl_certificate::params::ca_dir,
    default => $ca_dir
  }

  $real_ca_dir = $ca_dir ? {
    undef   => $ssl_certificate::params::ca_dir,
    default => $ca_dir
  }

  File {
    owner => 'root',
    group => 'root',
    mode  => 0600,
  }

  if $install_cert {
    file { "${real_cert_dir}/${cert_file}":,
      ensure => present,
      source => "puppet:///ssl_certificates/${name}/${cert_file}",
    }
  } else {
    file { "${real_cert_dir}/${cert_file}":,
      ensure => absent,
    }
  }

  if $install_key {
    file { "${real_key_dir}/${key_file}":
      ensure => present,
      source => "puppet:///ssl_certificates/${name}/${key_file}",
    }
  } else {
    file { "${real_key_dir}/${key_file}":
      ensure => absent,
    }
  }

  if $install_intermediate {
    file { "${real_intermediate_dir}/${intermediate_file}":
      ensure => present,
      source => "puppet:///ssl_certificates/${name}/${intermediate_file}",
    }
  } else {
    file { "${real_intermediate_dir}/${intermediate_file}":
      ensure => absent,
    }
  }

  if $install_ca {
    file { "${real_ca_dir}/${ca_file}":
      ensure => present,
      source => "puppet:///ssl_certificates/${name}/${ca_file}",
    }
  } else {
    file { "${real_ca_dir}/${ca_file}":
      ensure => absent,
    }
  }

  if $::osfamily == 'Debian' and $real_ca_dir =~ /^\/usr\/share\/ca-certificates/ or $real_intermediate_dir =~ /^\/usr\/share\/ca-certificates/ {
    $cert_conf_line_intermediate = regsubst("${real_intermediate_dir}/${intermediate_file}", '/usr/share/ca-certificates/', '')
    $cert_conf_line_ca = regsubst("${real_ca_dir}/${ca_file}", '/usr/share/ca-certificates/', '')

    if $install_intermediate {
      file_line { "/etc/ca-certificates.conf__${cert_conf_line_intermediate}":
        ensure  => present,
        line    => $cert_conf_line_intermediate,
        path    => '/etc/ca-certificates.conf',
        require => File["${real_intermediate_dir}/${intermediate_file}"],
        notify  => Exec['update-ca-certificates'],
      }
    } else {
      file_line { "/etc/ca-certificates.conf__${cert_conf_line_intermediate}":
        ensure => absent,
        line   => $cert_conf_line_intermediate,
        path   => '/etc/ca-certificates.conf',
        notify => Exec['update-ca-certificates'],
      }
    }

    if $install_ca {
      file_line { "/etc/ca-certificates.conf__${cert_conf_line_ca}":
        ensure  => present,
        line    => $cert_conf_line_ca,
        path    => '/etc/ca-certificates.conf',
        require => File["${real_ca_dir}/${ca_file}"],
        notify  => Exec['update-ca-certificates'],
      }
    } else {
      file_line { "/etc/ca-certificates.conf__${cert_conf_line_ca}":
        ensure => absent,
        line   => $cert_conf_line_ca,
        path   => '/etc/ca-certificates.conf',
        notify => Exec['update-ca-certificates'],
      }
    }

    exec { 'update-ca-certificates':
      path        => ['/bin', '/usr/bin/', '/usr/sbin'],
      refreshonly => true,
    }
  }
}
