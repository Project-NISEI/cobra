import pulumi
import pulumi_digitalocean as do
import pulumi_tls as tls

config = pulumi.Config()

with open('user_data', 'r') as user_data_file:
    user_data = user_data_file.read()

private_key = tls.PrivateKey("cobra-key", algorithm="RSA")
ssh_key = do.SshKey("cobra-ssh-key", public_key=private_key.public_key_openssh)

droplet = do.Droplet(
    resource_name="cobra",
    image="ubuntu-22-04-x64",
    region=config.get("region", "lon1"),
    size=config.get("size", "s-1vcpu-1gb"),
    user_data=user_data,
    ssh_keys=[ssh_key.fingerprint])


pulumi.export("droplet_public_ip", droplet.ipv4_address)
pulumi.export("private_key_openssh", private_key.private_key_openssh)
