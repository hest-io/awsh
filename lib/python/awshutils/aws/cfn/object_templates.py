"""This is a simple import module that provides templated strings that
represent AWS Cloudformation objects"""

SNIPPET_VPC = """{
    'VPC': {
        'Type': 'AWS::EC2::VPC',
        'Properties': {
            'CidrBlock': '$cidr',
            'Tags': $tags,
            'EnableDnsSupport' : 'true',
            'EnableDnsHostnames' : 'true',
        }
    }
}"""

SNIPPET_AZ = """{
    '$az_name_alias': {
        'AllowedPattern': '[-a-zA-Z0-9]*',
        'ConstraintDescription': 'Alphanumeric characters and dashes only',
        'Description': 'Availability Zone name',
        'MaxLength': '15',
        'MinLength': '10',
        'Default': '$default_az_name',
        'Type': 'String'
    }
}"""

SNIPPET_VPC_DHCP_OPTIONS = """{
    'DhcpOptions': {
        'Type' : 'AWS::EC2::DHCPOptions',
        'Properties' : {
            'DomainName' : '$domain',
            'DomainNameServers' : [ 'AmazonProvidedDNS' ],
            'Tags' : $tags
       }
    }
}"""

SNIPPET_VPC_DHCP_OPTIONS_ASSOCIATION = """{
    'DhcpOptionsAssociation': {
        'Type' : 'AWS::EC2::VPCDHCPOptionsAssociation',
        'Properties' : {
            'DhcpOptionsId' : { 'Ref': 'DhcpOptions' },
            'VpcId': { 'Ref': 'VPC' },
        }
   }
}"""

SNIPPET_VPC_IGW = """{
    'InternetGateway': {
        'Type': 'AWS::EC2::InternetGateway',
        'Properties': {
            'Tags': $tags
        }
    }
}"""

SNIPPET_VPC_IGW_ATTACHMENT = """{
    'VPCGatewayAttachment': {
        'DependsOn': 'InternetGateway',
        'Type': 'AWS::EC2::VPCGatewayAttachment',
        'Properties': {
            'VpcId': {
                'Ref': 'VPC'
            },
            'InternetGatewayId': {
                'Ref': 'InternetGateway'
            },
        }
    }
}"""

SNIPPET_VPC_VPNGW = """{
    'VPNGateway' : {
        'Type' : 'AWS::EC2::VPNGateway',
        'Properties' : {
            'Type' : 'ipsec.1',
            'Tags': $tags
        }
    }
}"""

SNIPPET_VPC_VPNGW_ATTACHMENT = """{
    'VPNGatewayAttachment': {
        'DependsOn': 'VPNGateway',
        'Type': 'AWS::EC2::VPCGatewayAttachment',
        'Properties': {
            'VpcId': {
                'Ref': 'VPC'
            },
            'VpnGatewayId': {
                'Ref': 'VPNGateway'
            },
        }
    }
}"""

SNIPPET_VPC_ROUTE_TABLE = """{
    '$route_table_name': {
        'Type': 'AWS::EC2::RouteTable',
        'Properties': {
            'VpcId': {
                'Ref': 'VPC'
            },
            'Tags': $tags
        }
    }
}"""

SNIPPET_VPC_ROUTE_PUBLIC = """{
    '$route_name': {
        'DependsOn': 'InternetGateway',
        'Type': 'AWS::EC2::Route',
        'Properties': {
            'RouteTableId': {
                'Ref': '$route_table_name'
            },
            'DestinationCidrBlock': '0.0.0.0/0',
            'GatewayId': {
                'Ref': 'InternetGateway'
            }
        }
    }
}"""

SNIPPET_VPC_ROUTE_AMBER = """{
    '$route_name': {
        'Type': 'AWS::EC2::Route',
        'Properties': {
            'RouteTableId': {
                'Ref': '$route_table_name'
            },
            'DestinationCidrBlock' : '0.0.0.0/0',
            'InstanceId': {
                'Ref': '$instance_name'
            }
        }
    }
}"""

