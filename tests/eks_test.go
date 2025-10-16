package test

import (
	"fmt"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/eks"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestEKSClusterCreation(t *testing.T) {
	t.Parallel()

	clusterName := fmt.Sprintf("test-eks-%d", time.Now().Unix())

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../terraform/eks",
		Vars: map[string]interface{}{
			"cluster_name":       clusterName,
			"cluster_version":    "1.28",
			"environment":        "test",
			"availability_zones": []string{"us-east-1a", "us-east-1b"},
			"tags": map[string]string{
				"Project": "Infrastructure-Test",
				"Owner":   "DevOps-Team",
			},
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	clusterID := terraform.Output(t, terraformOptions, "cluster_id")
	region := "us-east-1"
	eksClient := createEKSClient(t, region)

	cluster := getEKSCluster(t, eksClient, clusterID)
	assert.Equal(t, "test", cluster.Tags["Environment"])
	assert.Equal(t, "Infrastructure-Test", cluster.Tags["Project"])
	assert.Equal(t, "DevOps-Team", cluster.Tags["Owner"])
}

func TestEKSPublicAndPrivateAccess(t *testing.T) {
	t.Parallel()

	clusterName := fmt.Sprintf("test-eks-access-%d", time.Now().Unix())

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../terraform/eks",
		Vars: map[string]interface{}{
			"cluster_name":                  clusterName,
			"cluster_version":               "1.28",
			"endpoint_public_access":        true,
			"endpoint_private_access":       true,
			"public_access_cidrs":           []string{"10.0.0.0/8"},
			"environment":                   "test",
			"availability_zones":            []string{"us-east-1a", "us-east-1b"},
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	clusterID := terraform.Output(t, terraformOptions, "cluster_id")
	region := "us-east-1"
	eksClient := createEKSClient(t, region)

	cluster := getEKSCluster(t, eksClient, clusterID)
	assert.True(t, *cluster.ResourcesVpcConfig.EndpointPublicAccess)
	assert.True(t, *cluster.ResourcesVpcConfig.EndpointPrivateAccess)
}

func createEKSClient(t *testing.T, region string) *eks.EKS {
	sess := createAWSSession(t, region)
	return eks.New(sess)
}

func getEKSCluster(t *testing.T, client *eks.EKS, clusterName string) *eks.Cluster {
	input := &eks.DescribeClusterInput{
		Name: aws.String(clusterName),
	}

	result, err := client.DescribeCluster(input)
	assert.NoError(t, err)
	assert.NotNil(t, result.Cluster)

	return result.Cluster
}

func getEKSNodeGroup(t *testing.T, client *eks.EKS, clusterName, nodeGroupName string) *eks.Nodegroup {
	input := &eks.DescribeNodegroupInput{
		ClusterName:   aws.String(clusterName),
		NodegroupName: aws.String(nodeGroupName),
	}

	result, err := client.DescribeNodegroup(input)
	assert.NoError(t, err)
	assert.NotNil(t, result.Nodegroup)

	return result.Nodegroup
}
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	clusterID := terraform.Output(t, terraformOptions, "cluster_id")
	assert.Equal(t, clusterName, clusterID)

	clusterEndpoint := terraform.Output(t, terraformOptions, "cluster_endpoint")
	assert.NotEmpty(t, clusterEndpoint)

	region := "us-east-1"
	eksClient := createEKSClient(t, region)

	cluster := getEKSCluster(t, eksClient, clusterName)
	assert.Equal(t, "ACTIVE", *cluster.Status)
	assert.Equal(t, "1.28", *cluster.Version)
}

func TestEKSNodeGroup(t *testing.T) {
	t.Parallel()

	clusterName := fmt.Sprintf("test-eks-ng-%d", time.Now().Unix())
	nodeGroupName := fmt.Sprintf("%s-ng", clusterName)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../terraform/eks",
		Vars: map[string]interface{}{
			"cluster_name":       clusterName,
			"cluster_version":    "1.28",
			"node_group_name":    nodeGroupName,
			"node_instance_types": []string{"t3.medium"},
			"desired_size":       2,
			"min_size":           1,
			"max_size":           3,
			"environment":        "test",
			"availability_zones": []string{"us-east-1a", "us-east-1b"},
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	clusterID := terraform.Output(t, terraformOptions, "cluster_id")
	region := "us-east-1"
	eksClient := createEKSClient(t, region)

	nodeGroup := getEKSNodeGroup(t, eksClient, clusterID, nodeGroupName)
	assert.Equal(t, "ACTIVE", *nodeGroup.Status)
	assert.Equal(t, int64(2), *nodeGroup.ScalingConfig.DesiredSize)
	assert.Equal(t, int64(1), *nodeGroup.ScalingConfig.MinSize)
	assert.Equal(t, int64(3), *nodeGroup.ScalingConfig.MaxSize)
}

func TestEKSClusterLogging(t *testing.T) {
	t.Parallel()

	clusterName := fmt.Sprintf("test-eks-logging-%d", time.Now().Unix())

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../terraform/eks",
		Vars: map[string]interface{}{
			"cluster_name":       clusterName,
			"cluster_version":    "1.28",
			"enabled_log_types":  []string{"api", "audit", "authenticator", "controllerManager", "scheduler"},
			"environment":        "test",
			"availability_zones": []string{"us-east-1a", "us-east-1b"},
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	clusterID := terraform.Output(t, terraformOptions, "cluster_id")
	region := "us-east-1"
	eksClient := createEKSClient(t, region)

	cluster := getEKSCluster(t, eksClient, clusterID)
	
	enabledTypes := make([]string, 0)
	if cluster.Logging != nil && len(cluster.Logging.ClusterLogging) > 0 {
		for _, logSetup := range cluster.Logging.ClusterLogging {
			if logSetup.Enabled != nil && *logSetup.Enabled {
				for _, logType := range logSetup.Types {
					enabledTypes = append(enabledTypes, *logType)
				}
			}
		}
	}

	assert.NotEmpty(t, enabledTypes)
	assert.Contains(t, enabledTypes, "api")
	assert.Contains(t, enabledTypes, "audit")
}

func TestEKSClusterEncryption(t *testing.T) {
	t.Parallel()

	clusterName := fmt.Sprintf("test-eks-encryption-%d", time.Now().Unix())

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../terraform/eks",
		Vars: map[string]interface{}{
			"cluster_name":       clusterName,
			"cluster_version":    "1.28",
			"enable_encryption":  true,
			"environment":        "test",
			"availability_zones": []string{"us-east-1a", "us-east-1b"},
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	clusterID := terraform.Output(t, terraformOptions, "cluster_id")
	region := "us-east-1"
	eksClient := createEKSClient(t, region)

	cluster := getEKSCluster(t, eksClient, clusterID)
	assert.NotNil(t, cluster.EncryptionConfig)
	assert.NotEmpty(t, cluster.EncryptionConfig)
}

func TestEKSClusterTags(t *testing.T) {
	t.Parallel()

	clusterName := fmt.Sprintf("test-eks-tags-%d", time.Now().Unix())

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../terraform/eks",
		Vars: map[string]interface{}{
			"cluster_name":       clusterName,
			"cluster_version":    "1.28",
			"environment":        "test",
			"availability_zones": []string{"us-east-1a", "us-east-1b"},
