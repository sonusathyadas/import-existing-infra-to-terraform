# Building Terraform templates by importing existing resources in AWS

Terraform is a IaC (Infrastructure as  Code )  solution which helps you to define the resource configurations in a template file and create those resources in different environments such as dev, test and production. Yes, we can use Terraform to create new resources in the cloud. But what if we have some existing resources in the cloud which you have create using the Management console or CLI or some other way. What if you want to deploy a new EC2 instance to an existing VPC? 

Terraform provides a useful command to import existing resource configurations to the terraform state file and match the configuration with the cloud infrastructure. This article will help you to understand how to do it. 

## Create an EC2 instance in a custom VPC
1) Open the AWS Management Console and navigate to the VPC dashboard. Choose the region as `ap-south-1` (Mumbai).
2) Click on `Create VPC` button to start creating a new custom VPC.
3) Under the `VPC Settings`, choose `VPC only` option and provide a name tag value for VPC. Select the `IPv4 manual input` for `IPv4 CIDR block setting` and enter the IPv4 CIDR as `10.5.0.0/16`.
4) Select `No IPv6 CIDR block` for IPv6 setting. Leave other values as default and create the VPC.
5) After the VPC is being created, Click on the `Subnets` from the left panel to create subnets. Click on `Create Subnet` button and select the above created VPC from the `VPC ID` list.
6) Under the `Subnet settings`, provide the subnet name as `Subnet-1`, availability zone as `ap-south-1a` and IP CIDR as `10.5.0.0/24`. Create another subnet with name `Subnet-2`, availability zone as `ap-South-1b` and IP CIDR as `10.5.1.0/24`. Click on `Create Subnet` to create both subnets.
7) Click on the `Internet Gateways` from the left panel and create a new internet gateway with a name you prefer. Then attach the Gateway to the above created VPC.
8) Navigate to the `Route tables` and select the route table created for the above created VPC. Add a new route to the Route Table. Select destination as `0.0.0.0/0` and Target as `Internet Gateway` then select the above created internet gateway. Click on the `Save changes` button.
9) Go to the Security Groups and choose the default security group created for the above created Security Group. Edit the inbound rules in the security group and add the rules to allow SSH(22), Http(80) and RDP (3389) connection from Anywhere(0.0.0.0/0). 
10) Navigate to EC2 dashboard and click on the `Launch instance` button. Provide a name for the EC2 instnace. Choose the Windows Server type from OS images and choose `Microsoft Windows Server 2022 Base` AMI image. Select the `t2.micro` instance type and generate a new Key pair for authentication. 
11) Under the `Network Settings`, click on the `Edit` button to change the VPC and Subnet. Select the above created VPC and choose `Subnet-1`. Select `Enable` for `Auto-assign public IP` option and choose the `Select existing security group` and select the default security group created for the VPC. Leave the other values default and click on the `Launch Instance` button to create the EC2 instance.

## Import existing resources to Terraform template
1) Create a `main.tf` file in the VS Code and add the following code. 
    ```terraform
    // Provider configuration
    terraform {
     required_providers {
       aws = {
         source  = "hashicorp/aws"
         version = "~> 3.0"
       }
     }
    }
     
    provider "aws" {
     region = "ap-south-1"
    }
    ```

2) Run `terraform init` to initialize the Terraform modules. The output looks like the following 
    ```
    PS C:\Users\sonus\Desktop\terraform_import> terraform init
    
    Initializing the backend...
    
    Initializing provider plugins...
    - Finding latest version of hashicorp/aws...
    - Installing hashicorp/aws v4.45.0...
    - Installed hashicorp/aws v4.45.0 (signed by HashiCorp)
    
    Terraform has created a lock file .terraform.lock.hcl to record the provider
    selections it made above. Include this file in your version control repository
    so that Terraform can guarantee to make the same selections by default when
    you run "terraform init" in the future.
    
    Terraform has been successfully initialized!
    
    You may now begin working with Terraform. Try running "terraform plan" to see
    any changes that are required for your infrastructure. All Terraform commands
    should now work.
    
    If you ever set or change modules or backend configuration for Terraform,
    rerun this command to reinitialize your working directory. If you forget, other
    commands will detect it and remind you to do so if necessary.
    ```

