import pulumi
import pulumi_digitalocean as do
import pulumi_tls as tls
import pulumi_random as random
import rails_secret_key_base as rails

config = pulumi.Config()

with open('bin/in-droplet/cloud-init', 'r') as cloud_init_file:
    cloud_init_script = cloud_init_file.read()

with open('user_data', 'r') as user_data_file:
    user_data = user_data_file.read() \
        .replace("%cloud-init-script%", cloud_init_script)

postgres_password = random.RandomPassword("cobra-postgres-password", length=16, special=False)
rails_secret_key_base = rails.RailsSecretKeyBase("cobra-key-base")

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
pulumi.export("postgres_password", postgres_password.result)
pulumi.export("rails_secret_key_base", rails_secret_key_base.result)
pulumi.export("cobra_domain", config.require("cobra_domain"))
pulumi.export("nisei_domain", config.require("nisei_domain"))
