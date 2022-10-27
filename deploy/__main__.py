import pulumi
import pulumi_digitalocean as do
import pulumi_tls as tls
import os

config = pulumi.Config()

with open('user_data', 'r') as f:
    user_data = f.read() \
        .replace("${branch}", config.get("branch", "main")) \
        .replace("${fork}", config.get("fork", "Project-NISEI")) \
        .replace("${repository}", config.get("repository", "cobra"))

private_key = tls.PrivateKey("cobra-key", algorithm="RSA")
ssh_key = do.SshKey("cobra-ssh-key", public_key=private_key.public_key_openssh)

do.Droplet(
    resource_name="cobra",
    image="ubuntu-22-04-x64",
    region=config.get("region", "lon1"),
    size=config.get("size", "s-1vcpu-1gb"),
    user_data=user_data,
    ssh_keys=[ssh_key.fingerprint])


def write_private_key(key):
    with os.fdopen(os.open("id_cobra_rsa", os.O_WRONLY | os.O_CREAT, 0o600), "w") as file:
        file.write(key)


private_key.private_key_openssh.apply(write_private_key)