3) Add the configuration for VPC in the `main.tf` file.
    ```terraform
    resource "aws_vpc" "tf_vpc" {
  
    }
    ```

4) Run the following command to update the state file with the VPC configurations. Use the VPC ID with the command.
    ```bash
    terraform import aws_vpc.tf_vpc <VPC ID>
    ```

5) This will update the statefile with the configurations of the existing VPC. But it does not update the configurations on the terraform file (`main.tf`). You need to explicitly update the attributes and its values in the terraform file.
6) Run the following command to show the human-readble terraform configuration of the VPC from the statefile into the console.
    ```bash
    terraform show
    ``` 
7) This will show the terraform configuration for the VPC in the  following format. Copy the configuration attributes of the VPC to the VPC configuration block (between { and }) in the `main.tf` 
    ```PS C:\Users\sonus\Desktop\terraform_import> terraform show
    # aws_vpc.tf_vpc:
    resource "aws_vpc" "tf_vpc" {
        arn                              = "arn:aws:ec2:ap-south-1:184620931929:vpc/vpc-0a01cb1e7b0e80142"
        assign_generated_ipv6_cidr_block = false
        cidr_block                       = "10.5.0.0/16"
        default_network_acl_id           = "acl-013f5334471fb2604"
        default_route_table_id           = "rtb-08ebc1e0132e265a6"
        default_security_group_id        = "sg-0a51a42b7ce1208c6"
        dhcp_options_id                  = "dopt-08d721da4f0cfe129"
        enable_classiclink               = false
        enable_classiclink_dns_support   = false
        enable_dns_hostnames             = false
        enable_dns_support               = true
        id                               = "vpc-0a01cb1e7b0e80142"
        instance_tenancy                 = "default"
        ipv6_netmask_length              = 0
        main_route_table_id              = "rtb-08ebc1e0132e265a6"
        owner_id                         = "184620931929"
        tags                             = {
            "Name" = "tf-vpc"
        }
        tags_all                         = {
            "Name" = "tf-vpc"
        }
    }
    
    ```
8) Update the VPC configuation with the atttributes necessary for the VPC configuration. Add only the `cidr_block`, `instance_tenancy`, `tags` and `tags_all` attributes and remove other attributes. 

    ```terraform
    resource "aws_vpc" "tf_vpc" {
      cidr_block                       = "10.5.0.0/16"
      instance_tenancy                 = "default"
      tags = {
        "Name" = "tf-vpc"
      }
      tags_all = {
        "Name" = "tf-vpc"
      }
    }
    ```

9) Now, run the `terraform plan` command to check whether the configuration matches the cloud infrstructure in the cloud.
    ```
    PS C:\Users\sonus\Desktop\terraform_import> terraform plan
    aws_vpc.tf_vpc: Refreshing state... [id=vpc-0a01cb1e7b0e80142]

    No changes. Your infrastructure matches the configuration.

    Terraform has compared your real infrastructure against your configuration and found no differences, so no changes are needed.
    ```
10) Now we can update the state file with the configurations of Subnets, internet gateway and route table. For  that define the required resource configurations in `main.tf` file.
    ```terraform    
    resource "aws_subnet" "subnet1" {
      vpc_id = aws_vpc.tf_vpc.id
    }
    
    resource "aws_subnet" "subnet2" {
      vpc_id = aws_vpc.tf_vpc.id
    }
    
    resource "aws_internet_gateway" "tf_vpc_igw" {
     vpc_id = aws_vpc.tf_vpc.id
    }
       
    resource "aws_security_group" "tf_vpc_sg" {
        vpc_id = aws_vpc.tf_vpc.id
    }
    ```

11) Run the following commands to update the resource configurations on the state file.
    ```bash
    terraform import aws_subnet.subnet1 <Subnet1 ID>
    
    terraform import aws_subnet.subnet2 <Subnet2 ID>

    terraform import aws_internet_gateway.tf_vpc_igw <InternetGateway ID>

    terraform import aws_security_group.tf_vpc_sg <SecurityGroup ID>
    ```

