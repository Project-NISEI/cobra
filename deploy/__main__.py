import pulumi
import pulumi_digitalocean as do
import pulumi_tls as tls
import os

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


private_key_filename = "id_cobra_rsa_{}".format(pulumi.get_stack())
ssh_script_filename = "ssh-cobra-{}".format(pulumi.get_stack())


def write_with_permissions(filename, permissions, body):
    with os.fdopen(os.open(filename, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, permissions), "w") as file:
        file.write(body)


def write_private_key(key):
    write_with_permissions(private_key_filename, 0o600, key)


def write_connect_script(ip):
    with open('ssh-template', 'r') as f:
        ssh_script = f.read() \
            .replace("%private_key_filename%", private_key_filename) \
            .replace("%instance_ip%", ip)
    write_with_permissions(ssh_script_filename, 0o700, ssh_script)


private_key.private_key_openssh.apply(write_private_key)
droplet.ipv4_address.apply(write_connect_script)
