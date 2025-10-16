package test

import (
	"testing"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestVPCCreation(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../terraform/vpc",
		Vars: map[string]interface{}{
			"vpc_cidr":           "10.0.0.0/16",
			"environment":        "test",
			"availability_zones": []string{"us-east-1a", "us-east-1b"},
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	vpcID := terraform.Output(t, terraformOptions, "vpc_id")
	assert.NotEmpty(t, vpcID)

	region := "us-east-1"
	ec2Client := createEC2Client(t, region)

	vpc := getVPC(t, ec2Client, vpcID)
	assert.Equal(t, "10.0.0.0/16", *vpc.CidrBlock)
	assert.Equal(t, "available", *vpc.State)

	publicSubnets := terraform.OutputList(t, terraformOptions, "public_subnet_ids")
	assert.GreaterOrEqual(t, len(publicSubnets), 2)

	privateSubnets := terraform.OutputList(t, terraformOptions, "private_subnet_ids")
	assert.GreaterOrEqual(t, len(privateSubnets), 2)

	igwID := terraform.Output(t, terraformOptions, "internet_gateway_id")
	assert.NotEmpty(t, igwID)

	natGatewayIDs := terraform.OutputList(t, terraformOptions, "nat_gateway_ids")
	assert.NotEmpty(t, natGatewayIDs)
}

func TestVPCWithCustomCIDR(t *testing.T) {
	t.Parallel()

	customCIDR := "172.16.0.0/16"
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../terraform/vpc",
		Vars: map[string]interface{}{
			"vpc_cidr":           customCIDR,
			"environment":        "test-custom",
			"availability_zones": []string{"us-west-2a", "us-west-2b"},
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	vpcID := terraform.Output(t, terraformOptions, "vpc_id")
	region := "us-west-2"
	ec2Client := createEC2Client(t, region)

	vpc := getVPC(t, ec2Client, vpcID)
	assert.Equal(t, customCIDR, *vpc.CidrBlock)
}

func TestVPCTags(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../terraform/vpc",
		Vars: map[string]interface{}{
			"vpc_cidr":           "10.1.0.0/16",
			"environment":        "test-tags",
			"availability_zones": []string{"us-east-1a", "us-east-1b"},
			"tags": map[string]string{
				"Project": "Infrastructure-Test",
				"Owner":   "DevOps-Team",
			},
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	vpcID := terraform.Output(t, terraformOptions, "vpc_id")
	region := "us-east-1"
	ec2Client := createEC2Client(t, region)

	vpc := getVPC(t, ec2Client, vpcID)
	tags := convertEC2TagsToMap(vpc.Tags)

	assert.Equal(t, "test-tags", tags["Environment"])
	assert.Equal(t, "Infrastructure-Test", tags["Project"])
	assert.Equal(t, "DevOps-Team", tags["Owner"])
}

func createEC2Client(t *testing.T, region string) *ec2.EC2 {
	sess := createAWSSession(t, region)
	return ec2.New(sess)
}

func getVPC(t *testing.T, client *ec2.EC2, vpcID string) *ec2.Vpc {
	input := &ec2.DescribeVpcsInput{
		VpcIds: []*string{aws.String(vpcID)},
	}

	result, err := client.DescribeVpcs(input)
	assert.NoError(t, err)
	assert.Len(t, result.Vpcs, 1)

	return result.Vpcs[0]
}

func convertEC2TagsToMap(tags []*ec2.Tag) map[string]string {
	tagMap := make(map[string]string)
	for _, tag := range tags {
		if tag.Key != nil && tag.Value != nil {
			tagMap[*tag.Key] = *tag.Value
		}
	}
	return tagMap
}
