require 'spec_helper'

describe 'ssl_certificate::install', :type => :define do
  ['Debian'].each do |osfamily|
    context "on #{osfamily}" do
      let(:facts) {{ :osfamily => osfamily }}
      let(:title) { 'www.website.com' }

      describe "install 'www.website.com' certificate" do
        it { should compile.with_all_deps }
        it { should contain_class('ssl_certificate::config') }
        it { should contain_class('ssl_certificate::params') }
        it { should contain_ssl_certificate__install('www.website.com') }
        it { should contain_file('/usr/share/ca-certificates/managed_by_puppet') }
        it { should contain_file('/etc/ssl/certs/www.website.com.crt').with_source('puppet:///ssl_certificates/www.website.com/www.website.com.crt') }
        it { should contain_file('/etc/ssl/private/www.website.com.key').with_source('puppet:///ssl_certificates/www.website.com/www.website.com.key') }

        describe "and install PEM certificate" do
          let(:params) {{ :install_pem => true }}

          it { should contain_file('/etc/ssl/certs/www.website.com.pem').with_source('puppet:///ssl_certificates/www.website.com/www.website.com.pem') }
        end
        describe "and install intermediate certificate" do
          let(:params) {{ :install_intermediate => true }}

          it { should contain_file('/usr/share/ca-certificates/managed_by_puppet/www.website.com.intermediate.crt').with_source('puppet:///ssl_certificates/www.website.com/www.website.com.intermediate.crt') }
          if osfamily == 'Debian'
            it { should contain_file('/usr/share/ca-certificates/managed_by_puppet/www.website.com.intermediate.crt').that_notifies('Exec[update-ca-certificates]') }
            it { should contain_file_line('/etc/ca-certificates.conf__managed_by_puppet/www.website.com.intermediate.crt').that_requires('File[/usr/share/ca-certificates/managed_by_puppet/www.website.com.intermediate.crt]') }
            it { should contain_file_line('/etc/ca-certificates.conf__managed_by_puppet/www.website.com.intermediate.crt').that_notifies('Exec[update-ca-certificates]') }
            it { should contain_exec('update-ca-certificates') }
          end
        end

        describe "and install CA intermediate" do
          let(:params) {{ :install_ca => true }}

          it { should contain_file('/usr/share/ca-certificates/managed_by_puppet/www.website.com.ca.crt').with_source('puppet:///ssl_certificates/www.website.com/www.website.com.ca.crt') }
          if osfamily == 'Debian'
            it { should contain_file('/usr/share/ca-certificates/managed_by_puppet/www.website.com.ca.crt').that_notifies('Exec[update-ca-certificates]') }
            it { should contain_file_line('/etc/ca-certificates.conf__managed_by_puppet/www.website.com.ca.crt').that_requires('File[/usr/share/ca-certificates/managed_by_puppet/www.website.com.ca.crt]') }
            it { should contain_file_line('/etc/ca-certificates.conf__managed_by_puppet/www.website.com.ca.crt').that_notifies('Exec[update-ca-certificates]') }
            it { should contain_exec('update-ca-certificates') }
          end
        end
      end

      describe "install all 'www.website.com' certificate with custom filename and install paths" do
        let(:params) {{
          :cert_file            => 'www.crt',
          :key_file             => 'www.key',
          :pem_file             => 'www.pem',
          :intermediate_file    => 'intermediate.crt',
          :ca_file              => 'ca.crt',
          :cert_dir             => '/srv/www/www.website.com/certs',
          :pem_dir              => '/srv/www/www.website.com/certs',
          :key_dir              => '/srv/www/www.website.com/certs',
          :intermediate_dir     => '/srv/www/www.website.com/certs',
          :ca_dir               => '/srv/www/www.website.com/certs',
          :install_cert         => true,
          :install_key          => true,
          :install_pem          => true,
          :install_intermediate => true,
          :install_ca           => true,
        }}

        it { should contain_file('/srv/www/www.website.com/certs/www.crt').with_source('puppet:///ssl_certificates/www.website.com/www.crt') }
        it { should contain_file('/srv/www/www.website.com/certs/www.key').with_source('puppet:///ssl_certificates/www.website.com/www.key') }
        it { should contain_file('/srv/www/www.website.com/certs/www.pem').with_source('puppet:///ssl_certificates/www.website.com/www.pem') }
        it { should contain_file('/srv/www/www.website.com/certs/intermediate.crt').with_source('puppet:///ssl_certificates/www.website.com/intermediate.crt') }
        it { should contain_file('/srv/www/www.website.com/certs/ca.crt').with_source('puppet:///ssl_certificates/www.website.com/ca.crt') }
      end

      describe "uninstall 'www.website.com' related certificate" do
        let(:params) {{
          :install_cert         => false,
          :install_key          => false,
          :install_pem          => false,
          :install_intermediate => false,
          :install_ca           => false,
        }}

        it { should contain_file('/etc/ssl/certs/www.website.com.crt').with_ensure('absent') }
        it { should contain_file('/etc/ssl/private/www.website.com.key').with_ensure('absent') }
        it { should contain_file('/etc/ssl/certs/www.website.com.pem').with_ensure('absent') }
        it { should contain_file('/usr/share/ca-certificates/managed_by_puppet/www.website.com.intermediate.crt').with_ensure('absent') }
        it { should contain_file('/usr/share/ca-certificates/managed_by_puppet/www.website.com.ca.crt').with_ensure('absent') }
        if osfamily == 'Debian'
          it { should contain_file('/usr/share/ca-certificates/managed_by_puppet/www.website.com.intermediate.crt').that_notifies('Exec[update-ca-certificates]') }
          it { should contain_file('/usr/share/ca-certificates/managed_by_puppet/www.website.com.ca.crt').that_notifies('Exec[update-ca-certificates]') }
          it { should contain_file_line('/etc/ca-certificates.conf__managed_by_puppet/www.website.com.intermediate.crt').that_notifies('Exec[update-ca-certificates]') }
          it { should contain_file_line('/etc/ca-certificates.conf__managed_by_puppet/www.website.com.ca.crt').that_notifies('Exec[update-ca-certificates]') }
          it { should contain_exec('update-ca-certificates') }
        end
      end
    end
  end

  context 'on unsupported operating system' do
    describe "install 'www.website.com' certificate" do
      let(:facts) {{
        :osfamily        => 'Solaris',
        :operatingsystem => 'Nexenta',
      }}
      let(:title) { 'www.website.com' }

      it { expect { should contain_ssl_certificate__install('www.website.com') }.to raise_error(Puppet::Error, /Nexenta not supported/) }
    end
  end
end
