resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    name = "main"
  }
}

resource "aws_subnet" "public" {

  count = length(var.public_subnet_cidr)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidr[count.index]
  availability_zone = var.availability_zone[count.index]

  tags = {
    name = "public${count.index}"
  }
}

resource "aws_subnet" "private" {

  count = length(var.public_subnet_cidr)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr[count.index]
  availability_zone = var.availability_zone[count.index]

  tags = {
    name = "private0"
  }
}

resource "aws_internet_gateway" "ig0" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "internet gateway0"
  }
}

resource "aws_eip" "nat" {

  count = length(var.public_subnet_cidr)

  vpc = true

  tags = {
    Name = "nat${count.index}"
  }
}


resource "aws_nat_gateway" "main" {

  count         = length(var.public_subnet_cidr)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "main${count.index}"
  }
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig0.id
  }

  tags = {
    Name = "public"
  }
}


resource "aws_route_table" "private" {
  count = length(var.public_subnet_cidr)

  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name = "private${count.index}"
  }
}


resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidr)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}


resource "aws_route_table_association" "private" {
  count = length(var.public_subnet_cidr)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
