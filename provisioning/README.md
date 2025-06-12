# Ansible Collections

Using the funidata.infra collection

    ansible-galaxy collection install -r requirements.yml

Required Ansible vault password secrets across all environments:

- `vault-password.secret`
- `vault-password-oodikone.secret`
- `vault-password-prod.secret`

You should be familiar with

- https://github.com/funidata/otm/blob/master/provisioning/docs/aws.md
- https://github.com/funidata/otm/blob/master/provisioning/docs/ansible.md

# Oodikone playbooks

## aws-oodikone-install.yml

```
AWS_CONFIG_FILE=aws-sso.config ANSIBLE_VAULT_PASSWORD_FILE=vault-password.secret ansible-playbook --diff -i aws-oodikone-dev.aws_ec2.yml -i aws-oodikone.ini aws-oodikone-install.yml --check
```

## oodikone-postgres-database.yml - initialize db

```
AWS_CONFIG_FILE=aws-sso.config ANSIBLE_VAULT_PASSWORD_FILE=vault-password.secret ansible-playbook --diff -i aws-oodikone-dev.aws_ec2.yml -i aws-oodikone.ini oodikone-postgres-database.yml --check
```

## oodikone-postgres-database-restore.yml - restore dbs from dumps

```
AWS_CONFIG_FILE=aws-sso.config ANSIBLE_VAULT_PASSWORD_FILE=vault-password.secret ansible-playbook --diff -i aws-oodikone-dev.aws_ec2.yml -i aws-oodikone.ini oodikone-postgres-database-restore.yml --check
```

## oodikone-postgres-user-password.yml - create a password for postgres user

```
AWS_CONFIG_FILE=aws-sso.config ANSIBLE_VAULT_PASSWORD_FILE=vault-password.secret ansible-playbook --diff -i aws-oodikone-dev.aws_ec2.yml -i aws-oodikone.ini oodikone-postgres-user-password.yml -e oodikone_postgres_user=iirow --check
```

## oodikone-app-login-user.yml - create a user that can login to oodikone

```
AWS_CONFIG_FILE=aws-sso.config ANSIBLE_VAULT_PASSWORD_FILE=vault-password.secret ansible-playbook --diff -i aws-oodikone-dev.aws_ec2.yml -i aws-oodikone.ini oodikone-app-login-user.yml --check
```
