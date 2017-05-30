require "spec_helper"
require "serverspec"

package = "postfix"
service = "postfix"
conf_dir = "/etc/postfix"
ports = [25]
aliases_file = "/etc/aliases"
aliases_default_hash = { "postmaster" => "root" }
default_user = "root"
default_group = "root"

case os[:family]
when "freebsd"
  conf_dir = "/usr/local/etc/postfix"
  default_group = "wheel"
  aliases_file = "/etc/mail/aliases"
  aliases_default_hash = { "MAILER-DAEMON" => "postmaster", "_dhcp" => "root",
                           "auditdistd" => "root", "hast" => "root" }
when "openbsd"
  default_group = "wheel"
  aliases_file = "/etc/mail/aliases"
  aliases_default_hash = { "MAILER-DAEMON" => "postmaster", "_dhcp" => "/dev/null", "_bgpd" => "/dev/null" }
when "redhat"
  aliases_default_hash = { "mailer-daemon" => "postmaster", "ftpadmin" => "ftp", "ftp-adm" => "ftp", "marketing" => "postmaster" }
end

db_dir = "#{conf_dir}/db"
main_cf = "#{conf_dir}/main.cf"
master_cf = "#{conf_dir}/master.cf"

describe package(package) do
  it { should be_installed }
end

case os[:family]
when "freebsd"
  describe file("/etc/mail/mailer.conf") do
    it { should be_file }
    it { should be_owned_by default_user }
    it { should be_grouped_into default_group }
    it { should be_mode 644 }
  end

  describe command("diff /etc/mail/mailer.conf /usr/local/share/postfix/mailer.conf.postfix") do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match(/^$/) }
    its(:stderr) { should eq "" }
  end

  describe command("sysrc -n sendmail_enable") do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match(/^NONE$/) }
    its(:stderr) { should eq "" }
  end

  describe file("/etc/periodic.conf") do
    it { should be_file }
    it { should be_owned_by default_user }
    it { should be_grouped_into default_group }
    it { should be_mode 644 }
    its(:content) { should match(/^daily_clean_hoststat_enable="NO"$/) }
    its(:content) { should match(/^daily_status_mail_rejects_enable="NO"$/) }
    its(:content) { should match(/^daily_status_include_submit_mailq="NO"$/) }
    its(:content) { should match(/^daily_submit_queuerun="NO"$/) }

    its(:content) { should_not match(/^daily_clean_hoststat_enable="YES"$/) }
    its(:content) { should_not match(/^daily_status_mail_rejects_enable="YES"$/) }
    its(:content) { should_not match(/^daily_status_include_submit_mailq="YES"$/) }
    its(:content) { should_not match(/^daily_submit_queuerun="YES"$/) }
  end
end

describe file(aliases_file) do
  it { should be_file }
  it { should be_owned_by default_user }
  it { should be_grouped_into default_group }
  it { should be_mode 644 }
  its(:content) { should match(/^dave\.null:\s+root$/) }
  aliases_default_hash.each do |k, v|
    its(:content) { should_not match(/^#{Regexp.escape(k)}:\s+#{Regexp.escape(v)}$/) }
  end
end

aliases_default_hash.each do |k, v|
  describe command("postmap -q #{k} #{aliases_file}") do
    its(:exit_status) { should eq 1 }
    its(:stdout) { should_not match(/^#{Regexp.escape(v)}$/) }
    its(:stderr) { should eq "" }
  end
end

describe command("postmap -q dave.null #{aliases_file}") do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match(/^root$/) }
  its(:stderr) { should eq "" }
end

describe file(main_cf) do
  it { should be_file }
  it { should be_owned_by default_user }
  it { should be_grouped_into default_group }
  it { should be_mode 644 }
  its(:content) { should match(/^soft_bounce = yes$/) }
  its(:content) { should match(/^alias_database = #{Regexp.escape(aliases_file)}$/) } if os[:family] == "freebsd"
end

describe file(master_cf) do
  it { should be_file }
  it { should be_owned_by default_user }
  it { should be_grouped_into default_group }
  it { should be_mode 644 }
  its(:content) { should match(/^smtp\s+inet\s+n\s+-\s+n\s+-\s+-\s+smtpd$/) }
end

describe file(db_dir) do
  it { should exist }
  it { should be_directory }
  it { should be_owned_by default_user }
  it { should be_grouped_into default_group }
  it { should be_mode 755 }
end

# case os[:family]
# when "freebsd"
#   describe file("/etc/rc.conf.d/postfix") do
#     it { should be_file }
#   end
# end

describe service(service) do
  it { should be_running }
  it { should be_enabled }
end

ports.each do |p|
  describe port(p) do
    it { should be_listening }
  end
end

describe file("#{db_dir}/mynetworks.cidr") do
  it { should be_file }
  it { should be_owned_by default_user }
  it { should be_grouped_into default_group }
  it { should be_mode 644 }
  its(:content) { should match(/^#{ Regexp.escape("127.0.0.1") }\s*$/) }
  its(:content) { should match(/^#{ Regexp.escape("192.168.100.0/24") }\s*$/) }
  its(:content) { should match(/^#{ Regexp.escape("192.168.101.0/24") }\s*$/) }
end

describe file("#{db_dir}/hello_access.hash") do
  it { should be_file }
  it { should be_owned_by default_user }
  it { should be_grouped_into default_group }
  it { should be_mode 644 }
  its(:content) { should match(/^localhost\s+reject$/) }
end

describe file("#{db_dir}/hello_access.hash.db") do
  it { should be_file }
  it { should be_owned_by default_user }
  it { should be_grouped_into default_group }
  it { should be_mode 644 }
end

describe command("postmap -q localhost #{db_dir}/hello_access.hash") do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match(/^reject$/) }
  its(:stderr) { should eq "" }
end
