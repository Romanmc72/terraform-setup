# Terraform

I want to track all of the projects that I create in AWS using a modern infrastructure as code approach so I will do that here.

## Using this code

This will probably be rearranged multiple times throughout its lifecycle, but each folder here will represent a distinct subset of resources that are related or are part of a distinct project or something. Again, it will change over time so really just follow the individual `README.md` in each folder to figure out what it is all about.

Pretty much everything is getting to the `main.tf` file and running the following:

```bash
terraform init
terraform apply -var region=us-east-1
```

There is certainly a chance to script the whole thing but it is so simple at this point I do not want to over engineer it too much.
