#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with ssl_certificate](#setup)
    * [What ssl_certificate affects](#what-ssl_certificate-affects)
    * [Beginning with ssl_certificate](#beginning-with-ssl_certificate)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

This is a very basic module to deploy SSL certificates from a puppet master to the "correct" (read "OS-specific default") or custom defined path.

What this module will do:

- Install SSL certificates that already exist on the Puppet master on Puppet agents.
- Install certificates in the OS-family specific "default" path unless a directory is specified.

What this module will not do:

- Create self-signed certificates or certificate signing requests (CSRs) using OpenSSL.
- Create/Convert certificates based on existing certificiates.
- Manage OpenSSL versions.

The idea is that if you are creating/converting certificates, this is generally a once off task that is then checked into your SCM.  Once you have a new certificate, you check it out to the custom mount point (by default `/etc/puppet/files/ssl_certificates`) and it is then available to distribute to your Puppet nodes.

## Module Description

Sometimes you do not have the luxury of allowing of your Internet facing servers access to your local git instance; this module aims to solve that problem by making SSL certificates available to your client using a [custom mount point](https://docs.puppetlabs.com/guides/file_serving.html#serving-files-from-custom-mount-points).

Without specifying any install paths, the define will push certificates to the default path per OS-family, but this is configurable.  It will also install any CA or intermediary certificates to the system certificate database if specified.

Default paths used (based on OS-family):

- Debian:
    - certificates install to `/etc/ssl/certs`
    - keys install to `/etc/ssl/private`
    - CA and intermediary install to `/usr/share/ca-certificates`

More OS-family defaults to be added in the future!

## Setup

### What ssl_certificate affects

Not an awful lot at this time.  It will push certificates to the path specified and at most attempt to install them to the system certificate database.  On Debian based systems, the certificate is installed and imported using the ["SSL Certificates for Server Use"](https://help.ubuntu.com/community/OpenSSL#SSL_Certificates_for_Server_Use) method defined on the Ubuntu community wiki.

### Beginning with ssl_certificate

To use this define you will need to have an "ssl_certificate" custom file server mount point configured.  This is a manual step at the moment, but is pretty straight forward configure and can be done by adding the following to your /etc/puppet/fileserver.conf:

```
[ssl_certificates]
    path /etc/puppet/files/ssl_certificates
    allow *
```
You can limit access via the `allow` statement, but that is out of the scope of this README.  Please see the custom mount point documetation](https://docs.puppetlabs.com/guides/file_serving.html#serving-files-from-custom-mount-points) for more information.

Once the custom mount point have been created, check out your SSL certificates to the `/etc/puppet/files/ssl_certificates` directory from your preferred SCM of choice and ensure the files are readable by your webserver (this can be done by running `netstat -anp | grep 8140` and taking note of the user in the last column.  The `ssl_certificates` directory does not need to be in this path, you are free to check it out another location but you will need to ensure the webserver user can read the files in order to distribute them to Puppet clients.

Automatic configuration of the custom mount point will be addressed in a future version of this module but as it's a once off setup and quick to do, it has not yet been implemented.

## Usage

### The `ssl_certificate::install` define

If using the default parameters, the module expects the following directory below.  In this example, the first directory is using the default/expected layout, the second is using files that will need to be specified (as shown in examples below).

```
/etc/puppet/files/ssl_certificates
├── certificate1
│   ├── certificate1.ca.crt
│   ├── certificate1.crt
│   ├── certificate1.intermediate.crt
│   └── certificate1.key
└── domain.com
    ├── ca.crt
    ├── shop.crt
    ├── intermediate.crt
    └── shop.key
```

The define name needs to match the directory name in the ssl_certificates file server mount point that contains those certificates - in our example above this means the name can be either `certificate` or `domain.com`.

To deploy a certificate and key to the default location when the files are in the expected format, use the following syntax:

```puppet
ssl_certificate::install { 'certicate1': }
```

To define custom certificate and key names and install the certificates to a location, use the following syntax:

```puppet
ssl_certificate::install { 'domain.com':
  cert     => 'shop.crt',
  key      => 'shop.key',
  cert_dir => '/srv/www/shop.domain.com/certs',
  key_dir  => '/srv/www/shop.domain.com/certs'
}
```

It is also possible to install root and intermediary CA certificates, be sure to set `install_ca` and `install_intermediate` to `true` and specify the directories if required:

```puppet
ssl_certificate::install { 'domain.com':
  intermediate         => 'intermediate.crt',
  ca                   => 'ca.crt',
  intermediate_dir     => '/srv/www/shop.domain.com/certs'.
  ca_dir               => '/srv/www/shop.domain.com/certs'
  install_intermediate => true,
  install_ca           => true
}
```

To install the root and intermediary CA certificates when in the expected format, you only need to set the `install_intermediate` and/or `install_ca` paramaters to true, as below:

```puppet
ssl_certificate::install { 'certificate1':
  install_intermediate => true,
  install_ca           => true
}
```

#### Parameters

##### `cert`
Set this to specify the filename of the certificate if it is not in expected format.  Defaults to `"${name}.crt"`.

##### `key`
Set this to specify the filename of the key if it is not in expected format.  Defaults to `"${name}.key"`.

##### `intermediate`
Set this to specify the filename of the intermediate certificate if it is not in expected format.  Defaults to `"${name}.intermediate.crt"`.

##### `ca`
Set this to specify the filename of the CA certificate if it is not in expected format.  Defaults to `"${name}.ca.crt"`.

##### `cert_dir`
Set this to specify here to install the certificate.  Defaults to OS-family specific path.

##### `key_dir`
Set this to specify here to install the certificate key.  Defaults to OS-family specific path.

##### `intermediate_dir`
Set this to specify here to install the intermediate CA certificate.  Defaults to OS-family specific path.

##### `ca_dir`
Set this to specify here to install the root CA certificate.  Defaults to OS-family specific path.

##### `install_cert`
Set to true to install a certificate.  Defaults to 'true'.

##### `install_key`
Set to true to install a certificate key.  Defaults to 'true'.

##### `install_intermediate`
Set to true to install an intermediate CA certificiate.  Defaults to 'false'.

##### `install_ca`
Set to true to install a root CA certificate.  Defaults to 'false'.

## Reference

Here, list the classes, types, providers, facts, etc contained in your module. This section should include all of the under-the-hood workings of your module so people know what the module is touching on their system but don't need to mess with things. (We are working on automating this section!)

### Classes

#### Public Defines

* `ssl_certificate::install`: Installs SSL certificates from a Puppet fileserver mount point to your nodes.

#### Private Classes

* `ownCloud::params`: Manages ssl_certificate operating system specific parameters.

## Limitations

This module has been tested on the following Operating Systems:

* Ubuntu 12.04 Precise
* Ubuntu 14.04 Trusty

## Development

This module was created out of necessity as there wasn't another similar that performs this basic function.  Pull requests and/or suggestions to enhance it are welcome, please see the [contributing guidelines](https://github.com/shoekstra/puppet-owncloud/blob/develop/CONTRIBUTING.md) if you with to contribute.

In the pipeline:

* Add default paths for other OS-families.
* Automate configuration of `/etc/puppet/fileserver.conf`.