12) This will update the state file with the configurations of subnets, internet gateway, route table and security group. Run the `terraform show` command to display the state configurations and update necessary attributes in the `main.tf` file.
13) Update the subnet (`subnet1`) setting with the following attributes.
    ```terraform
    resource "aws_subnet" "subnet1" {
      vpc_id            = aws_vpc.tf_vpc.id
      availability_zone = "ap-south-1a"
      cidr_block = "10.5.0.0/24"
      tags = {
        "Name" = "Subnet-1"
      }
      tags_all = {
        "Name" = "Subnet-1"
      }
    }
    ```
14) Update the subnet (` subnet2`) setting with the following attributes.
    ```terraform
    resource "aws_subnet" "subnet2" {
      vpc_id            = aws_vpc.tf_vpc.id
      availability_zone = "ap-south-1b"
      cidr_block        = "10.5.1.0/24"
      tags = {
        "Name" = "Subnet-2"
      }
      tags_all = {
        "Name" = "Subnet-2"
      }
    }
    ```
15) Update the internet gateway (`tf_vpc_igw`) settings with the following attributes.
    ```terraform
    resource "aws_internet_gateway" "tf_vpc_igw" {
      vpc_id = aws_vpc.tf_vpc.id
      tags = {
        "Name" = "tf-vpc-igw"
      }
      tags_all = {
        "Name" = "tf-vpc-igw"
      }
    }
    ```

16) Update the security group (`tf_vpc_sg`) settings with the following attributes.
    ```terraform
    resource "aws_security_group" "tf_vpc_sg" {
      vpc_id      = aws_vpc.tf_vpc.id
      description = "default VPC security group"
      egress = [
        {
          cidr_blocks = [
            "0.0.0.0/0",
          ]
          from_port        = 0
          protocol         = "-1"
          to_port          = 0
        },
      ]
      ingress = [
        {
          cidr_blocks = [
            "0.0.0.0/0",
          ]
          from_port        = 22
          protocol         = "tcp"
          to_port          = 22
        },
        {
          cidr_blocks = [
            "0.0.0.0/0",
          ]
          from_port        = 3389
          protocol         = "tcp"
          to_port          = 3389
        },
        {
          cidr_blocks = [
            "0.0.0.0/0",
          ]
          from_port        = 80
          protocol         = "tcp"
          to_port          = 80
        },
        {
          cidr_blocks      = []
          from_port        = 0
          protocol         = "-1"
          to_port          = 0
        },
      ]
      name = "default"
    }
    ```
17) Run the `terraform plan` command to check whether the infrstructure matches the configuration.
    ```
    PS C:\Users\sonus\Desktop\terraform_import> terraform plan
    aws_vpc.tf_vpc: Refreshing state... [id=vpc-0a01cb1e7b0e80142]
    aws_internet_gateway.tf_vpc_igw: Refreshing state... [id=igw-06fce2afc72eea089]
    aws_subnet.subnet2: Refreshing state... [id=subnet-0b17c269c8ef3de7c]
    aws_subnet.subnet1: Refreshing state... [id=subnet-00b66ce965ee0b22f]
    aws_security_group.tf_vpc_sg: Refreshing state... [id=sg-0a51a42b7ce1208c6]
    
    No changes. Your infrastructure matches the configuration.
    
    Terraform has compared your real infrastructure against your configuration and found no differences, so no changes are needed.
    ```

18) Now, can update the EC2 instance configuration to the terraform file and import the infrastructure configurations to state file. Add the following resource configuration in `main.tf` file.
    ```
    resource "aws_instance" "vm1" {
      
    }
    
    ```
19) Run the `terraform import` with the existing EC2 instance id to update the state file with the EC2 configurations.
    ```bash
    terraform import aws_instance.vm1 <Instance ID>
    ```

20) This will update the state file with EC2 configurations. Show the state file configurations in console and update the settings in `main.tf` EC2 configuration to match the infrastructure with the terraform configurations.
    ```
    resource "aws_instance" "vm1" {
      ami                          = "ami-08bd8e5c51334492e"
      associate_public_ip_address  = true
      availability_zone            = "ap-south-1a"
      instance_type                = "t2.micro"
      subnet_id                    = aws_subnet.subnet1.id
    }
    ```

