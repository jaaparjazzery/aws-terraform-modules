package test

import (
	"fmt"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/rds"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestRDSInstanceCreation(t *testing.T) {
	t.Parallel()

	instanceID := fmt.Sprintf("test-db-%d", time.Now().Unix())

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../terraform/rds",
		Vars: map[string]interface{}{
			"db_instance_identifier": instanceID,
			"db_name":                "testdb",
			"db_username":            "admin",
			"db_password":            "TestPassword123!",
			"instance_class":         "db.t3.micro",
			"allocated_storage":      20,
			"engine":                 "postgres",
			"engine_version":         "14.7",
			"environment":            "test",
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	dbInstanceID := terraform.Output(t, terraformOptions, "db_instance_id")
	assert.Equal(t, instanceID, dbInstanceID)

	dbEndpoint := terraform.Output(t, terraformOptions, "db_endpoint")
	assert.NotEmpty(t, dbEndpoint)

	region := "us-east-1"
	rdsClient := createRDSClient(t, region)

	dbInstance := getRDSInstance(t, rdsClient, dbInstanceID)
	assert.Equal(t, "available", *dbInstance.DBInstanceStatus)
	assert.Equal(t, "postgres", *dbInstance.Engine)
	assert.Equal(t, "db.t3.micro", *dbInstance.DBInstanceClass)
	assert.Equal(t, int64(20), *dbInstance.AllocatedStorage)
}

func TestRDSWithMultiAZ(t *testing.T) {
	t.Parallel()

	instanceID := fmt.Sprintf("test-db-multiaz-%d", time.Now().Unix())

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../terraform/rds",
		Vars: map[string]interface{}{
			"db_instance_identifier": instanceID,
			"db_name":                "testdb",
			"db_username":            "admin",
			"db_password":            "TestPassword123!",
			"instance_class":         "db.t3.small",
			"allocated_storage":      20,
			"engine":                 "postgres",
			"engine_version":         "14.7",
			"multi_az":               true,
			"environment":            "test-multiaz",
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	dbInstanceID := terraform.Output(t, terraformOptions, "db_instance_id")
	region := "us-east-1"
	rdsClient := createRDSClient(t, region)

	dbInstance := getRDSInstance(t, rdsClient, dbInstanceID)
	assert.True(t, *dbInstance.MultiAZ)
}

func TestRDSWithBackupRetention(t *testing.T) {
	t.Parallel()

	instanceID := fmt.Sprintf("test-db-backup-%d", time.Now().Unix())

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../terraform/rds",
		Vars: map[string]interface{}{
			"db_instance_identifier":  instanceID,
			"db_name":                 "testdb",
			"db_username":             "admin",
			"db_password":             "TestPassword123!",
			"instance_class":          "db.t3.micro",
			"allocated_storage":       20,
			"engine":                  "mysql",
			"engine_version":          "8.0.35",
			"backup_retention_period": 7,
			"backup_window":           "03:00-04:00",
			"environment":             "test-backup",
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	dbInstanceID := terraform.Output(t, terraformOptions, "db_instance_id")
	region := "us-east-1"
	rdsClient := createRDSClient(t, region)

	dbInstance := getRDSInstance(t, rdsClient, dbInstanceID)
	assert.Equal(t, int64(7), *dbInstance.BackupRetentionPeriod)
	assert.NotEmpty(t, *dbInstance.PreferredBackupWindow)
}

func TestRDSEncryption(t *testing.T) {
	t.Parallel()

	instanceID := fmt.Sprintf("test-db-encrypted-%d", time.Now().Unix())

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../terraform/rds",
		Vars: map[string]interface{}{
			"db_instance_identifier": instanceID,
			"db_name":                "testdb",
			"db_username":            "admin",
			"db_password":            "TestPassword123!",
			"instance_class":         "db.t3.micro",
			"allocated_storage":      20,
			"engine":                 "postgres",
			"engine_version":         "14.7",
			"storage_encrypted":      true,
			"environment":            "test-encrypted",
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	dbInstanceID := terraform.Output(t, terraformOptions, "db_instance_id")
	region := "us-east-1"
	rdsClient := createRDSClient(t, region)

	dbInstance := getRDSInstance(t, rdsClient, dbInstanceID)
	assert.True(t, *dbInstance.StorageEncrypted)
}

func createRDSClient(t *testing.T, region string) *rds.RDS {
	sess := createAWSSession(t, region)
	return rds.New(sess)
}

func getRDSInstance(t *testing.T, client *rds.RDS, instanceID string) *rds.DBInstance {
	input := &rds.DescribeDBInstancesInput{
		DBInstanceIdentifier: aws.String(instanceID),
	}

	result, err := client.DescribeDBInstances(input)
	assert.NoError(t, err)
	assert.Len(t, result.DBInstances, 1)

	return result.DBInstances[0]
}
