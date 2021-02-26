#----root/main.tf-----

provider "aws" {
  region = "${var.aws_region}"
}

# Deploy s3 hosting bucket
module "S3CDNhosting" {
  source              = "./modules/S3CDNhosting"
  website_bucket_name = "${var.website_bucket_name}"
}

# Deploy cloudformation distribution
module "CDN" {
  source                     = "./modules/CDN"
  domain_name                = "${var.domain_name}"
  hosted_website_bucket_name = "${module.S3hosting.tf_s3_hosted_bucket}"
}

# Deploy API gateway
module "Apigateway" {
  source                  = "./modules/ApiGateway"
  api_rest_container_name = "${var.website_bucket_name}-rest-api"
}

# Deploy VPC and attach IGW
module "vpc_igw" {
  source   = "./modules/VPC_igw"
  vpc_cidr = "${var.vpc_cidr}"
}

# Deploy Public Subnet and Route tables
module "PublicSubnet" {
  source     = "./modules/PublicSubnet"
  vpc_id     = "${module.vpc_igw.vpc_id}"
  vpc_igw_id = "${module.vpc_igw.igw_id}"
  #  vpc_route_table_id      = "${module.vpc_igw.default_route_table_id}"
  vpc_public_subnet_count = "${var.vpc_public_subnet_count}"
  vpc_public_cidrs        = "${var.vpc_public_cidrs}"
}

# Deploy Private Subnet and Route tables
module "PrivateSubnet" {
  source = "./modules/PrivateSubnet"
  vpc_id = "${module.vpc_igw.vpc_id}"
  #  vpc_igw_id   = "${module.vpc_igw.igw_id}"
  vpc_route_table_id       = "${module.vpc_igw.default_route_table_id}"
  vpc_private_subnet_count = "${var.vpc_private_subnet_count}"
  vpc_private_cidrs        = "${var.vpc_private_cidrs}"
}

# Deploy RDS Subnet and Route tables
module "RDSSubnet" {
  source               = "./modules/RDSSubnet"
  vpc_id               = "${module.vpc_igw.vpc_id}"
  vpc_rds_subnet_count = "${var.vpc_rds_subnet_count}"
  vpc_rds_cidrs        = "${var.vpc_rds_cidrs}"
}

# Deploy VPC flowlogs
module "VPCFlowlogs" {
  source = "./modules/Flowlogs"
  vpc_id = "${module.vpc_igw.vpc_id}"
}

# Deploy Security group
module "SecurityGroup" {
  source = "./modules/SecurityGroup"
  vpc_id = "${module.vpc_igw.vpc_id}"
}

# Deploy a ECS Cluster
module "ECSCluster" {
  source              = "./modules/ECSCluster"
  tf_ecs_cluster_name = "${var.vpc_id}-cluster"
}

# ECS Service role
module "ECSServiceRole" {
  source = "./modules/ECSServiceRole"
}

# ECS Instance role
module "ECSInstanceRole" {
  source = "./modules/ECSInstanceRole"
}

# ECS Service role
module "APPlloadbalancer" {
  source              = "./modules/ECSALB"
  vpc_id              = "${module.vpc_igw.vpc_id}"
  private_subnets_alb = "${module.PrivateSubnet.vpc_private_subnets}"
}