21) Run the `terraform plan` to check the terraform configurations matches the infrastructure or not.
    ```bash
    PS C:\Users\sonus\Desktop\terraform_import> terraform plan
    aws_vpc.tf_vpc: Refreshing state... [id=vpc-0a01cb1e7b0e80142]
    aws_internet_gateway.tf_vpc_igw: Refreshing state... [id=igw-06fce2afc72eea089]
    aws_subnet.subnet2: Refreshing state... [id=subnet-0b17c269c8ef3de7c]
    aws_subnet.subnet1: Refreshing state... [id=subnet-00b66ce965ee0b22f]
    aws_security_group.tf_vpc_sg: Refreshing state... [id=sg-0a51a42b7ce1208c6]
    aws_instance.vm1: Refreshing state... [id=i-0f148090732ec2e4a]
    
    No changes. Your infrastructure matches the configuration.
    
    Terraform has compared your real infrastructure against your configuration and found no differences, so no changes are needed.
    ```

## Deploy a new EC2 instance to the existing VPC.
1) Add the new EC2 configuration to the `main.tf` file.
    ```terraform
    resource "aws_instance" "vm2" {
      ami                         = "ami-08bd8e5c51334492e"
      associate_public_ip_address = true
      availability_zone           = "ap-south-1a"
      instance_type               = "t2.micro"
      subnet_id                   = aws_subnet.subnet1.id
      key_name                    = "MyWinKey"
      security_groups             = [aws_security_group.tf_vpc_sg.id]
    }
    ```

2) Run the `terraform plan` command to check the infrastructure to be created. It will show the configurations of the EC2 instance to be created.
3) Run the `terraform apply` command to create the resources in AWS.
    ```
    PS C:\Users\sonus\Desktop\terraform_import> terraform apply
    aws_vpc.tf_vpc: Refreshing state... [id=vpc-0a01cb1e7b0e80142]
    aws_internet_gateway.tf_vpc_igw: Refreshing state... [id=igw-06fce2afc72eea089]
    aws_subnet.subnet2: Refreshing state... [id=subnet-0b17c269c8ef3de7c]
    aws_subnet.subnet1: Refreshing state... [id=subnet-00b66ce965ee0b22f]
    aws_security_group.tf_vpc_sg: Refreshing state... [id=sg-0a51a42b7ce1208c6]
    aws_instance.vm1: Refreshing state... [id=i-0f148090732ec2e4a]
    
    Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following
    symbols:
      + create
    
    Terraform will perform the following actions:
    
      # aws_instance.vm2 will be created
      + resource "aws_instance" "vm2" {
          + ami                                  = "ami-08bd8e5c51334492e"
          + arn                                  = (known after apply)
          + associate_public_ip_address          = true
          <Output removed for brevity>
        }
    
    Plan: 1 to add, 0 to change, 0 to destroy.
    
    Do you want to perform these actions?
      Terraform will perform the actions described above.
      Only 'yes' will be accepted to approve.
    
      Enter a value: yes
    
    aws_instance.vm2: Creating...
    aws_instance.vm2: Still creating... [10s elapsed]
    aws_instance.vm2: Still creating... [20s elapsed]
    aws_instance.vm2: Still creating... [30s elapsed]
    aws_instance.vm2: Creation complete after 31s [id=i-099da997974a73771]
    
    Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
    ```

## Import existing resources to modules
1) Create a root folder and a `main.tf` file inside it. Create a subfolder `assets` to the root folder. Add two subfolders inside the `assets` folder with the names `compute` and `networks`. Create `instances.tf` inside the `compute` folder and `network.tf` inside the `networks` folder.

2) Open the `main.tf` and add the following code to it. 
    ```
    terraform {
      required_providers {
        aws = {
          source  = "hashicorp/aws"
          version = "~> 3.0"
        }
      }
    }
    
    provider "aws" {
      region = "ap-south-1"
    }

    ```

