require "spec_helper"

class ServiceNotReady < StandardError
end

sleep 10 if ENV["JENKINS_HOME"]

context "after provisioning finished" do
  describe server(:client1) do
    it "should be able to ping server" do
      result = current_server.ssh_exec("ping -c 1 #{server(:server1).server.address} && echo OK")
      expect(result).to match(/OK/)
    end

    it "sends a message to vagrant@server1" do
      result = current_server.ssh_exec("echo test | mail -s test vagrant@server1.virtualbox.reallyenglish.com && echo OK")
      expect(result).to match(/OK/)
    end
  end

  describe server(:server1) do
    it "should be able to ping client" do
      result = current_server.ssh_exec("ping -c 1 #{server(:client1).server.address} && echo OK")
      expect(result).to match(/OK/)
    end

    describe "mailq" do
      it "is empty" do
        result = current_server.ssh_exec("mailq")
        expect(result).to match(/^Mail queue is empty$/)
      end
    end

    describe "maillog" do
      it "logs local(8) delivered to mailbox" do
        result = current_server.ssh_exec("sudo cat /var/log/maillog | grep 'postfix\/local'")
        expect(result).to match(%r{postfix/local\[\d+\]: [0-9A-Z]+: to=<vagrant@server1\.virtualbox\.reallyenglish\.com>, relay=local, .* status=sent \(delivered to mailbox\)$})
      end
    end
  end
end