SNIPPET_VPC_ROUTE_PRIVATE = """{
    '$route_name': {
        'Type': 'AWS::EC2::Route',
        'Properties': {
            'RouteTableId': {
                'Ref': '$route_table_name'
            },
            'DestinationCidrBlock' : '0.0.0.0/0',
            'InstanceId': {
                'Ref': '$instance_name'
            }
        }
    }
}"""

SNIPPET_VPC_SUBNET = """{
    '$subnet_name': {
        'Type': 'AWS::EC2::Subnet',
        'Properties': {
            'AvailabilityZone': '$az_name',
            'VpcId': {
                'Ref': 'VPC'
            },
            'CidrBlock': '$cidr',
            'Tags': $tags
        }
    }
}"""

SNIPPET_VPC_ROUTE_TABLE_ASSOCIATION = """{
    '$association_name': {
        'Type': 'AWS::EC2::SubnetRouteTableAssociation',
        'Properties': {
            'SubnetId': {
                'Ref': '$subnet_name'
            },
            'RouteTableId' : {
                'Ref': '$route_table_name'
            }
        }
    }
}"""

SNIPPET_SG_RULE_SG_SOURCE = """{
    'IpProtocol': '$protocol',
    'FromPort': '$port_from',
    'ToPort': '$port_to',
    'SourceSecurityGroupId': {
        'Ref': '$sg_name'
    }
}"""

SNIPPET_SG_RULE_CIDR_SOURCE = """{
    'IpProtocol': '$protocol',
    'FromPort': '$port_from',
    'ToPort': '$port_to',
    'CidrIp': '$cidr'
}"""

SNIPPET_SG = """{
    '$sg_name': {
        'Type': 'AWS::EC2::SecurityGroup',
        'Properties': {
            'GroupDescription': '$sg_description',
            'VpcId': {
                'Ref': 'VPC'
            },
            'SecurityGroupIngress': [
                '$src_sg_ingress', {
                    'IpProtocol': 'tcp', 'FromPort': '80', 'ToPort': '80', 'CidrIp': vpc_cidrblock
                }, {
                    'IpProtocol': 'tcp', 'FromPort': '443', 'ToPort': '443', 'CidrIp': vpc_cidrblock
                }
            ],
            'SecurityGroupEgress': [
                {
                    'IpProtocol': 'tcp', 'FromPort': '80', 'ToPort': '80', 'CidrIp': '0.0.0.0/0'
                }, {
                    'IpProtocol': 'tcp', 'FromPort': '443', 'ToPort': '443', 'CidrIp': '0.0.0.0/0'
                }
            ],
            'Tags': $tags
        }
    }
}"""

SNIPPET_INSTANCE_EIP = """{
    '$eip_name': {
        'DependsOn': 'VPCGatewayAttachment',
        'Type': 'AWS::EC2::EIP',
        'Properties': {
            'Domain': 'vpc',
            'InstanceId': {
                'Ref': '$instance_name'
            }
        }
    }
}"""

SNIPPET_NAT_SG = """{
    'NatSecurityGroup': {
        'Type': 'AWS::EC2::SecurityGroup',
        'Properties': {
            'GroupDescription': 'Allow NAT access from the VPC',
            'VpcId': {
                'Ref': 'VPC'
            },
            'SecurityGroupEgress': [
                { 'IpProtocol': '-1', 'FromPort': '-1', 'ToPort': '-1', 'CidrIp': '0.0.0.0/0' }
            ],
            'SecurityGroupIngress': [
                { 'IpProtocol': '-1', 'FromPort': '-1', 'ToPort': '-1', 'CidrIp': '$cidr' }
            ],
            'Tags': $tags
        }
    }
}"""

