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

droplet = do.Droplet(
    resource_name="cobra",
    image="ubuntu-22-04-x64",
    region=config.get("region", "lon1"),
    size=config.get("size", "s-1vcpu-1gb"),
    user_data=user_data,
    ssh_keys=[ssh_key.fingerprint])


private_key_filename = "id_cobra_rsa_{}".format(pulumi.get_stack())
connect_script_filename = "ssh-cobra-{}.sh".format(pulumi.get_stack())


def write_private_key(key):
    with os.fdopen(os.open(private_key_filename, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600), "w") as file:
        file.write(key)


def write_connect_script(ip):
    with os.fdopen(os.open(connect_script_filename, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o700), "w") as file:
        file.write("ssh -i {} root@{}".format(private_key_filename, ip))


private_key.private_key_openssh.apply(write_private_key)
droplet.ipv4_address.apply(write_connect_script)
