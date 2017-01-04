require "spec_helper"
require "serverspec"

package = "postfix"
service = "postfix"
conf_dir = "/etc/postfix"
ports   = [ 25 ]
extra_make_flag = "--no-print-directory"

case os[:family]
when "freebsd"
  conf_dir = "/usr/local/etc/postfix"
  extra_make_flag = ""
end

db_dir  = "#{ conf_dir }/db"
main_cf  = "#{ conf_dir }/main.cf"
master_cf = "#{ conf_dir }/master.cf"

describe package(package) do
  it { should be_installed }
end 

case os[:family]
when "freebsd"
  describe file("/etc/mail/mailer.conf") do
    it { should be_file }
    it { should be_mode 644 }
  end

  describe command("diff /etc/mail/mailer.conf /usr/local/share/postfix/mailer.conf.postfix") do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match(/^$/) }
    its(:stderr) { should match(/^$/) }
  end

  describe command("sysrc -n sendmail_enable") do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match(/^NONE$/) }
    its(:stderr) { should match(/^$/) }
  end
end

describe file(main_cf) do
  it { should be_file }
  its(:content) { should match(/^soft_bounce = yes$/) }
end

describe file(master_cf) do
  it { should be_file }
  its(:content) { should match(/^smtp\s+inet\s+n\s+-\s+n\s+-\s+-\s+smtpd$/) }
end

describe file(db_dir) do
  it { should exist }
  it { should be_directory }
  it { should be_mode 755 }
end

describe file("#{ db_dir }/Makefile") do
  it { should exist }
  it { should be_file }
end

describe command("make -C #{db_dir} -n #{ extra_make_flag }") do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match(/^(?::)?$/) } # gmake prints commands starting with "@" even when given -n
    its(:stderr) { should match(/^$/) }
end

=begin
case os[:family]
when "freebsd"
  describe file("/etc/rc.conf.d/postfix") do
    it { should be_file }
  end
end
=end

describe service(service) do
  it { should be_running }
  it { should be_enabled }
end

ports.each do |p|
  describe port(p) do
    it { should be_listening }
  end
end

describe file("#{ db_dir }/mynetworks.cidr") do
  it { should be_file }
  its(:content) { should match(/^#{ Regexp.escape("127.0.0.1") }\s*$/) }
  its(:content) { should match(/^#{ Regexp.escape("192.168.100.0/24") }\s*$/) }
  its(:content) { should match(/^#{ Regexp.escape("192.168.101.0/24") }\s*$/) }
end

describe file("#{ db_dir }/hello_access.hash") do
  it { should be_file }
  its(:content) { should match(/^localhost\s+reject$/) }
end

describe file("#{ db_dir }/hello_access.hash.db") do
  it { should be_file }
end

describe command("postmap -q localhost #{ db_dir }/hello_access.hash") do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match(/^reject$/) }
  its(:stderr) { should match(/^$/) }
end