SNIPPET_UTM_ACCESS_SG = """{
    'UTMAccessSecurityGroup': {
        'Type': 'AWS::EC2::SecurityGroup',
        'Properties': {
            'GroupDescription': 'Allow management access to the UTM instance',
            'VpcId': {
                'Ref': 'VPC'
            },
            'SecurityGroupEgress': [
                { 'IpProtocol': '-1', 'FromPort': '-1', 'ToPort': '-1', 'CidrIp': '0.0.0.0/0' }
            ],
            'SecurityGroupIngress': [
                { 'IpProtocol': '-1', 'FromPort': '-1', 'ToPort': '-1', 'CidrIp': { "Ref": "UTMAccessFromCidr" } }
            ],
            'Tags': $tags
        }
    }
}"""

SNIPPET_SG_ALLOW_ALL_ICMP = """{
    'ICMPSecurityGroup': {
        'Type': 'AWS::EC2::SecurityGroup',
        'Properties': {
            'GroupDescription': 'Allow ICMP within the VPC from anywhere',
            'VpcId': {
                'Ref': 'VPC'
            },
            'SecurityGroupIngress': [
                { 'IpProtocol': 'icmp', 'FromPort': '-1', 'ToPort': '-1', 'CidrIp': '0.0.0.0/0' },
            ],
            'SecurityGroupEgress': [
                { 'IpProtocol': 'icmp', 'FromPort': '-1', 'ToPort': '-1', 'CidrIp': '0.0.0.0/0' },
            ],
            'Tags': $tags
        }
    }
}"""

SNIPPET_SG_ALLOW_VPC_ICMP = """{
    'VPCICMPSecurityGroup': {
        'Type': 'AWS::EC2::SecurityGroup',
        'Properties': {
            'GroupDescription': 'Allow ICMP within the VPC from anywhere',
            'VpcId': {
                'Ref': 'VPC'
            },
            'SecurityGroupIngress': [
                { 'IpProtocol': 'icmp', 'FromPort': '-1', 'ToPort': '-1', 'CidrIp': '$cidr' },
            ],
            'SecurityGroupEgress': [
                { 'IpProtocol': 'icmp', 'FromPort': '-1', 'ToPort': '-1', 'CidrIp': '$cidr' },
            ],
            'Tags': $tags
        }
    }
}"""

SNIPPET_NAT_INSTANCE = """{
    '$instance_name': {
        'DependsOn': 'InternetGateway',
        'Type': 'AWS::EC2::Instance',
        'Properties': {
            'Tags': $tags,
            'ImageId': '$image_id',
            'InstanceType': {
                'Ref': 'UTMInstanceType'
            },
            'KeyName': {
                'Ref': 'KeyName'
            },
            'SubnetId': {
                'Ref': '$subnet_name'
            },
            'SourceDestCheck': 'false',
            'SecurityGroupIds': [
                {'Ref': 'NatSecurityGroup'},
                {'Ref': 'VPCICMPSecurityGroup'},
                {'Ref': 'UTMAccessSecurityGroup'},
            ],
        }
    }
}"""


SNIPPET_SSH_KEY = """{
    'KeyName': {
        'Description': 'Name of an existing EC2 KeyPair to enable SSH access to the instance',
        'Type': 'AWS::EC2::KeyPair::KeyName',
        'ConstraintDescription': 'must be the name of an existing EC2 KeyPair.'
    }
}"""

SNIPPET_UTM_ACCESS_CIDR = """{
    'UTMAccessFromCidr': {\
        'AllowedPattern': '(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})/(\\d{1,2})',
        'ConstraintDescription': 'Please specify the CIDR block as n.n.n.n/n',
        'Default': '0.0.0.0/0',
        'Description': 'CIDR block allowed to connect to the UTM Hosts',
        'MaxLength': '18',
        'MinLength': '9',
        'Type': 'String'
    }
}"""

