require 'spec_helper'

describe 'ssl_certificate::install', :type => :define do
  ['Debian'].each do |osfamily|
    context "on #{osfamily}" do
      let(:facts) {{ :osfamily => osfamily }}
      let(:title) { 'www.website.com' }

      describe "install 'www.website.com' certificate" do
        it { should compile.with_all_deps }
        it { should contain_class('ssl_certificate::params') }
        it { should contain_ssl_certificate__install('www.website.com') }
        it { should contain_file('/etc/ssl/certs/www.website.com.crt') }
        it { should contain_file('/etc/ssl/private/www.website.com.key') }

        describe "and install intermediate certificate" do
          let(:params) {{ :install_intermediate => true }}

          it { should contain_file('/usr/share/ca-certificates/www.website.com.intermediate.crt') }
          it { should contain_exec('dpkg-reconfigure ca-certificates').that_comes_before('Exec[update-ca-certificates]') }
          it { should contain_exec('update-ca-certificates') }
        end

        describe "and install CA intermediate" do
          let(:params) {{ :install_ca => true }}

          it { should contain_file('/usr/share/ca-certificates/www.website.com.ca.crt') }

          it { should contain_exec('dpkg-reconfigure ca-certificates').that_comes_before('Exec[update-ca-certificates]') }
          it { should contain_exec('update-ca-certificates') }
        end
      end

      describe "install 'www.website.com' certificate with custom filename and install paths" do
        let(:params) {{
          :cert                 => "www.crt",
          :key                  => "www.key",
          :intermediate         => "intermediate.crt",
          :ca                   => "ca.crt",
          :cert_dir             => '/srv/www/www.website.com/certs',
          :key_dir              => '/srv/www/www.website.com/certs',
          :intermediate_dir     => '/srv/www/www.website.com/certs',
          :ca_dir               => '/srv/www/www.website.com/certs',
          :install_cert         => true,
          :install_key          => true,
          :install_intermediate => true,
          :install_ca           => true,
        }}

        it { should contain_file('/srv/www/www.website.com/certs/www.crt') }
        it { should contain_file('/srv/www/www.website.com/certs/www.key') }
        it { should contain_file('/srv/www/www.website.com/certs/intermediate.crt') }
        it { should contain_file('/srv/www/www.website.com/certs/ca.crt') }
        it { should contain_exec('dpkg-reconfigure ca-certificates').that_comes_before('Exec[update-ca-certificates]') }
        it { should contain_exec('update-ca-certificates') }
      end

      describe "uninstall 'www.website.com' related certificate" do
        let(:params) {{
          :install_cert         => false,
          :install_key          => false,
          :install_intermediate => false,
          :install_ca           => false,
        }}

        it { should contain_file('/etc/ssl/certs/www.website.com.crt').with_ensure('absent') }
        it { should contain_file('/etc/ssl/private/www.website.com.key').with_ensure('absent') }
        it { should contain_file('/usr/share/ca-certificates/www.website.com.intermediate.crt').with_ensure('absent') }
        it { should contain_file('/usr/share/ca-certificates/www.website.com.ca.crt').with_ensure('absent') }
        it { should contain_exec('dpkg-reconfigure ca-certificates').that_comes_before('Exec[update-ca-certificates]') }
        it { should contain_exec('update-ca-certificates') }
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