3) Open the `networks.tf` file and define the VPC, Subnets, Secuirity Group and Internet Gateway resource configurations inside it. 
    ```
    resource "aws_vpc" "tf_vpc" {

    }
    
    resource "aws_subnet" "subnet1" {
    
    }
    
    resource "aws_subnet" "subnet2" {
    
    }
    
    resource "aws_internet_gateway" "tf_vpc_igw" {
    
    }
    
    resource "aws_security_group" "tf_vpc_sg" {
     
    }
    ```
4) Open the `instances.tf` file and define the EC2 resource configurations inside it. 
    ```
    variable "subnet_id" {
      type = string
      description = "Id of the subnet where EC2 need to be deployed"
    }
    resource "aws_instance" "vm1" {
    
    }

    ```
5) Now, add the module configurations in the `main.tf` file.
    ```
    module "network" {
      source = "./assets/networks"
    }
    
    module "compute" {
      source = "./assets/compute"
    }
    ```

6) Run the `terraform init` command to download the provider definitions and authenticate with AWS.
7) Import the networking resources configurations using the following commands.
    ```
    terraform import module.network.aws_vpc.tf_vpc <VPC ID>    
    ```
8) This will import the VPC configurations into the statefile. You can now update the VPC attributes in the `assets/networks/network.tf ` with the statefile values. You can use the `terraform show` command to get the values printed on the screen. 
9) Repeat the same for Subnets, internet gateways and Security group. 
    ```dotnetcli
    terraform import module.network.aws_subnet.subnet1 <Subnet1 ID> 
    terraform import module.network.aws_subnet.subnet2 <Subnet2 ID> 
    terraform import module.network.aws_internet_gateway.tf_vpc_igw <InternetGateway ID> 
    terraform import module.network.aws_security_group.tf_vpc_sg <Securitygroup ID> 
    ```
10) Declare some **output variables** in the `network` module which needs to be used in the `compute` module while defining the EC2 instance.
    ```
    output "vpc_id" {
      value = aws_vpc.tf_vpc.id
    }
    output "subnet1_id"{
        value = aws_subnet.subnet1.id
    }
    output "subnet2_id" {
      value = aws_subnet.subnet2.id
    }
    ```
11) Now, import the configurations for the compute resources. Run the following command to import the configuration of the EC2 instnace.
    ```
    terraform import module.compute.aws_instnace.vm1 <EC2 ID>    
    ```
12) This will import the configurations of the EC2 to statefile. Update the `assets/compute/instances.tf` file with the values of the `terraform show` command output.
    ```
    resource "aws_instance" "vm1" {
      ami                         = "ami-08bd8e5c51334492e"
      associate_public_ip_address = true
      availability_zone           = "ap-south-1a"
      instance_type               = "t2.micro"
      subnet_id                   = var.subnet_id
    }
    ```

13) Update the `main.tf` file to pass the subnet id as an input variable to the `compute` module.
    ```
    module "compute" {
      source = "./assets/compute"
      subnet_id = module.network.subnet1_id
    }
    ```
14) Run the `terraform plan` command to check the infrastructure and terraform configurations are matching or not.
    ```bash
    terraform plan
    ```

13) This will give the following output.
    ```
    PS C:\Users\sonus\Desktop\terraform_import\import-to-module> terraform plan
    module.network.aws_vpc.tf_vpc: Refreshing state... [id=vpc-0a01cb1e7b0e80142]
    module.network.aws_internet_gateway.tf_vpc_igw: Refreshing state... [id=igw-06fce2afc72eea089]
    module.network.aws_subnet.subnet1: Refreshing state... [id=subnet-00b66ce965ee0b22f]
    module.network.aws_subnet.subnet2: Refreshing state... [id=subnet-0b17c269c8ef3de7c]
    module.network.aws_security_group.tf_vpc_sg: Refreshing state... [id=sg-0a51a42b7ce1208c6]
    module.compute.aws_instance.vm1: Refreshing state... [id=i-0f148090732ec2e4a]
    
    No changes. Your infrastructure matches the configuration.
    
    Terraform has compared your real infrastructure against your configuration and found no differences, so no changes are needed.
    ```
14) You can now define additional resources in the terraform template file and run the `terraform apply` command to deploy them in the AWS cloud.
