# Utiliser ansible avec terraform

---

Importer la clé privée au format **pem**

Créer un fichier **terraform.tfvars** avec vos données

```
region = "us-east-1"
aws_access_key = "*****Your*aws*access*key******"
aws_secret_key = "*****Your*aws*secret*key******"
key_name = "yourkey"
private_key_path = "./yourkey.pem"
host = "EC2AnsibleTerra"
```


```
terraform init
```

```
terraform plan
```

```
terraform apply
```

---

pour installer ansible,
au lieu de passer par user_data = file("./userdata.sh"), on provisionne avec un script l'instance via remote exec



```
#run the script on remote instance
provisioner "remote-exec" {
  inline = [
    "sh /home/ec2-user/userdata.sh",
    "echo 'export PATH=\"/home/ec2-user/.local/bin:$PATH\"' >> ~/.bashrc",
    "source ~/.bashrc"
  ]
}
```



le script :

```
#! /bin/bash
echo "-------------------------------------"
echo "Upgrading python to 3.8 and installing ansible"
echo "-------------------------------------"
sudo yum update -y
sudo yum install python38 python38-virtualenv python38-pip -y
sudo pip-3.8 install --upgrade pip
pip3 install --user ansible
echo "-------------------------------------"
echo "Done"
echo "-------------------------------------"
```

dès que le script a fini d'installer ansible,
lancement du playbook via la commande ansible playbook (hosts: localhost)


