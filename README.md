## Demo Project using EC2 instances, Load Balancer and Auto Scaling on AWS 

This repository deploys a basic web app [Pizza Luvrs by Ryan H. Lewis](https://github.com/ryanmurakami/pizza-luvrs)
on AWS EC2 instances with Load Balancing and Auto Scaling

### To get started

- Add a `env.tfvars` file to the "config/terraform" directory and 
  populate the variables from the `env.tfvars.example` file
- Install and configure AWS Vault to use the `make` commands in the `Makefile`
  located at the root level of the Terraform directory