resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = var.vpc_name
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_flow_log" "this" {
  iam_role_arn         = var.vpc_flow_log_iam_role_arn
  vpc_id               = aws_vpc.this.id
  traffic_type         = "ALL"
  log_destination_type = "cloud-watch-logs"
  log_destination      = var.aws_cloudwatch_vpc_flow_log_group_arn
  tags = {
    Name = "${var.vpc_name}-flow-logs"
  }
}

resource "aws_subnet" "public_subnet" {
  count             = length(var.public_subnet_cidr)                                                       # Derived from the number of supplied CIDR blocks
  cidr_block        = var.public_subnet_cidr[count.index]                                                  # CIDR block for each public subnet from `public_subnet_cidr`
  vpc_id            = aws_vpc.this.id                                                                      # The VPC to associate the subnet with
  availability_zone = element(coalesce(var.azs, data.aws_availability_zones.available.names), count.index) # Choose an AZ from the list or fallback to available AZs
  tags = merge(
    { Name = "${var.vpc_name}-public_subnet-${count.index + 1}" },
    var.enable_eks_tags ? { "kubernetes.io/role/elb" = "1" } : {},
  )
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_subnet" "private_subnet" {
  count             = length(var.private_subnet_cidr)                                                      # Derived from the number of supplied CIDR blocks
  cidr_block        = var.private_subnet_cidr[count.index]                                                 # CIDR block for each private subnet from `private_subnet_cidr`
  vpc_id            = aws_vpc.this.id                                                                      # The VPC to associate the subnet with
  availability_zone = element(coalesce(var.azs, data.aws_availability_zones.available.names), count.index) # Choose an AZ from the list or fallback to available AZs
  tags = merge(
    { Name = "${var.vpc_name}-private_subnet-${count.index + 1}" },
    var.enable_eks_tags ? {
      "kubernetes.io/role/internal-elb" = "1"
      "karpenter.sh/discovery"          = "${var.environment}-${var.cluster_name}"
    } : {},
  )
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_subnet" "isolated_subnet" {
  count             = length(var.isolated_subnet_cidr)
  cidr_block        = var.isolated_subnet_cidr[count.index]
  vpc_id            = aws_vpc.this.id
  availability_zone = element(coalesce(var.azs, data.aws_availability_zones.available.names), count.index)
  tags = {
    Name = "${var.vpc_name}-isolated-subnet-${count.index + 1}"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id # Attach the gateway to the VPC
  tags = {
    Name = "${var.vpc_name}-igw"
  }
  lifecycle {
    create_before_destroy = true
  }
  depends_on = [
    aws_vpc.this # Ensure the VPC is created/modified before creating IGW
  ]
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.this.id # Associate the route table with the VPC
  route {
    cidr_block = "0.0.0.0/0"                  # Route all traffic to the internet
    gateway_id = aws_internet_gateway.this.id # Use the internet gateway as the route
  }
  tags = {
    Name = "${var.vpc_name}-public-rt"
  }
}

resource "aws_route_table_association" "public_rt_association" {
  count          = length(var.public_subnet_cidr)           # Create an association for each public subnet
  subnet_id      = aws_subnet.public_subnet[count.index].id # Associate the route table with each public subnet
  route_table_id = aws_route_table.public_rt.id             # Associate the public route table
}



resource "aws_eip" "this" {
  count = var.create_nat ? 1 : 0
  tags = {
    Name = "${var.vpc_name}-nat-eip"
  }
}

resource "aws_nat_gateway" "this" {
  count         = var.create_nat ? 1 : 0         # Create NAT gateways or Not
  subnet_id     = aws_subnet.public_subnet[0].id # Attach each NAT gateway to a public subnet
  allocation_id = aws_eip.this[0].id             # Associate each NAT gateway with an Elastic IP
  depends_on    = [aws_eip.this]                 # Ensure the Elastic IPs are created before the NAT gateways
  tags = {
    Name = "${var.vpc_name}-nat-gw" # Name the NAT gateways with the VPC name and suffix
  }
}

resource "aws_route_table" "private_rt" {
  count  = var.create_nat ? 1 : 0 # Create only when NAT gateway is enabled
  vpc_id = aws_vpc.this.id        # Associate the route table with the VPC
  route {
    cidr_block     = "0.0.0.0/0"                # Route all outbound traffic to the NAT gateway
    nat_gateway_id = aws_nat_gateway.this[0].id # Use the corresponding NAT gateway
  }
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Name = "${var.vpc_name}-private-rt" # Name the route tables
  }
}

resource "aws_route_table_association" "private_rt_association" {
  count          = var.create_nat ? length(var.private_subnet_cidr) : 0 # Create an association for each private subnet only when NAT is enabled
  subnet_id      = aws_subnet.private_subnet[count.index].id            # Associate the route table with each private subnet
  route_table_id = aws_route_table.private_rt[0].id                     # Use the shared private route table
}