SNIPPET_UTM_SG = """{
    'UTMSecurityGroup': {
        'Type': 'AWS::EC2::SecurityGroup',
        'Properties': {
            'GroupDescription': 'Allow remote access from a CIDR range',
            'VpcId': {
                'Ref': 'VPC'
            },
            'SecurityGroupIngress': [
                {'IpProtocol': 'tcp', 'FromPort': {'Ref': 'UTMTcpPort'},
                'ToPort': {'Ref': 'UTMTcpPort'},
                'CidrIp': {'Ref': 'UTMAccessFromCidr'}}],
            'SecurityGroupEgress': [
                {'IpProtocol': 'tcp', 'FromPort': '0', 'ToPort': '65535', 'CidrIp': '$cidr'},
                {'IpProtocol': 'udp', 'FromPort': '0', 'ToPort': '65535', 'CidrIp': '$cidr'},
            ],
            'Tags': $tags
        }
    }
}"""

SNIPPET_UTM_TCP_PORT = """{
    'UTMTcpPort': {
        'AllowedPattern': '[0-9]*',
        'ConstraintDescription': 'Numbers only',
        'Default': '$port',
        'Description': 'TCP port the UTM Host listens to',
        'Type': 'String'
    }
}"""

SNIPPET_UTM_AMI = """{
    'UTMAmi': {
        'Description': 'AMI to use for the UTM instance',
        'Type': 'String',
        'Default': 'ami-75342c01'
    }
}"""

SNIPPET_UTM_INSTANCE = """{
    '$instance_name': {
        'DependsOn': 'InternetGateway',
        'Type': 'AWS::EC2::Instance',
        'Properties': {
            'Tags': $tags,
            'ImageId': '$image_id',
            'InstanceType': {
                'Ref': 'UTMInstanceType'
            },
            'KeyName': {
                'Ref': 'KeyName'
            },
            'SubnetId': {
                'Ref': '$subnet_name'
            },
            'SecurityGroupIds': [{'Ref': 'UTMSecurityGroup'}, {'Ref': 'VPCICMPSecurityGroup'}],
            "UserData"       : {
                "Fn::Base64" : {
                    "Fn::Join" : ["", [
                        "#!/bin/bash -ex", "\n",
                        "wget --output-document=/tmp/bootstrap.sh --timeout=10 --no-check-certificate --tries=3 https://s3-eu-west-1.amazonaws.com/boss-public/bootstrap/bootstrap.sh\n",
                        "chmod +x /tmp/bootstrap.sh\n",
                        "/tmp/bootstrap.sh\n"
                    ] ]
                }
            }
        }
    }
}"""

SNIPPET_INSTANCE_TYPES = """{
    'UTMInstanceType': {
        'AllowedValues': [
            't1.micro',
            't2.micro',
            't2.small',
            't2.medium',
            't2.large',
            'm1.small'
            'm3.medium',
            'm3.large',
            'm3.xlarge',
            'm3.2xlarge',
            'm4.large',
            'm4.xlarge',
            'm4.2xlarge',
            'm4.4xlarge',
            'm4.10xlarge',
            'c4.large',
            'c4.xlarge',
            'c4.2xlarge',
            'c4.4xlarge',
            'c4.8xlarge'
        ],
        'ConstraintDescription': 'Instance type must be of a valid EC2 type',
        'Default': 't1.micro',
        'Description': 'EC2 instance type for the UTM instance',
        'Type': 'String'
    }
}"""

SNIPPET_OUTPUT = """{
    '$name': {
        'Description': '$description',
        'Value': {
            'Ref': '$ref'
        }
    }
}"""

SNIPPET_EBS_VOLUME = """{
   'Type': 'AWS::EC2::Volume',
   'Properties': {
      'AvailabilityZone': '$az_name',
      'Size': '$vol_size_gb',
      'Tags': $tags,
      'VolumeType': 'standard'
   }
}"""

SNIPPET_S3_BUCKET = """{
   'Type': 'AWS::S3::Bucket',
   'Properties': {
      'AccessControl': 'Private',
      'BucketName': '$bucket_name',
      'Tags': $tags,
   }
}"""

